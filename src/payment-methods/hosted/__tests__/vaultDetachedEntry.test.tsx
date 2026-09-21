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

  it('refuses to tokenize when no host is mounted', async () => {
    const form = createDetachedCardForm({
      sdkAuthorization: AUTH,
      environment: 'sandbox',
    });
    const result = await form.tokenize();
    expect(result.status).not.toBe('success');
  });
});
