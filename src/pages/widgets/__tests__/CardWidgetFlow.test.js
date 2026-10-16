import { describe, it, expect } from '@jest/globals';

import * as Flow from '../CardWidgetFlow.bs.js';
import { readFormDescriptor } from '../../../payment-methods/hosted/descriptor';
import { PROTOCOL_VERSION, SURFACE_TYPE_FORM } from '../../../payment-methods/hosted/protocol';
import { errorResult } from '../../../payment-methods/core/results';

/* ReScript's runtime shapes for the values CardWidget receives. */
const hyperswitchVault = {
  vaultTypeStr: 'hyperswitch',
  config: { TAG: 'HyperswitchVault', sdkAuthorization: 'vault-auth' },
};
const vgsVault = {
  vaultTypeStr: 'vgs',
  config: { TAG: 'VgsVault', vaultId: 'tnt_123', environment: 'sandbox' },
};

const descriptor = (vaultDetails, extra = {}) =>
  Flow.descriptorOf(
    'form_1',
    'pk_snd_123',
    extra.profileId,
    'SANDBOX',
    vaultDetails,
    extra.appearance,
    extra.locale
  );

/* The hosted form's PM_COMMAND_RESULT for one tokenize, as the relay hands it over. */
const reply = (result, ok = true, message) =>
  JSON.stringify({ commandId: 'c1', name: 'tokenize', ok, message, result });

describe('descriptorOf', () => {
  it('builds a descriptor the hosted form accepts, with the vault details it needs', () => {
    const built = descriptor(hyperswitchVault, { profileId: 'pro_1', locale: 'en' });
    const parsed = readFormDescriptor(built);

    expect(parsed.ok).toBe(true);
    expect(built).toEqual({
      protocolVersion: PROTOCOL_VERSION,
      type: SURFACE_TYPE_FORM,
      formId: 'form_1',
      hyper: { publishableKey: 'pk_snd_123', environment: 'SANDBOX', profileId: 'pro_1' },
      vaultDetails: {
        vaultType: 'hyperswitch',
        vaultData: { sdkAuthorization: 'vault-auth', environment: 'SANDBOX' },
      },
      locale: 'en',
    });
  });

  it('passes a VGS vault and the merchant appearance through unchanged', () => {
    const appearance = { variables: { colorPrimary: '#000' } };
    const built = descriptor(vgsVault, { appearance });

    expect(readFormDescriptor(built).ok).toBe(true);
    expect(built.vaultDetails).toEqual({
      vaultType: 'vgs',
      vaultData: { vaultId: 'tnt_123', environment: 'sandbox' },
    });
    expect(built.appearance).toBe(appearance);
    expect(built).not.toHaveProperty('locale');
  });
});

describe('outcomeOfReply', () => {
  it('turns a Hyperswitch vault token into a payment_token', () => {
    const outcome = Flow.outcomeOfReply(
      reply({
        status: 'success',
        vaultType: 'hyperswitch',
        data: { tokens: { payment_method_token: 'tok_1' } },
      })
    );
    expect(outcome).toEqual({
      TAG: 'Tokenized',
      _0: { fragment: { payment_token: 'tok_1' }, savedCardToken: undefined },
    });
  });

  it('turns VGS aliases into vault_card', () => {
    const outcome = Flow.outcomeOfReply(
      reply({
        status: 'success',
        vaultType: 'vgs',
        data: {
          tokens: {
            json: {
              card_number: 'alias_pan',
              card_cvc: 'alias_cvc',
              expiration_date: '12 / 30',
            },
          },
        },
      })
    );
    expect(outcome.TAG).toBe('Tokenized');
    expect(outcome._0.fragment).toEqual({
      payment_method_data: {
        vault_card: {
          card_number: 'alias_pan',
          card_cvc: 'alias_cvc',
          card_exp_month: '12',
          card_exp_year: '2030',
        },
      },
    });
  });

  it('confirms a saved card with its own token and the tokenized CVC', () => {
    const outcome = Flow.outcomeOfReply(
      reply({
        status: 'success',
        vaultType: 'hyperswitch',
        data: {
          tokens: { payment_method_token: 'cvc_tok' },
          savedCard: { paymentMethodToken: 'pm_saved' },
        },
      })
    );
    expect(outcome).toEqual({
      TAG: 'Tokenized',
      _0: {
        fragment: { payment_method_data: { card_token: { card_cvc_token: 'cvc_tok' } } },
        savedCardToken: 'pm_saved',
      },
    });
  });

  it('confirms with the saved card the confirm names when the vault only tokenized the CVC', () => {
    const outcome = Flow.outcomeOfReply(
      reply({
        status: 'success',
        vaultType: 'hyperswitch',
        data: { tokens: { payment_method_token: 'cvc_tok' }, savedCard: {} },
      }),
      'token_saved'
    );
    expect(outcome).toEqual({
      TAG: 'Tokenized',
      _0: {
        fragment: { payment_method_data: { card_token: { card_cvc_token: 'cvc_tok' } } },
        savedCardToken: 'token_saved',
      },
    });
  });

  it('asks for input when the fields are incomplete or invalid', () => {
    for (const code of ['validation_error', 'incomplete_field_set']) {
      expect(Flow.outcomeOfReply(reply(errorResult('hyperswitch', code, 'fix it')))).toBe(
        'NeedsInput'
      );
    }
  });

  it('passes the vault error code through', () => {
    const outcome = Flow.outcomeOfReply(
      reply(errorResult('hyperswitch', 'session_expired', 'The session expired.'))
    );
    expect(outcome).toEqual({
      TAG: 'Failed',
      _0: { code: 'session_expired', message: 'The session expired.' },
    });
  });

  it('reports a malformed success as tokenization_failed', () => {
    const outcome = Flow.outcomeOfReply(
      reply({ status: 'success', vaultType: 'hyperswitch', data: { tokens: {} } })
    );
    expect(outcome.TAG).toBe('Failed');
    expect(outcome._0.code).toBe('tokenization_failed');
  });

  it('reports a command the form could not run, or an unreadable reply, as sdk_not_ready', () => {
    expect(Flow.outcomeOfReply(reply(undefined, false, 'No form "form_1" is open.'))).toEqual({
      TAG: 'Failed',
      _0: { code: 'sdk_not_ready', message: 'No form "form_1" is open.' },
    });
    expect(Flow.outcomeOfReply('not json')._0.code).toBe('sdk_not_ready');
    expect(Flow.outcomeOfReply(reply(undefined, true))._0.code).toBe('tokenization_failed');
  });
});

describe('refusalOf', () => {
  it('lets a pending or vaulted form through', () => {
    expect(Flow.refusalOf('Pending')).toBeUndefined();
    expect(Flow.refusalOf({ TAG: 'VaultCard', _0: hyperswitchVault })).toBeUndefined();
  });

  it('refuses a skip profile and a missing or unreadable vault as unsupported_configuration', () => {
    for (const strategy of [
      'DirectCard',
      { TAG: 'Refused', _0: 'VaultUnavailable' },
      { TAG: 'Refused', _0: 'UnreadableVaultingAction' },
    ]) {
      expect(Flow.refusalOf(strategy).code).toBe('unsupported_configuration');
    }
  });
});

describe('results', () => {
  it('reports a confirm in the widgets result payload', () => {
    expect(Flow.succeeded('processing')).toEqual({ status: 'processing' });
    expect(Flow.failed(Flow.validationError)).toEqual({
      status: 'failed',
      code: 'validation_error',
      message: Flow.validationError.message,
    });
    expect(Flow.errorJson(Flow.notReady)).toEqual({
      code: 'sdk_not_ready',
      message: Flow.notReady.message,
    });
  });

  it('gives a payment failure a code and a message even when the API sent neither', () => {
    expect(Flow.paymentErrorOf({ status: 'failed' })).toEqual({
      code: 'payment_failed',
      message: expect.any(String),
    });
    expect(Flow.paymentErrorOf({ code: 'IR_19', message: 'Declined' })).toEqual({
      code: 'IR_19',
      message: 'Declined',
    });
  });
});
