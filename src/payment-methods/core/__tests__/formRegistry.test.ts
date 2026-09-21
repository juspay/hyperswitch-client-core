import { describe, it, expect } from '@jest/globals';
import { registerForm, getFormTokenize } from '../formRegistry';
import type { TokenizeResult } from '../types';

const ok: TokenizeResult = { status: 'success', vaultType: 'vgs' };

describe('formRegistry', () => {
  it('returns undefined for an unregistered id', () => {
    expect(getFormTokenize('nope')).toBeUndefined();
  });

  it('routes to the registered tokenize function', async () => {
    let called = false;
    const off = registerForm('checkout', async () => {
      called = true;
      return ok;
    });
    try {
      const fn = getFormTokenize('checkout');
      expect(fn).toBeDefined();
      await fn!();
      expect(called).toBe(true);
    } finally {
      off();
    }
  });

  it('unregister removes the registration', () => {
    const off = registerForm('temp', async () => ok);
    off();
    expect(getFormTokenize('temp')).toBeUndefined();
  });

  it('stale unregister does not evict a newer registration for the same id', async () => {
    const offA = registerForm('dup', async () => ({ ...ok, vaultType: 'vgs' }));
    const second = async (): Promise<TokenizeResult> => ({
      ...ok,
      vaultType: 'skyflow',
    });
    const offB = registerForm('dup', second);
    offA();
    try {
      const fn = getFormTokenize('dup');
      expect(fn).toBe(second);
    } finally {
      offB();
    }
  });
});
