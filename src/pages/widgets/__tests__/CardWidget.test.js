import { describe, it, expect, beforeEach, jest } from '@jest/globals';
import * as React from 'react';
import { render, act } from '@testing-library/react-native';

/* The relay is the host's; here it records what CardWidget asks of it. */
jest.mock('../../../components/modules/HyperVaultRelayNative', () => ({
  isAvailable: jest.fn(() => true),
  openVaultForm: jest.fn(),
  tokenizeVaultForm: jest.fn(),
}));

/* Results and events go out on the widgets' existing channels. */
jest.mock('../../../components/modules/HyperModuleNative', () => ({
  ...jest.requireActual('../../../components/modules/HyperModuleNative'),
  notifyWidgetPaymentResult: jest.fn(),
  emitPaymentEvent: jest.fn(),
}));

/* The confirm itself (network, 3DS) is the existing redirect hook; it is replaced by a recorder. */
const mockRedirect = jest.fn();
jest.mock('../../../hooks/AllPaymentHooks.bs.js', () => ({
  ...jest.requireActual('../../../hooks/AllPaymentHooks.bs.js'),
  useRedirectHook: () => mockRedirect,
}));
jest.mock('../../../hooks/LoggerHook.bs.js', () => ({
  ...jest.requireActual('../../../hooks/LoggerHook.bs.js'),
  useLoggerHook: () => () => {},
}));

const relay = require('../../../components/modules/HyperVaultRelayNative');
const host = require('../../../components/modules/HyperModuleNative');
const { make: CardWidget } = require('../CardWidget.bs.js');
const SdkTypes = require('../../../types/SdkTypes.bs.js');
const NativePropContext = require('../../../contexts/NativePropContext.bs.js');
const CardStrategyContext = require('../../../contexts/CardStrategyContext.bs.js');
const AllApiDataContextNew = require('../../../contexts/AllApiDataContextNew.bs.js');

const ROOT_TAG = 41;
const sdkAuthorization = Buffer.from(
  'publishable_key=pk_snd_123,client_secret=pay_1_secret_abc,payment_id=pay_1',
  'utf8'
).toString('base64');

const nativePropWith = ({ attempt, cardForm = { formId: 'form_1' } } = {}) =>
  SdkTypes.nativeJsonToRecord(
    {
      type: 'card',
      hyperswitchConfig: { publishableKey: 'pk_snd_123' },
      paymentSessionConfig: { sdkAuthorization },
      ...(cardForm ? { cardForm } : {}),
      ...(attempt === undefined ? {} : { widgetConfirm: { attempt } }),
    },
    ROOT_TAG
  );

const vaultCard = {
  TAG: 'VaultCard',
  _0: {
    vaultTypeStr: 'hyperswitch',
    config: { TAG: 'HyperswitchVault', sdkAuthorization: 'vault-auth' },
  },
};

const element = (nativeProp, strategy) =>
  React.createElement(
    NativePropContext.nativePropContext.Provider,
    { value: [nativeProp, () => {}] },
    React.createElement(
      AllApiDataContextNew.allApiDataContext.Provider,
      { value: [undefined, undefined, undefined] },
      React.createElement(
        CardStrategyContext.cardStrategyContext.Provider,
        {
          value: {
            strategy,
            getFormState: () => ({ isValid: false, showErrors: false }),
            setFormValid: () => {},
            setShowErrors: () => {},
          },
        },
        React.createElement(CardWidget, {})
      )
    )
  );

const results = () => host.notifyWidgetPaymentResult.mock.calls;
const events = () => host.emitPaymentEvent.mock.calls;

const tokenReply = (tokens) =>
  JSON.stringify({
    commandId: 'c',
    name: 'tokenize',
    ok: true,
    result: { status: 'success', vaultType: 'hyperswitch', data: { tokens } },
  });

/* Lets the relay's promise and its continuation run. */
const settle = () => act(async () => {});

/* The redirect hook answers through ~responseCallback, its 7th (positional) argument. */
const respond = (call, status) => act(() => call[6]('PaymentSuccess', { status }));

beforeEach(() => {
  jest.clearAllMocks();
  relay.isAvailable.mockImplementation(() => true);
});

describe('CardWidget', () => {
  it('opens the vault form once, however often it re-renders', () => {
    const view = render(element(nativePropWith(), vaultCard));
    view.rerender(element(nativePropWith(), vaultCard));

    expect(relay.openVaultForm).toHaveBeenCalledTimes(1);
    const [tag, json] = relay.openVaultForm.mock.calls[0];
    expect(tag).toBe(ROOT_TAG);
    expect(JSON.parse(json)).toMatchObject({
      formId: 'form_1',
      type: 'paymentMethodsForm',
      vaultDetails: { vaultType: 'hyperswitch', vaultData: { sdkAuthorization: 'vault-auth' } },
    });
    expect(events()).toEqual([]);
  });

  it('reports once why a skip profile cannot pay, and opens nothing', () => {
    const view = render(element(nativePropWith(), 'DirectCard'));
    view.rerender(element(nativePropWith(), 'DirectCard'));

    expect(relay.openVaultForm).not.toHaveBeenCalled();
    expect(events()).toEqual([
      [ROOT_TAG, 'error', { code: 'unsupported_configuration', message: expect.any(String) }],
    ]);
  });

  it('reports sdk_not_ready when the host has no relay', () => {
    relay.isAvailable.mockImplementation(() => false);
    render(element(nativePropWith(), vaultCard));

    expect(relay.openVaultForm).not.toHaveBeenCalled();
    expect(events()[0][2].code).toBe('sdk_not_ready');
  });

  it('tokenizes, confirms with the token and reports the outcome', async () => {
    relay.tokenizeVaultForm.mockResolvedValue(tokenReply({ payment_method_token: 'tok_1' }));

    const view = render(element(nativePropWith(), vaultCard));
    view.rerender(element(nativePropWith({ attempt: 0 }), vaultCard));
    await settle();

    expect(relay.tokenizeVaultForm).toHaveBeenCalledWith(ROOT_TAG, 'form_1');
    expect(mockRedirect).toHaveBeenCalledTimes(1);
    const call = mockRedirect.mock.calls[0];
    const body = JSON.parse(call[0]);
    expect(body).toMatchObject({ payment_method: 'card', payment_token: 'tok_1' });
    expect(body).not.toHaveProperty('client_secret');

    respond(call, 'succeeded');
    expect(results()).toEqual([[ROOT_TAG, { status: 'succeeded' }]]);
  });

  it('ignores a confirm that overlaps a running one, and reports only the first', async () => {
    let resolveTokenize;
    relay.tokenizeVaultForm.mockReturnValue(new Promise((resolve) => (resolveTokenize = resolve)));

    const view = render(element(nativePropWith({ attempt: 0 }), vaultCard));
    view.rerender(element(nativePropWith({ attempt: 1 }), vaultCard));

    expect(relay.tokenizeVaultForm).toHaveBeenCalledTimes(1);
    expect(results()).toEqual([]);

    resolveTokenize(tokenReply({ payment_method_token: 'tok_1' }));
    await settle();
    expect(mockRedirect).toHaveBeenCalledTimes(1);
    respond(mockRedirect.mock.calls[0], 'processing');
    expect(results()).toEqual([[ROOT_TAG, { status: 'processing' }]]);
  });

  it('reports validation_error and confirms nothing when the fields are incomplete', async () => {
    relay.tokenizeVaultForm.mockResolvedValue(
      JSON.stringify({
        ok: true,
        result: {
          status: 'validation_error',
          error: { code: 'validation_error', message: 'x', type: 'validation_error' },
        },
      })
    );
    render(element(nativePropWith({ attempt: 3 }), vaultCard));
    await settle();

    expect(mockRedirect).not.toHaveBeenCalled();
    expect(results()).toEqual([
      [ROOT_TAG, { status: 'failed', code: 'validation_error', message: expect.any(String) }],
    ]);
  });

  it('refuses a confirm while the data is still loading, and one for a skip profile', () => {
    render(element(nativePropWith({ attempt: 0 }), 'Pending'));
    render(element(nativePropWith({ attempt: 0 }), 'DirectCard'));

    expect(relay.tokenizeVaultForm).not.toHaveBeenCalled();
    expect(results().map(([, payload]) => payload.code)).toEqual([
      'sdk_not_ready',
      'unsupported_configuration',
    ]);
  });
});
