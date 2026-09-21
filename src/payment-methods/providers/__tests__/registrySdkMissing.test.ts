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

import { resolveAdapter } from '../registry';

describe('registry — optional provider SDK not installed', () => {
  it('throws an actionable install message instead of a raw module error', () => {
    let thrown: Error | undefined;
    try {
      resolveAdapter('vgs');
    } catch (error) {
      thrown = error as Error;
    }
    expect(thrown).toBeDefined();
    expect(thrown?.message).toMatch(/@vgs\/collect-react-native/);
    expect(thrown?.message).toMatch(/not installed/i);
  });
});
