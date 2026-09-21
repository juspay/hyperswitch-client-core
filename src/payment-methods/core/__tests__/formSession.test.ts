import { describe, it, expect, jest } from '@jest/globals';
import { createFormSession } from '../formSession';
import type { ProviderAdapter } from '../ProviderAdapter';
import type { TokenizeResult } from '../types';

const success: TokenizeResult = {
  status: 'success',
  vaultType: 'vgs',
  data: { tokens: { card_number: 'tok_123' } },
};

const errorOf = (result: TokenizeResult) =>
  result.status === 'success' ? undefined : result.error;

function fakeAdapter(
  tokenize: ProviderAdapter['tokenize'] = async () => success
): ProviderAdapter {
  return {
    vaultType: 'vgs',
    validateVaultData: (raw) => raw,
    Host: () => null,
    Field: () => null,
    tokenize,
  };
}

describe('createFormSession', () => {
  it('starts in the initializing state', () => {
    const session = createFormSession(fakeAdapter());
    expect(session.status).toBe('initializing');
  });

  it('becomes ready once a collector attaches', () => {
    const session = createFormSession(fakeAdapter());
    session.attachCollector({});
    expect(session.status).toBe('ready');
  });

  it('delegates tokenize to the adapter once ready, passing providerData', async () => {
    const tokenize = jest.fn(async () => success);
    const collector = { id: 'collector' };
    const session = createFormSession(fakeAdapter(tokenize));
    session.attachCollector(collector);

    const result = await session.tokenize({ extra: 1 });

    expect(result).toEqual(success);
    expect(tokenize).toHaveBeenCalledWith(collector, { extra: 1 });
    expect(session.status).toBe('ready');
  });

  it('awaits a collector that attaches after tokenize is called', async () => {
    const session = createFormSession(fakeAdapter(), { readyTimeoutMs: 1000 });
    const pending = session.tokenize();
    setTimeout(() => session.attachCollector({}), 5);
    await expect(pending).resolves.toEqual(success);
  });

  it('answers sdk_not_ready if no collector attaches before the timeout', async () => {
    const session = createFormSession(fakeAdapter(), { readyTimeoutMs: 10 });
    const result = await session.tokenize();
    expect(result.status).toBe('error');
    expect(result.vaultType).toBe('vgs');
    expect(errorOf(result)?.code).toBe('sdk_not_ready');
    expect(errorOf(result)?.type).toBe('api_error');
  });

  it('answers tokenization_failed when the host has failed', async () => {
    const session = createFormSession(fakeAdapter(), { readyTimeoutMs: 1000 });
    session.fail(new Error('init blew up'));
    const result = await session.tokenize();
    expect(result.status).toBe('error');
    expect(errorOf(result)?.code).toBe('tokenization_failed');
    expect(errorOf(result)?.message).toMatch(/init blew up/);
  });

  it('maps an adapter rejection to tokenization_failed and recovers status', async () => {
    const session = createFormSession(
      fakeAdapter(async () => {
        throw new Error('tokenization failed');
      })
    );
    session.attachCollector({});
    const result = await session.tokenize();
    expect(result.status).toBe('error');
    expect(errorOf(result)?.code).toBe('tokenization_failed');
    expect(errorOf(result)?.message).toMatch(/tokenization failed/);
    expect(session.status).toBe('ready');
  });

  it('reports tokenizing while the adapter call is in flight, and shares that call', async () => {
    let resolveTokenize!: (r: TokenizeResult) => void;
    const tokenize = jest.fn(
      () => new Promise<TokenizeResult>((r) => (resolveTokenize = r))
    );
    const session = createFormSession(fakeAdapter(tokenize));
    session.attachCollector({});
    const first = session.tokenize();
    const second = session.tokenize();
    expect(session.status).toBe('tokenizing');
    expect(second).toBe(first);
    resolveTokenize(success);
    await first;
    expect(tokenize).toHaveBeenCalledTimes(1);
    expect(session.status).toBe('ready');
  });
});
