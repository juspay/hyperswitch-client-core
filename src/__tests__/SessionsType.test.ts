import {
  defaultToken,
  getWallet,
  itemToObjMapper,
  jsonToSessionTokenType,
} from '../types/AllApiDataTypes/SessionsType.bs.js';

jest.mock('../utility/logics/Utils.bs.js', () => ({
  getString: jest.fn((dict, key, defaultVal) => dict?.[key] ?? defaultVal),
  getBool: jest.fn((dict, key, defaultVal) => dict?.[key] ?? defaultVal),
  getArray: jest.fn((dict, key) => dict?.[key] ?? []),
  getDictFromJson: jest.fn((json) => (typeof json === 'object' ? json : {})),
  getJsonObjectFromDict: jest.fn((dict, key) => dict?.[key] ?? null),
}));

jest.mock('@rescript/core/src/Core__JSON.bs.js', () => ({
  Decode: {
    array: jest.fn((val) => (Array.isArray(val) ? val : null)),
    object: jest.fn((val) => (val && typeof val === 'object' ? val : null)),
  },
}));

jest.mock('@rescript/core/src/Core__Option.bs.js', () => ({
  getOr: jest.fn((val, defaultVal) => val ?? defaultVal),
  map: jest.fn((val, fn) => (val !== undefined && val !== null ? fn(val) : undefined)),
  flatMap: jest.fn((val, fn) => (val !== undefined && val !== null ? fn(val) : undefined)),
}));

describe('SessionsType', () => {
  describe('defaultToken', () => {
    it('has expected structure', () => {
      expect(defaultToken).toHaveProperty('wallet_name');
      expect(defaultToken).toHaveProperty('session_token');
      expect(defaultToken).toHaveProperty('session_id');
    });

    it('has default wallet_name of NONE', () => {
      expect(defaultToken.wallet_name).toBe('NONE');
    });

    it('has empty string defaults', () => {
      expect(defaultToken.session_token).toBe('');
      expect(defaultToken.session_id).toBe('');
      expect(defaultToken.connector).toBe('');
    });

    it('has boolean defaults set to false', () => {
      expect(defaultToken.shipping_address_required).toBe(false);
      expect(defaultToken.billing_address_required).toBe(false);
      expect(defaultToken.email_required).toBe(false);
    });

    it('has null values for optional fields', () => {
      expect(defaultToken.merchant_info).toBeNull();
      expect(defaultToken.transaction_info).toBeNull();
    });
  });

  describe('getWallet', () => {
    it('returns APPLE_PAY for apple_pay', () => {
      expect(getWallet('apple_pay')).toBe('APPLE_PAY');
    });

    it('returns GOOGLE_PAY for google_pay', () => {
      expect(getWallet('google_pay')).toBe('GOOGLE_PAY');
    });

    it('returns PAYPAL for paypal', () => {
      expect(getWallet('paypal')).toBe('PAYPAL');
    });

    it('returns SAMSUNG_PAY for samsung_pay', () => {
      expect(getWallet('samsung_pay')).toBe('SAMSUNG_PAY');
    });

    it('returns NONE for unknown wallet types', () => {
      expect(getWallet('unknown')).toBe('NONE');
    });

    it('returns NONE for empty string', () => {
      expect(getWallet('')).toBe('NONE');
    });

    it('returns NONE for null', () => {
      expect(getWallet(null)).toBe('NONE');
    });

    it('returns NONE for undefined', () => {
      expect(getWallet(undefined)).toBe('NONE');
    });
  });

  describe('itemToObjMapper', () => {
    it('returns undefined when session_token is missing', () => {
      const dict = {};
      const result = itemToObjMapper(dict);
      expect(result).toBeUndefined();
    });

    it('handles empty session_token array', () => {
      const dict = {
        session_token: [],
      };
      const result = itemToObjMapper(dict);
      expect(result).toBeDefined();
    });

    it('handles dict with session_token', () => {
      const dict = {
        session_token: [
          { wallet_name: 'google_pay', session_token: 'token_123' },
        ],
      };
      const result = itemToObjMapper(dict);
      expect(result).toBeDefined();
    });
  });

  describe('jsonToSessionTokenType', () => {
    it('converts JSON to session token type', () => {
      const sessionTokenData = {
        session_token: [],
      };
      const result = jsonToSessionTokenType(sessionTokenData);
      expect(result).toBeDefined();
    });

    it('handles undefined input', () => {
      const result = jsonToSessionTokenType(undefined);
      expect(result).toBeUndefined();
    });
  });
});
