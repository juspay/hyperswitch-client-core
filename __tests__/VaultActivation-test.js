import {resolve} from '../src/components/vault/VaultActivation.bs.js';

const DirectCardFlow = 'DirectCardFlow';
import {
  narrowVaultSession,
  isSupportedVault,
} from '../src/types/AllApiDataTypes/SessionsType.bs.js';
import {classify, closesSheet} from '../src/components/vault/VaultResultMapper.bs.js';

const hyperswitchSession = {
  vaultType: 'hyperswitch',
  session: {vault_details: {vault_type: 'hyperswitch', vault_data: {sdk_authorization: 'abc'}}},
};

const activationOf = result => (typeof result === 'string' ? result : result.TAG);

describe('vault activation', () => {
  it('uses the DIRECT library flow when the profile says Skip, with or without a session', () => {
    expect(resolve('Skip', hyperswitchSession)).toBe(DirectCardFlow);
    expect(resolve('Skip', undefined)).toBe(DirectCardFlow);
  });

  it('uses the vault flow when the profile says Tokenize and the session supports it', () => {
    const result = resolve('Tokenize', hyperswitchSession);
    expect(activationOf(result)).toBe('VaultCardFlow');
    expect(result.session).toEqual(hyperswitchSession.session);
  });

  describe('Tokenize with an unusable session NEVER confirms directly instead', () => {
    it.each([
      ['no session at all', undefined],
      ['an unsupported vault type', {vaultType: 'other', session: {}}],
      ['a blank vault type', {vaultType: '', session: {}}],
    ])('%s -> VaultUnavailable, not DirectCardFlow', (_label, session) => {
      const result = resolve('Tokenize', session);
      expect(activationOf(result)).toBe('VaultUnavailable');
      expect(result).not.toBe(DirectCardFlow);
      expect(result.code).toBe('vault_session_unavailable');
      expect(typeof result.message).toBe('string');
      expect(result.message.length).toBeGreaterThan(0);
    });
  });

  it('no longer refuses tokenization when the payment has an eligibility step', () => {
    expect(resolve.length).toBe(2);
    const result = resolve('Tokenize', hyperswitchSession);
    expect(activationOf(result)).toBe('VaultCardFlow');
  });

  it('every outcome is one of the three, and none of them is a host-owned card form', () => {
    const outcomes = [
      resolve('Skip', undefined),
      resolve('Skip', hyperswitchSession),
      resolve('Tokenize', hyperswitchSession),
      resolve('Tokenize', undefined),
    ].map(activationOf);
    expect(new Set(outcomes)).toEqual(
      new Set(['DirectCardFlow', 'VaultCardFlow', 'VaultUnavailable']),
    );
    expect(outcomes).not.toContain('ClassicCardFlow');
  });

  it('never surfaces the vault credential in the blocked message', () => {
    const result = resolve('Tokenize', {vaultType: 'other', session: {}});
    expect(JSON.stringify(result)).not.toContain('sdk_authorization');
  });
});

describe('narrowVaultSession', () => {
  const sessionTokensResponse = {
    payment_id: 'pay_123',
    client_secret: 'pay_123_secret_abc',
    session_token: [{wallet_name: 'apple_pay', session_token: 'wallet-tok'}],
    vault_details: {vault_type: 'Hyperswitch', vault_data: {sdk_authorization: 'base64-envelope'}},
  };

  it('keeps only the vault_details subtree', () => {
    const narrowed = narrowVaultSession(sessionTokensResponse);
    expect(narrowed.session).toEqual({
      vault_details: {vault_type: 'Hyperswitch', vault_data: {sdk_authorization: 'base64-envelope'}},
    });
  });

  it('does not carry the client secret or the wallet tokens to the library', () => {
    const serialized = JSON.stringify(narrowVaultSession(sessionTokensResponse).session);
    expect(serialized).not.toContain('client_secret');
    expect(serialized).not.toContain('pay_123');
    expect(serialized).not.toContain('apple_pay');
    expect(serialized).not.toContain('wallet-tok');
  });

  it('normalises the vault type for comparison but leaves the payload verbatim', () => {
    const narrowed = narrowVaultSession(sessionTokensResponse);
    expect(narrowed.vaultType).toBe('hyperswitch');
    expect(narrowed.session.vault_details.vault_type).toBe('Hyperswitch');
    expect(isSupportedVault(narrowed)).toBe(true);
  });

  it('is absent when the response carries no vault_details', () => {
    expect(narrowVaultSession({payment_id: 'pay_1'})).toBeUndefined();
    expect(narrowVaultSession(null)).toBeUndefined();
    expect(isSupportedVault(undefined)).toBe(false);
  });
});

describe('result mapping', () => {
  const outcomeOf = result => (typeof result === 'string' ? result : result.TAG);

  it('maps succeeded and processing to their navigation outcomes', () => {
    expect(outcomeOf(classify({status: 'succeeded'}))).toBe('Succeeded');
    expect(outcomeOf(classify({status: 'processing'}))).toBe('Processing');
  });

  it('carries a customer action through', () => {
    const result = classify({
      status: 'requires_customer_action',
      nextAction: {type_: 'redirect_to_url', redirectUrl: 'https://3ds.example'},
    });
    expect(outcomeOf(result)).toBe('RequiresCustomerAction');
    expect(result._0.redirectUrl).toBe('https://3ds.example');
  });

  it('fails safe when a customer action arrives with nothing to navigate to', () => {
    expect(outcomeOf(classify({status: 'requires_customer_action'}))).toBe('Failed');
  });

  it('maps every failure branch to Failed and keeps the library message', () => {
    for (const status of ['failed', 'validation_error', 'not_ready']) {
      const result = classify({status, error: {code: 'server_error', message: 'Safe message.'}});
      expect(outcomeOf(result)).toBe('Failed');
      expect(result._0.message).toBe('Safe message.');
      expect(result._0.code).toBe('server_error');
    }
  });

  it('fails safe on a status this build does not recognise', () => {
    const result = classify({status: 'something_new_from_the_backend'});
    expect(outcomeOf(result)).toBe('Failed');
    expect(result._0.code).toBe('vault_unknown_status');
  });

  it('keeps the sheet open only when nothing was sent', () => {
    expect(closesSheet({status: 'validation_error'})).toBe(false);
    expect(closesSheet({status: 'not_ready'})).toBe(false);
    expect(closesSheet({status: 'failed'})).toBe(true);
    expect(closesSheet({status: 'succeeded'})).toBe(true);
  });
});
