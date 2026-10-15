import { describe, it, expect, afterEach, beforeEach } from '@jest/globals';
import { render, waitFor, act } from '@testing-library/react-native';

import { mockFetch } from '../../__fixtures__/mockFetch';

/* The Hyperswitch vault itself, not a mock: this is the entry the hosted
   adapter stands on, so what it promises is pinned here. A vault release that
   predates its ./detached entry skips these; it cannot pass or fail them. */
type DetachedEntry = {
  createDetachedCardForm: (config?: Record<string, unknown>) => any;
  CardNumberField: any;
  CardExpiryField: any;
  CardCVCField: any;
};

let vault: DetachedEntry | null = null;
try {
  vault = require('@juspay-tech/react-native-hyperswitch-vault/detached');
} catch {
  vault = null;
}
const root = require('@juspay-tech/react-native-hyperswitch-vault') as Record<
  string,
  unknown
>;

const { createDetachedCardForm, CardNumberField, CardExpiryField, CardCVCField } =
  vault ?? ({} as DetachedEntry);

const describeIfAvailable = vault ? describe : describe.skip;

const AUTH = Buffer.from(
  'payment_method_session_id=0a_pms_0192,profile_id=pro_456',
  'utf8'
).toString('base64');

const PAN = '4242424242424242';

let network: ReturnType<typeof mockFetch>;
beforeEach(() => {
  network = mockFetch();
});
afterEach(() => {
  network.restore();
});

function mountForm(config: Record<string, unknown> = {}) {
  const changes: any[] = [];
  const form = createDetachedCardForm({
    sdkAuthorization: AUTH,
    environment: 'sandbox',
    onChange: (event: unknown) => changes.push(event),
    ...config,
  });

  /* Four separate React roots: the host, and one per field. */
  const host = render(<form.Host />);
  const number = render(
    <form.Field>
      <CardNumberField />
    </form.Field>
  );
  const expiry = render(
    <form.Field>
      <CardExpiryField />
    </form.Field>
  );
  const cvc = render(
    <form.Field>
      <CardCVCField />
    </form.Field>
  );

  /* Not fireEvent: the testing library only treats the most recent render() as
     mounted and silently ignores events for any earlier root. Separate roots
     are the whole point here, so the input's own handler is called instead. */
  const enter = (view: ReturnType<typeof render>, testID: string, text: string) =>
    act(async () => {
      view.getByTestId(testID).props.onChangeText(text);
    });

  const type = async () => {
    await enter(number, 'CardNumberInputTestId', PAN);
    await enter(expiry, 'ExpiryInputTestId', '12/30');
    await enter(cvc, 'CVCInputTestId', '123');
  };

  return { form, host, number, expiry, cvc, changes, type };
}

describeIfAvailable('vault ./detached', () => {
  it('shares its fields with the package root, so there is one context', () => {
    expect(CardNumberField).toBe(root.CardNumberField);
    expect(CardCVCField).toBe(root.CardCVCField);
    expect(createDetachedCardForm).toBe(root.createDetachedCardForm);
  });

  it('makes fields in separate roots one form', async () => {
    const { changes, type } = mountForm();
    await type();

    await waitFor(() => expect(changes.at(-1)?.complete).toBe(true));
    const latest = changes.at(-1);
    expect(latest.payload).toMatchObject({ bin: '424242', last4: '4242' });
    expect(latest.fields.cardNumber.complete).toBe(true);
    expect(latest.fields.cardExpiry.complete).toBe(true);
    expect(latest.fields.cardCvc.complete).toBe(true);
  });

  it('hands out a handle that carries no card data and no store', async () => {
    const { form, changes, type } = mountForm();
    await type();
    await waitFor(() => expect(changes.at(-1)?.complete).toBe(true));

    expect(Object.keys(form).sort()).toEqual([
      'Field',
      'Host',
      'focus',
      'getState',
      'on',
      'reset',
      'tokenize',
    ]);
    expect(JSON.stringify(form.getState())).not.toContain(PAN);
    expect(JSON.stringify(changes)).not.toContain(PAN);
  });

  it('keeps the card out of reach of whoever holds the handle', async () => {
    const { form, host, changes, type } = mountForm();
    await type();
    await waitFor(() => expect(changes.at(-1)?.complete).toBe(true));

    const seen = new Set<unknown>();
    const strings: string[] = [];
    const keys: string[] = [];
    const walk = (value: unknown) => {
      if (typeof value === 'string') strings.push(value);
      if (value === null || typeof value !== 'object' || seen.has(value)) return;
      seen.add(value);
      for (const key of Reflect.ownKeys(value)) {
        if (typeof key === 'string') keys.push(key);
        walk((value as Record<PropertyKey, unknown>)[key]);
      }
    };
    walk(form);
    walk(form.getState());
    type Drawn = { props: unknown; children: Array<Drawn | string> };
    const walkDrawn = (node: Drawn) => {
      walk(node.props);
      for (const child of node.children) {
        if (typeof child === 'string') strings.push(child);
        else walkDrawn(child);
      }
    };
    walkDrawn(host.UNSAFE_root as Drawn);
    walk((form.Field as (props: unknown) => unknown)({ children: null }));

    expect(strings.filter((text) => text.replace(/\s/g, '').includes(PAN))).toEqual([]);
    expect(keys).not.toContain('store');
    expect(keys).not.toContain('cvc');
    expect(keys).toContain('form');
  });

  it('tokenizes once, from the host, with the card the fields collected', async () => {
    const { form, changes, type } = mountForm();
    await type();
    await waitFor(() => expect(changes.at(-1)?.complete).toBe(true));

    await act(async () => {
      await form.tokenize();
    });

    /* The fields also fetch their brand icons; only the API call counts. */
    const confirms = network.apiCalls();
    expect(confirms).toHaveLength(1);
    expect(String(confirms[0]![0])).toMatch(
      /\/payment-method-sessions\/0a_pms_0192\/confirm$/
    );
    const body = String((confirms[0]![1] as { body?: unknown } | undefined)?.body);
    expect(body).toContain(PAN);
  });

  it('clears the card when the host unmounts', async () => {
    const { host, number, changes, type } = mountForm();
    await type();
    await waitFor(() => expect(changes.at(-1)?.complete).toBe(true));
    expect(
      number.getByTestId('CardNumberInputTestId').props.value
    ).not.toBe('');

    await act(async () => {
      host.unmount();
    });

    await waitFor(() =>
      expect(number.getByTestId('CardNumberInputTestId').props.value).toBe('')
    );
  });

  it('takes nothing typed after the host is gone', async () => {
    const { host, number, changes, type } = mountForm();
    await type();
    await waitFor(() => expect(changes.at(-1)?.complete).toBe(true));
    await act(async () => {
      host.unmount();
    });
    await waitFor(() =>
      expect(number.getByTestId('CardNumberInputTestId').props.value).toBe('')
    );

    /* A field in another root can outlive its form by a moment. */
    await act(async () => {
      number.getByTestId('CardNumberInputTestId').props.onChangeText(PAN);
    });
    expect(number.getByTestId('CardNumberInputTestId').props.value).toBe('');
  });

  it('clears the card once the vault has it, and keeps it when the vault refuses', async () => {
    const kept = mountForm();
    await kept.type();
    await waitFor(() => expect(kept.changes.at(-1)?.complete).toBe(true));
    network.restore();
    network = mockFetch({ ok: false, status: 500 });
    await act(async () => {
      expect((await kept.form.tokenize()).status).not.toBe('success');
    });
    expect(
      kept.number.getByTestId('CardNumberInputTestId').props.value
    ).not.toBe('');
    kept.host.unmount();

    network.restore();
    network = mockFetch({
      body: {
        associated_payment_methods: [
          { payment_method_token: { type: 'payment_method_id', data: 'pm_test_1' } },
        ],
      },
    });
    const cleared = mountForm();
    await cleared.type();
    await waitFor(() => expect(cleared.changes.at(-1)?.complete).toBe(true));
    await act(async () => {
      expect((await cleared.form.tokenize()).status).toBe('success');
    });
    await waitFor(() => {
      expect(
        cleared.number.getByTestId('CardNumberInputTestId').props.value
      ).toBe('');
      expect(cleared.cvc.getByTestId('CVCInputTestId').props.value).toBe('');
    });
    expect(cleared.changes.at(-1)?.complete).toBe(false);
  });

  it("holds no card in the vault's own state once the vault has it, nor after the host is gone", async () => {
    network.restore();
    network = mockFetch({
      body: {
        associated_payment_methods: [
          { payment_method_token: { type: 'payment_method_id', data: 'pm_test_1' } },
        ],
      },
    });
    const { form, host, number, expiry, cvc, changes, type } = mountForm();
    await type();
    await waitFor(() => expect(changes.at(-1)?.complete).toBe(true));

    type Fiber = {
      memoizedProps: unknown;
      memoizedState: unknown;
      child: Fiber | null;
      sibling: Fiber | null;
    };
    const fibersOf = (view: ReturnType<typeof render>): Fiber[] => {
      const out: Fiber[] = [];
      const visit = (fiber: Fiber | null) => {
        if (!fiber) return;
        out.push(fiber);
        visit(fiber.child);
        visit(fiber.sibling);
      };
      visit((view.UNSAFE_root as unknown as { _fiber: Fiber })._fiber);
      return out;
    };
    const held = (view: ReturnType<typeof render>): string[] => {
      const out: string[] = [];
      const seen = new Set<unknown>();
      const walk = (value: unknown) => {
        if (typeof value === 'string') out.push(value);
        if (value === null || typeof value !== 'object' || seen.has(value)) return;
        seen.add(value);
        for (const key of Object.keys(value as object)) {
          if (
            key === '_owner' ||
            key === 'return' ||
            key === 'stateNode' ||
            key === '_reactInternals' ||
            key === 'alternate'
          ) {
            continue;
          }
          walk((value as Record<string, unknown>)[key]);
        }
      };
      for (const fiber of fibersOf(view)) {
        walk(fiber.memoizedProps);
        let hook = fiber.memoizedState as { memoizedState?: unknown; next?: unknown } | null;
        while (hook && typeof hook === 'object' && 'next' in hook) {
          walk(hook.memoizedState);
          hook = hook.next as typeof hook;
        }
      }
      return out;
    };
    const controllerOf = (view: ReturnType<typeof render>): Record<string, any> => {
      for (const fiber of fibersOf(view)) {
        const value = (fiber.memoizedProps as { value?: Record<string, unknown> } | null)?.value;
        if (value && typeof value === 'object' && 'controller' in value) {
          return value.controller as Record<string, any>;
        }
      }
      throw new Error('The vault provider was not found in the tree.');
    };
    const views = () => [number, expiry, cvc];
    const withoutSpaces = (text: string) => text.replace(/\s/g, '');
    const holdsCard = () =>
      views().flatMap(held).filter((text) => withoutSpaces(text).includes(PAN));

    /* Sanity: while the card is being entered, the vault's state does hold it. */
    expect(withoutSpaces(controllerOf(number).cardDetails().cardNumber)).toBe(PAN);
    expect(holdsCard().length).toBeGreaterThan(0);

    await act(async () => {
      expect((await form.tokenize()).status).toBe('success');
    });
    await waitFor(() => {
      expect(controllerOf(number).cardDetails()).toEqual({
        cardNumber: '',
        expiryMonth: '',
        expiryYear: '',
        cvc: '',
      });
    });
    expect(controllerOf(number).values.cardNumber).toBe('');
    expect(controllerOf(number).values.cvc).toBe('');
    expect(holdsCard()).toEqual([]);

    /* Typed again, then the host goes: the store is wiped and sealed, so no root can
       reach the card any more, and nothing typed after lands anywhere. */
    await type();
    await waitFor(() => expect(changes.at(-1)?.complete).toBe(true));
    await act(async () => {
      host.unmount();
    });
    await waitFor(() => {
      expect(controllerOf(number).cardDetails()).toEqual({
        cardNumber: '',
        expiryMonth: '',
        expiryYear: '',
        cvc: '',
      });
    });
    await act(async () => {
      number.getByTestId('CardNumberInputTestId').props.onChangeText(PAN);
    });
    expect(controllerOf(number).cardDetails().cardNumber).toBe('');
    expect(holdsCard()).toEqual([]);
  });

  it('hands out a handle that cannot be altered', () => {
    const form = createDetachedCardForm({});
    expect(Object.isFrozen(form)).toBe(true);
    expect(() => {
      'use strict';
      (form as { tokenize: unknown }).tokenize = () => PAN;
    }).toThrow();
  });

  it('shows no more of a number than PCI truncation allows', async () => {
    const { number, changes } = mountForm();
    const enter = (text: string) =>
      act(async () => {
        number.getByTestId('CardNumberInputTestId').props.onChangeText(text);
      });
    const summary = () => changes.at(-1)?.payload ?? {};

    /* Sixteen digits that are not a valid number: no last four. */
    await enter('4242424242424241');
    await waitFor(() => expect(summary().bin).toBe('424242'));
    expect(summary().last4 ?? null).toBeNull();

    await enter(PAN);
    await waitFor(() => expect(summary().last4).toBe('4242'));
    expect(summary().extendedBin).toBe('42424242');

    /* American Express is fifteen digits: first six and last four, never eight. */
    await enter('378282246310005');
    await waitFor(() => expect(summary().last4).toBe('0005'));
    expect(summary().bin).toBe('378282');
    expect(summary().extendedBin ?? null).toBeNull();
  });

  it('refuses to tokenize when no host is mounted', async () => {
    const form = createDetachedCardForm({
      sdkAuthorization: AUTH,
      environment: 'sandbox',
    });
    const result = await form.tokenize();
    expect(result.status).not.toBe('success');
  });
});
