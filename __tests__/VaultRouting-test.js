import {resolve, route} from '../src/components/vault/VaultActivation.bs.js';

const hyperswitchSession = {
  vaultType: 'hyperswitch',
  session: {vault_details: {vault_type: 'hyperswitch', vault_data: {sdk_authorization: 'abc'}}},
};

const tagOf = value => (typeof value === 'string' ? value : value.TAG);
const routeFor = (action, session) => route(resolve(action, session));

describe('routing truth table', () => {
  it('Tokenize + a usable session confirms with the VAULT source', () => {
    const result = routeFor('Tokenize', hyperswitchSession);
    expect(tagOf(result)).toBe('ConfirmWith');
    expect(result._0.type_).toBe('vault');
    expect(result._0.session).toEqual(hyperswitchSession.session);
  });

  it('Skip confirms with the DIRECT source', () => {
    const result = routeFor('Skip', undefined);
    expect(tagOf(result)).toBe('ConfirmWith');
    expect(result._0.type_).toBe('direct');
  });

  it.each([
    ['no session', undefined],
    ['an unsupported vault type', {vaultType: 'other', session: {}}],
  ])('Tokenize + %s is BLOCKED, not downgraded to a direct confirm', (_label, session) => {
    const result = routeFor('Tokenize', session);
    expect(tagOf(result)).toBe('Blocked');
    expect(result.code).toBe('vault_session_unavailable');
    expect(typeof result.message).toBe('string');
  });
});

describe('the direct source carries nothing that implies tokenization', () => {
  it('has no session', () => {
    const source = routeFor('Skip', hyperswitchSession)._0;
    expect(source.type_).toBe('direct');
    expect('session' in source).toBe(false);
  });

  it('has no confirmTokenMode', () => {
    const source = routeFor('Skip', undefined)._0;
    expect('confirmTokenMode' in source).toBe(false);
  });

  it('carries no vault credential anywhere, even when a session was available', () => {
    const source = routeFor('Skip', hyperswitchSession)._0;
    expect(JSON.stringify(source)).not.toContain('sdk_authorization');
    expect(JSON.stringify(source)).not.toContain('abc');
  });
});

describe('the vault source carries the session and nothing else about it', () => {
  it('passes the session through verbatim', () => {
    const source = routeFor('Tokenize', hyperswitchSession)._0;
    expect(source.session).toEqual(hyperswitchSession.session);
  });

  it('does not pin a confirmTokenMode, leaving the library default in force', () => {
    const source = routeFor('Tokenize', hyperswitchSession)._0;
    expect('confirmTokenMode' in source).toBe(false);
  });
});

describe('the table is total and has no fourth outcome', () => {
  it('every activation routes to exactly one of ConfirmWith or Blocked', () => {
    const tags = [
      routeFor('Skip', undefined),
      routeFor('Skip', hyperswitchSession),
      routeFor('Tokenize', hyperswitchSession),
      routeFor('Tokenize', undefined),
      routeFor('Tokenize', {vaultType: 'other', session: {}}),
    ].map(tagOf);
    expect(new Set(tags)).toEqual(new Set(['ConfirmWith', 'Blocked']));
  });

  it('exactly one activation is blocked, so the gate is not blocking everything', () => {
    const blocked = [
      routeFor('Skip', undefined),
      routeFor('Skip', hyperswitchSession),
      routeFor('Tokenize', hyperswitchSession),
      routeFor('Tokenize', undefined),
    ].filter(r => tagOf(r) === 'Blocked');
    expect(blocked).toHaveLength(1);
  });
});
