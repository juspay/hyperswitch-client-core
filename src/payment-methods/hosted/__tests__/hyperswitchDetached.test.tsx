import { describe, it, expect, afterEach } from '@jest/globals';
import { render, waitFor, act } from '@testing-library/react-native';

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

function mount(host: ReturnType<typeof mockHost>) {
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
      last4: '4242',
      brand: expect.stringMatching(/visa/i),
    });
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
