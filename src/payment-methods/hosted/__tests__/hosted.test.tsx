import { describe, it, expect, jest, afterEach } from '@jest/globals';
import { render, waitFor, act } from '@testing-library/react-native';

import { createMockAdapter } from '../../__fixtures__/mockAdapter';
import type { MockAdapterOptions } from '../../__fixtures__/mockAdapter';
import { registerAdapter } from '../../providers/registry';
import type { ElementType } from '../../core/types';
import type { HostBridge, RawCommand } from '../bridge';
import { startCommands } from '../commands';
import { FieldSurface } from '../FieldSurface';
import { FormSurface } from '../FormSurface';
import { getForm } from '../forms';
import {
  FieldEvent,
  FormEvent,
  PROTOCOL_VERSION,
  SURFACE_TYPE_FIELD,
  SURFACE_TYPE_FORM,
} from '../protocol';
import type { CommandResultPayload } from '../protocol';

const FORM_ID = 'form-1';
const FORM_TAG = 5;

const cleanups: Array<() => void> = [];
afterEach(() => {
  while (cleanups.length) cleanups.pop()!();
});

function useMock(options: MockAdapterOptions = {}) {
  cleanups.push(
    registerAdapter(createMockAdapter({ vaultType: 'vgs', ...options }))
  );
}

function mockHost() {
  const fieldEvents: Array<{ rootTag: number; event: string; payload: any }> =
    [];
  const formEvents: Array<{ rootTag: number; event: string; payload: any }> =
    [];
  let listener: ((command: RawCommand) => void) | null = null;

  const bridge: HostBridge = {
    emitField: (rootTag, event, payload) =>
      void fieldEvents.push({ rootTag, event, payload }),
    emitForm: (rootTag, event, payload) =>
      void formEvents.push({ rootTag, event, payload }),
    onCommand: (next) => {
      listener = next;
      return () => {
        listener = null;
      };
    },
  };
  cleanups.push(startCommands(bridge));

  return {
    bridge,
    fieldEvents,
    formEvents,
    form: (event: string) => formEvents.filter((e) => e.event === event),
    field: (event: string) => fieldEvents.filter((e) => e.event === event),
    send: (command: RawCommand) => listener?.(command),
    replyTo: (commandId: string) =>
      formEvents.find(
        (e) =>
          e.event === FormEvent.CommandResult &&
          e.payload.commandId === commandId
      )?.payload as CommandResultPayload | undefined,
  };
}

const formProps = (overrides: Record<string, unknown> = {}) => ({
  type: SURFACE_TYPE_FORM,
  protocolVersion: PROTOCOL_VERSION,
  formId: FORM_ID,
  hyper: { publishableKey: 'pk_snd_1' },
  vaultDetails: { vaultType: 'vgs', vaultData: {} },
  ...overrides,
});

const fieldProps = (
  elementType: ElementType,
  overrides: Record<string, unknown> = {}
) => ({
  type: SURFACE_TYPE_FIELD,
  protocolVersion: PROTOCOL_VERSION,
  formId: FORM_ID,
  elementType,
  ...overrides,
});

const ROOT_TAG: Record<ElementType, number> = {
  cardNumber: 11,
  cardExpiry: 21,
  cardCvc: 31,
  cardholderName: 41,
};

/* Each call is its own React root, which is what a native field view is. */
const mountField = (
  host: ReturnType<typeof mockHost>,
  elementType: ElementType,
  overrides: Record<string, unknown> = {}
) =>
  render(
    <FieldSurface
      props={fieldProps(elementType, overrides)}
      rootTag={ROOT_TAG[elementType]}
      bridge={host.bridge}
    />
  );

const mountForm = (
  host: ReturnType<typeof mockHost>,
  overrides: Record<string, unknown> = {},
  rootTag = FORM_TAG
) =>
  render(
    <FormSurface
      props={formProps(overrides)}
      rootTag={rootTag}
      bridge={host.bridge}
    />
  );

const shows = (view: ReturnType<typeof render>, elementType: ElementType) =>
  view.queryByTestId(`mock-field-${elementType}`) !== null;

describe('hosted payment methods: separate roots acting as one form', () => {
  it('binds three field roots to one form and reports it once', async () => {
    const onTokenize = jest.fn();
    useMock({
      onTokenize,
      fieldState: { empty: false, valid: true, touched: true },
    });
    const host = mockHost();

    mountForm(host);
    const number = mountField(host, 'cardNumber');
    const expiry = mountField(host, 'cardExpiry');
    const cvc = mountField(host, 'cardCvc');

    await waitFor(() => expect(shows(number, 'cardNumber')).toBe(true));
    await waitFor(() => expect(shows(expiry, 'cardExpiry')).toBe(true));
    await waitFor(() => expect(shows(cvc, 'cardCvc')).toBe(true));

    await waitFor(() => expect(host.form(FormEvent.Ready)).toHaveLength(1));
    await waitFor(() =>
      expect(host.form(FormEvent.Change).length).toBeGreaterThan(0)
    );

    const latest = host.form(FormEvent.Change).at(-1)!.payload;
    expect(Object.keys(latest.fields).sort()).toEqual([
      'cardCvc',
      'cardExpiry',
      'cardNumber',
    ]);
    expect(latest.valid).toBe(true);

    /* Each field reported to its own view, the form to its own screen. */
    expect(
      host.field(FieldEvent.Change).map((e) => e.rootTag).sort()
    ).toEqual([11, 21, 31]);
    expect(host.formEvents.every((e) => e.rootTag === FORM_TAG)).toBe(true);

    await act(async () => {
      host.send({ rootTag: FORM_TAG, formId: FORM_ID, commandId: 'c1', name: 'tokenize' });
    });
    await waitFor(() => expect(host.replyTo('c1')).toBeDefined());
    expect(host.replyTo('c1')).toMatchObject({ ok: true });
    expect(host.replyTo('c1')!.result?.status).toBe('success');
    expect(onTokenize).toHaveBeenCalledTimes(1);
  });

  it('sends one form change per field report, never one per field view', async () => {
    useMock({ fieldState: { empty: false, valid: true, touched: true } });
    const host = mockHost();

    mountForm(host);
    mountField(host, 'cardNumber');
    mountField(host, 'cardExpiry');
    mountField(host, 'cardCvc');

    await waitFor(() => expect(host.field(FieldEvent.Change)).toHaveLength(3));
    expect(host.form(FormEvent.Change)).toHaveLength(3);

    /* Each one is the whole form as it stood at that report. */
    const seen = host
      .form(FormEvent.Change)
      .map((e) => Object.keys(e.payload.fields).length);
    expect(seen).toEqual([1, 2, 3]);
  });

  it('lets a field start before its form and draws it once the form opens', async () => {
    useMock();
    const host = mockHost();

    const number = mountField(host, 'cardNumber');
    expect(shows(number, 'cardNumber')).toBe(false);

    mountForm(host);
    await waitFor(() => expect(shows(number, 'cardNumber')).toBe(true));
  });

  it('forwards field options, including testID, to the provider field', async () => {
    useMock();
    const host = mockHost();
    mountForm(host);
    const cvc = mountField(host, 'cardCvc', {
      placeholder: 'CVC',
      testID: 'cvc-input',
    });

    await waitFor(() => expect(shows(cvc, 'cardCvc')).toBe(true));
    const forwarded = JSON.parse(
      cvc.getByTestId('mock-field-cardCvc').props.accessibilityValue.text
    ) as { placeholder?: string; testID?: string };
    expect(forwarded).toMatchObject({ placeholder: 'CVC', testID: 'cvc-input' });
  });
});

describe('hosted payment methods: commands', () => {
  it('drives a field command through to the provider field', async () => {
    const onFieldCommand = jest.fn();
    useMock({ onFieldCommand });
    const host = mockHost();
    mountForm(host);
    const cvc = mountField(host, 'cardCvc');
    await waitFor(() => expect(shows(cvc, 'cardCvc')).toBe(true));

    await act(async () => {
      host.send({
        rootTag: FORM_TAG,
        formId: FORM_ID,
        commandId: 'c1',
        name: 'focus',
        elementType: 'cardCvc',
      });
    });
    await waitFor(() => expect(host.replyTo('c1')).toBeDefined());
    expect(onFieldCommand).toHaveBeenCalledWith('cardCvc', 'focus');
    expect(host.replyTo('c1')).toMatchObject({ ok: true });
  });

  it('answers every command it cannot run, and says why', async () => {
    useMock();
    const host = mockHost();
    mountForm(host);
    await waitFor(() => expect(getForm(FORM_ID)?.instance).toBeDefined());

    await act(async () => {
      host.send({
        rootTag: FORM_TAG,
        formId: FORM_ID,
        commandId: 'c1',
        name: 'clear',
        elementType: 'cardholderName',
      });
      host.send({ rootTag: FORM_TAG, formId: FORM_ID, commandId: 'c2', name: 'explode' });
      host.send({
        rootTag: 99,
        formId: 'nobody',
        commandId: 'c3',
        name: 'tokenize',
      });
    });

    await waitFor(() => expect(host.replyTo('c3')).toBeDefined());
    expect(host.replyTo('c1')).toMatchObject({ ok: false });
    expect(host.replyTo('c1')!.message).toMatch(/no "cardholderName" field/);
    expect(host.replyTo('c2')!.message).toMatch(/Unknown command "explode"/);
    expect(host.replyTo('c3')!.result?.status).toBe('validation_error');

    /* An answer goes to the screen the command named, known form or not. */
    const answeredTo = (commandId: string) =>
      host.formEvents.find((e) => e.payload.commandId === commandId)?.rootTag;
    expect(answeredTo('c1')).toBe(FORM_TAG);
    expect(answeredTo('c3')).toBe(99);
  });
});

describe('hosted payment methods: a form ends when its screen ends', () => {
  it('drops the form, blanks its fields and refuses to tokenize afterwards', async () => {
    const onTokenize = jest.fn();
    useMock({ onTokenize });
    const host = mockHost();
    const form = mountForm(host);
    const number = mountField(host, 'cardNumber');
    await waitFor(() => expect(shows(number, 'cardNumber')).toBe(true));

    await act(async () => {
      form.unmount();
    });

    expect(getForm(FORM_ID)).toBeUndefined();
    expect(shows(number, 'cardNumber')).toBe(false);

    await act(async () => {
      host.send({ rootTag: FORM_TAG, formId: FORM_ID, commandId: 'c1', name: 'tokenize' });
    });
    await waitFor(() => expect(host.replyTo('c1')).toBeDefined());
    expect(host.replyTo('c1')!.result?.status).toBe('validation_error');
    expect(onTokenize).not.toHaveBeenCalled();
  });

  it('keeps the same form when the host re-sends equal props', async () => {
    useMock();
    const host = mockHost();
    const form = mountForm(host);
    await waitFor(() => expect(getForm(FORM_ID)?.instance).toBeDefined());
    const before = getForm(FORM_ID)!.instance;

    await act(async () => {
      form.rerender(
        <FormSurface
          props={formProps()}
          rootTag={FORM_TAG}
          bridge={host.bridge}
        />
      );
    });

    expect(getForm(FORM_ID)!.instance).toBe(before);
    expect(host.form(FormEvent.Error)).toHaveLength(0);
  });

  it('refuses a second screen for a form that is already open', async () => {
    useMock();
    const host = mockHost();
    mountForm(host);
    await waitFor(() => expect(getForm(FORM_ID)?.instance).toBeDefined());
    const before = getForm(FORM_ID)!.instance;

    const second = mountForm(host, {}, FORM_TAG + 1);
    await waitFor(() => expect(host.form(FormEvent.Error)).toHaveLength(1));
    expect(host.form(FormEvent.Error)[0]!.payload.message).toMatch(
      /already open/
    );
    /* The refusal goes to the screen that was refused, not to the real form. */
    expect(host.form(FormEvent.Error)[0]!.rootTag).toBe(FORM_TAG + 1);

    /* Ending the refused screen must not end the real form. */
    await act(async () => {
      second.unmount();
    });
    expect(getForm(FORM_ID)!.instance).toBe(before);
  });
});

describe('hosted payment methods: what it refuses', () => {
  it('says so when the vault cannot show fields as separate views', async () => {
    const { createCollector: _createCollector, ...contextOnly } =
      createMockAdapter({ vaultType: 'vgs' });
    cleanups.push(registerAdapter(contextOnly));
    const host = mockHost();

    mountForm(host);
    await waitFor(() => expect(host.form(FormEvent.Error)).toHaveLength(1));
    expect(host.form(FormEvent.Error)[0]!.payload.message).toMatch(
      /cannot be mounted detached/
    );
    expect(getForm(FORM_ID)?.failed).toBe(true);
    expect(getForm(FORM_ID)?.instance?.status).toBe('error');
  });

  it('reports unusable props to the right place', async () => {
    useMock();
    const host = mockHost();

    mountForm(host, { protocolVersion: PROTOCOL_VERSION + 1, formId: '' });
    mountField(host, 'cardNumber', { elementType: 'cardPin' });

    /* Even props too broken to name a form reach the form screen's owner. */
    await waitFor(() => expect(host.form(FormEvent.Error)).toHaveLength(1));
    expect(host.form(FormEvent.Error)[0]).toMatchObject({ rootTag: FORM_TAG });
    expect(host.form(FormEvent.Error)[0]!.payload.message).toMatch(
      /Update the SDK bundle/
    );
    await waitFor(() => expect(host.field(FieldEvent.Error)).toHaveLength(1));
    expect(host.field(FieldEvent.Error)[0]).toMatchObject({ rootTag: 11 });
  });
});
