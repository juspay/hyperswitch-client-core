import { describe, it, expect, afterEach } from '@jest/globals';
import { render, waitFor, act } from '@testing-library/react-native';
import { StyleSheet } from 'react-native';

import { mockFetch } from '../../__fixtures__/mockFetch';
import type { ElementType } from '../../core/types';
import type { HostBridge, RawCommand } from '../bridge';
import { startCommands } from '../commands';
import { FieldSurface } from '../FieldSurface';
import { FormSurface } from '../FormSurface';
import { getForm } from '../forms';
import {
  hyperswitchDetachedAvailable,
  registerHostedAdapters,
} from '../hyperswitchDetached';
import {
  FormEvent,
  PROTOCOL_VERSION,
  SURFACE_TYPE_FIELD,
  SURFACE_TYPE_FORM,
} from '../protocol';
import type { CommandResultPayload } from '../protocol';
import { toWire } from '../wire';

/* The real Hyperswitch vault behind the hosted screens, the way the PM bundle
   wires it. Only the network is mocked. */

const FORM_ID = 'form-hs';
const FORM_TAG = 5;
const PAN = '4242424242424242';
const CVC = '123';
const AUTH = Buffer.from(
  'payment_method_session_id=0a_pms_0192,profile_id=pro_456',
  'utf8'
).toString('base64');

const INPUT: Record<string, string> = {
  cardNumber: 'CardNumberInputTestId',
  cardExpiry: 'ExpiryInputTestId',
  cardCvc: 'CVCInputTestId',
};

const cleanups: Array<() => void> = [];
afterEach(() => {
  while (cleanups.length) cleanups.pop()!();
});

const mockNetwork = (...args: Parameters<typeof mockFetch>) => {
  const network = mockFetch(...args);
  cleanups.push(network.restore);
  return network;
};

function mockHost() {
  /* Everything is recorded as it would cross to native: after the wire rules. */
  const sent: Array<{ to: number; event: string; payload: any }> = [];
  let listener: ((command: RawCommand) => void) | null = null;

  const bridge: HostBridge = {
    emitField: (rootTag, event, payload) =>
      void sent.push({ to: rootTag, event, payload: toWire(event, payload) }),
    emitForm: (rootTag, event, payload) =>
      void sent.push({ to: rootTag, event, payload: toWire(event, payload) }),
    onCommand: (next) => {
      listener = next;
      return () => {
        listener = null;
      };
    },
  };
  cleanups.push(startCommands(bridge));
  cleanups.push(registerHostedAdapters());

  return {
    bridge,
    sent,
    of: (event: string) => sent.filter((e) => e.event === event),
    send: (command: RawCommand) => listener?.(command),
    replyTo: (commandId: string) =>
      sent.find(
        (e) =>
          e.event === FormEvent.CommandResult &&
          e.payload.commandId === commandId
      )?.payload as CommandResultPayload | undefined,
  };
}

function mount(
  host: ReturnType<typeof mockHost>,
  extra: { form?: object; cardNumber?: object } = {}
) {
  const form = render(
    <FormSurface
      bridge={host.bridge}
      rootTag={FORM_TAG}
      props={{
        type: SURFACE_TYPE_FORM,
        protocolVersion: PROTOCOL_VERSION,
        formId: FORM_ID,
        hyper: { publishableKey: 'pk_snd_1', environment: 'SANDBOX' },
        vaultDetails: {
          vaultType: 'hyperswitch',
          vaultData: { sdkAuthorization: AUTH, environment: 'SANDBOX' },
        },
        ...extra.form,
      }}
    />
  );
  const field = (elementType: ElementType, rootTag: number) =>
    render(
      <FieldSurface
        bridge={host.bridge}
        rootTag={rootTag}
        props={{
          type: SURFACE_TYPE_FIELD,
          protocolVersion: PROTOCOL_VERSION,
          formId: FORM_ID,
          elementType,
          ...(elementType === 'cardNumber' ? extra.cardNumber : undefined),
        }}
      />
    );
  const views = {
    cardNumber: field('cardNumber', 11),
    cardExpiry: field('cardExpiry', 21),
    cardCvc: field('cardCvc', 31),
  };

  /* Not fireEvent: the testing library ignores events for any root but the
     most recently rendered one. */
  const enter = (elementType: keyof typeof views, text: string) =>
    act(async () => {
      views[elementType].getByTestId(INPUT[elementType]!).props.onChangeText(text);
    });

  const ready = () =>
    waitFor(() =>
      expect(views.cardCvc.queryByTestId(INPUT.cardCvc!) !== null).toBe(true)
    );

  const typeCard = async () => {
    await ready();
    await enter('cardNumber', PAN);
    await enter('cardExpiry', '12/30');
    await enter('cardCvc', CVC);
  };

  return { form, views, typeCard };
}

const tokenize = (host: ReturnType<typeof mockHost>) =>
  act(async () => {
    host.send({
      rootTag: FORM_TAG,
      formId: FORM_ID,
      commandId: 'c1',
      name: 'tokenize',
    });
  });

const describeIfAvailable = hyperswitchDetachedAvailable
  ? describe
  : describe.skip;

describeIfAvailable('hosted screens over the real Hyperswitch vault', () => {
  it('collects a card across three field screens and reports it as one form', async () => {
    const host = mockHost();
    mockNetwork();
    const { typeCard } = mount(host);
    await typeCard();

    await waitFor(() =>
      expect(host.of(FormEvent.Change).at(-1)?.payload.complete).toBe(true)
    );
    const latest = host.of(FormEvent.Change).at(-1)!.payload;
    expect(latest.payload).toMatchObject({
      bin: '424242',
      extendedBin: '42424242',
      brand: expect.stringMatching(/visa/i),
    });
    expect(latest.payload).not.toHaveProperty('last4');
    expect(Object.keys(latest.fields).sort()).toEqual([
      'cardCvc',
      'cardExpiry',
      'cardNumber',
    ]);
  });

  it('never lets the card number or CVC cross to the host', async () => {
    const host = mockHost();
    mockNetwork({ ok: false, status: 400 });

    const { typeCard } = mount(host);
    await typeCard();
    await tokenize(host);
    await waitFor(() => expect(host.replyTo('c1')).toBeDefined());

    const everything = JSON.stringify(host.sent);
    expect(everything).not.toContain(PAN);
    expect(everything).not.toContain('4242 4242 4242 4242');
    expect(host.sent.some((e) => JSON.stringify(e).includes(`"${CVC}"`))).toBe(
      false
    );
  });

  it('tokenizes exactly once for one command', async () => {
    const host = mockHost();
    const { apiCalls } = mockNetwork();

    const { typeCard } = mount(host);
    await typeCard();
    await tokenize(host);
    await waitFor(() => expect(host.replyTo('c1')).toBeDefined());

    const confirms = apiCalls();
    expect(confirms).toHaveLength(1);
    expect(String(confirms[0]![0])).toMatch(/\/confirm$/);
    expect(
      String((confirms[0]![1] as { body?: unknown } | undefined)?.body)
    ).toContain(PAN);
    expect(host.of(FormEvent.CommandResult)).toHaveLength(1);
  });

  it('sends the card to the vault and nowhere else', async () => {
    const host = mockHost();
    const network = mockNetwork({
      body: {
        associated_payment_methods: [
          { payment_method_token: { type: 'payment_method_id', data: 'pm_test_1' } },
        ],
      },
    });
    const { typeCard } = mount(host, { form: { vaultDetails: undefined, sdkAuthorization: AUTH } });
    await typeCard();
    await waitFor(() =>
      expect(host.of(FormEvent.Change).at(-1)?.payload.complete).toBe(true)
    );
    await act(async () => {
      host.send({ rootTag: FORM_TAG, formId: FORM_ID, commandId: 'net-1', name: 'tokenize' });
    });
    await waitFor(() => expect(host.replyTo('net-1')?.ok).toBe(true));

    const calls = (globalThis.fetch as unknown as { mock: { calls: unknown[][] } }).mock.calls;
    const api = network.apiCalls() as Array<[string, { method?: string; body?: string; headers?: Record<string, string> }]>;
    const carriesCard = (text: unknown) =>
      typeof text === 'string' && (text.includes(PAN) || text.includes(CVC));

    expect(api.map(([url, init]) => `${init?.method ?? 'GET'} ${url}`)).toEqual([
      'GET https://app.hyperswitch.io/api/v1/payment-method-sessions/0a_pms_0192',
      'POST https://app.hyperswitch.io/api/v1/payment-method-sessions/0a_pms_0192/confirm',
    ]);
    const [lookup, confirm] = api;
    expect(lookup![1]?.body).toBeUndefined();
    expect(lookup![1]?.headers?.Authorization).toBe(AUTH);
    expect(confirm![1]?.headers?.Authorization).toBe(AUTH);
    expect(JSON.parse(confirm![1]!.body!)).toEqual({
      payment_method_type: 'card',
      payment_method_data: {
        card: { card_number: PAN, card_exp_month: '12', card_exp_year: '2030', card_cvc: CVC },
      },
    });
    for (const [url, init] of calls as Array<[unknown, { body?: unknown } | undefined]>) {
      expect(carriesCard(url)).toBe(false);
      if (init !== confirm![1]) expect(carriesCard(init?.body)).toBe(false);
    }
    /* Everything else the vault fetched is a brand icon. */
    for (const [url] of calls) {
      if (!api.some(([apiUrl]) => apiUrl === url)) expect(String(url)).toMatch(/\.svg$/);
    }
    expect(JSON.stringify(host.sent)).not.toContain(PAN);
    expect(JSON.stringify(host.sent)).not.toContain(CVC);
  });

  it('never sends the host the same form change twice in a row', async () => {
    const host = mockHost();
    mockNetwork();
    const { typeCard } = mount(host);
    await typeCard();
    await waitFor(() =>
      expect(host.of(FormEvent.Change).at(-1)?.payload.complete).toBe(true)
    );

    const sent = host.of(FormEvent.Change).map((e) => JSON.stringify(e.payload));
    expect(sent.length).toBeGreaterThan(0);
    sent.forEach((change, index) => {
      if (index > 0) expect(change).not.toBe(sent[index - 1]);
    });
  });

  it('draws the fields the way the host asked for', async () => {
    const host = mockHost();
    mockNetwork();
    /* As CardFormAppearance and CardFieldStyle build them on both platforms. */
    const { views } = mount(host, {
      form: {
        appearance: {
          colors: { light: { componentText: '#101010' }, dark: { componentText: '#F5F5F5' } },
          shapes: { borderRadius: 12 },
          font: { family: 'Inter' },
        },
      },
      cardNumber: { styles: { input: { color: '#FF0000' } } },
    });
    await waitFor(() =>
      expect(views.cardCvc.queryByTestId(INPUT.cardCvc!) !== null).toBe(true)
    );

    const styleOf = (view: ReturnType<typeof render>, testID: string) =>
      StyleSheet.flatten(view.getByTestId(testID).props.style) as Record<string, unknown>;

    /* The form's type reaches every field... */
    expect(styleOf(views.cardExpiry, INPUT.cardExpiry!).fontFamily).toBe('Inter');
    expect(styleOf(views.cardExpiry, INPUT.cardExpiry!).color).toBe('#101010');
    /* ...and a field's own style wins over it. */
    expect(styleOf(views.cardNumber, INPUT.cardNumber!).color).toBe('#FF0000');
  });

  it('offers a saved card only when the host asks for it', async () => {
    const host = mockHost();
    mockNetwork();
    const plain = mount(host);
    await waitFor(() =>
      expect(plain.views.cardCvc.queryByTestId(INPUT.cardCvc!) !== null).toBe(true)
    );
    const propsOf = (view: ReturnType<typeof render>, testID: string) =>
      view.getByTestId(testID).props as Record<string, unknown>;

    /* A card field says it holds a one-time code, so no keyboard offers a card. */
    expect(propsOf(plain.views.cardNumber, INPUT.cardNumber!).autoComplete).toBe('off');
    expect(propsOf(plain.views.cardNumber, INPUT.cardNumber!).textContentType).toBe(
      'oneTimeCode'
    );
    plain.form.unmount();

    const asked = mount(mockHost(), { form: { autofill: true } });
    await waitFor(() =>
      expect(asked.views.cardCvc.queryByTestId(INPUT.cardCvc!) !== null).toBe(true)
    );
    expect(propsOf(asked.views.cardNumber, INPUT.cardNumber!).autoComplete).toBe('cc-number');
    expect(propsOf(asked.views.cardNumber, INPUT.cardNumber!).textContentType).toBe(
      'creditCardNumber'
    );
    expect(propsOf(asked.views.cardExpiry, INPUT.cardExpiry!).autoComplete).toBe('cc-exp');
    expect(propsOf(asked.views.cardCvc, INPUT.cardCvc!).autoComplete).toBe('cc-csc');
  });

  it('clears a field when the host asks, in the vault and not only in its answer', async () => {
    const host = mockHost();
    mockNetwork();
    const { views, typeCard } = mount(host);
    await typeCard();
    await waitFor(() =>
      expect(host.of(FormEvent.Change).at(-1)?.payload.complete).toBe(true)
    );

    await act(async () => {
      host.send({
        rootTag: FORM_TAG,
        formId: FORM_ID,
        commandId: 'clear-1',
        name: 'clear',
        elementType: 'cardNumber',
      });
    });
    await waitFor(() => expect(host.replyTo('clear-1')?.ok).toBe(true));

    await waitFor(() =>
      expect(views.cardNumber.getByTestId(INPUT.cardNumber!).props.value).toBe('')
    );
    await waitFor(() => {
      const latest = host.of(FormEvent.Change).at(-1)?.payload;
      expect(latest.complete).toBe(false);
      expect(latest.payload.last4 ?? null).toBeNull();
      expect(latest.payload.bin ?? null).toBeNull();
    });
  });

  it('clears the card when the form screen stops', async () => {
    const host = mockHost();
    mockNetwork();
    const { form, views, typeCard } = mount(host);
    await typeCard();
    expect(
      views.cardNumber.getByTestId(INPUT.cardNumber!).props.value
    ).not.toBe('');

    await act(async () => {
      form.unmount();
    });

    expect(getForm(FORM_ID)).toBeUndefined();
    expect(views.cardNumber.queryByTestId(INPUT.cardNumber!)).toBeNull();
    expect(views.cardCvc.queryByTestId(INPUT.cardCvc!)).toBeNull();
  });
});
