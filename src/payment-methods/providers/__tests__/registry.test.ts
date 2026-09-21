import { describe, it, expect } from '@jest/globals';
import { registerAdapter, resolveAdapter } from '../registry';
import type { ProviderAdapter } from '../../core/ProviderAdapter';
import type { VaultType } from '../../core/types';

function fakeAdapter(vaultType: VaultType): ProviderAdapter {
  return {
    vaultType,
    validateVaultData: (raw) => raw,
    Host: () => null,
    Field: () => null,
    tokenize: async () => ({ status: 'success', vaultType }),
  };
}

const UNREGISTERED = 'no_such_provider' as VaultType;

describe('adapter registry', () => {
  it('throws a helpful error when no adapter exists for a vault type', () => {
    expect(() => resolveAdapter(UNREGISTERED)).toThrow(/no provider adapter/i);
  });

  it('resolves a registered adapter', () => {
    const adapter = fakeAdapter('vgs');
    const off = registerAdapter(adapter);
    try {
      expect(resolveAdapter('vgs')).toBe(adapter);
    } finally {
      off();
    }
  });

  it('unregister removes the adapter', () => {
    const adapter = fakeAdapter(UNREGISTERED);
    const off = registerAdapter(adapter);
    off();
    expect(() => resolveAdapter(UNREGISTERED)).toThrow(/no provider adapter/i);
  });

  it('stale unregister does not remove a newer registration for the same type', () => {
    const first = fakeAdapter('evervault');
    const second = fakeAdapter('evervault');
    const offFirst = registerAdapter(first);
    const offSecond = registerAdapter(second);
    offFirst();
    try {
      expect(resolveAdapter('evervault')).toBe(second);
    } finally {
      offSecond();
    }
  });
});
