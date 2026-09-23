import { describe, it, expect, jest } from '@jest/globals';

jest.mock(
  '@vgs/collect-react-native',
  () => {
    const err = new Error("Cannot find module '@vgs/collect-react-native'");
    (err as { code?: string }).code = 'MODULE_NOT_FOUND';
    throw err;
  },
  { virtual: true }
);

import {
  isAdapterNotLoadedError,
  isProviderUnavailableError,
  loadAdapter,
  resolveAdapter,
} from '../registry';

describe('registry — optional provider SDK not installed', () => {
  it('reports a chunked provider as not loaded until loadAdapter() runs', () => {
    let thrown: unknown;
    try {
      resolveAdapter('vgs');
    } catch (error) {
      thrown = error;
    }
    expect(isAdapterNotLoadedError(thrown)).toBe(true);
    expect((thrown as Error).message).toMatch(/loadAdapter\("vgs"\)/);
  });

  it('rejects with an actionable install message instead of a raw module error', async () => {
    const thrown = await loadAdapter('vgs').then(
      () => undefined,
      (error: unknown) => error as Error
    );
    expect(thrown).toBeDefined();
    expect(thrown?.message).toMatch(/@vgs\/collect-react-native/);
    expect(thrown?.message).toMatch(/not installed/i);
  });

  it('tags the failure so a shopper-facing UI can show a ghost instead of the message', async () => {
    const thrown = await loadAdapter('vgs').then(
      () => undefined,
      (error: unknown) => error
    );
    expect(isProviderUnavailableError(thrown)).toBe(true);
    expect(isProviderUnavailableError(new Error('network down'))).toBe(false);
    expect(isProviderUnavailableError(undefined)).toBe(false);
  });

  it('tries the chunk again on the next call instead of caching the failure', async () => {
    await expect(loadAdapter('vgs')).rejects.toThrow(/not installed/i);
    await expect(loadAdapter('vgs')).rejects.toThrow(/not installed/i);
  });
});
