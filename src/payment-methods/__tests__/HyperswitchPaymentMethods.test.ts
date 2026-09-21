import { describe, it, expect, jest } from '@jest/globals';
import { HyperswitchPaymentMethods } from '../HyperswitchPaymentMethods';
import { registerForm } from '../core/formRegistry';
import type { TokenizeResult } from '../core/types';

const ok: TokenizeResult = { status: 'success', vaultType: 'skyflow' };

describe('HyperswitchPaymentMethods.tokenize', () => {
  it('answers incomplete_field_set when no form is registered for the id', async () => {
    const result = await HyperswitchPaymentMethods.tokenize('absent');
    expect(result.status).toBe('validation_error');
    expect(result.status === 'validation_error' && result.error).toEqual({
      code: 'incomplete_field_set',
      message: expect.stringContaining('<CardForm id="absent">'),
      type: 'validation_error',
    });
  });

  it('routes to the registered form and forwards providerData', async () => {
    const tokenize = jest.fn(async () => ok);
    const off = registerForm('checkout', tokenize);
    try {
      const result = await HyperswitchPaymentMethods.tokenize('checkout', {
        token: 'abc',
      });
      expect(tokenize).toHaveBeenCalledWith({ token: 'abc' });
      expect(result).toEqual(ok);
    } finally {
      off();
    }
  });
});
