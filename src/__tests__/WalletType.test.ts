import {
  arrayJsonToCamelCase,
  itemToObject,
  getGpayToken,
  getGpayTokenStringified,
  getAllowedPaymentMethods,
  itemToObjMapper,
  applePayItemToObjMapper,
} from '../types/WalletType.bs.js';

jest.mock('../utility/logics/Utils.bs.js', () => ({
  getString: jest.fn((dict, key, defaultVal) => dict?.[key] ?? defaultVal),
  getBool: jest.fn((dict, key, defaultVal) => dict?.[key] ?? defaultVal),
  getOptionString: jest.fn((dict, key) => dict?.[key]),
  transformKeysSnakeToCamel: jest.fn((obj) => obj),
  getStringFromRecord: jest.fn((obj) => JSON.stringify(obj)),
}));

jest.mock('../utility/logics/AddressUtils.bs.js', () => ({
  getGooglePayBillingAddress: jest.fn(() => ({})),
  getApplePayBillingAddress: jest.fn(() => ({})),
}));

jest.mock('@rescript/core/src/Core__JSON.bs.js', () => ({
  Decode: {
    object: jest.fn((val) => (val && typeof val === 'object' ? val : null)),
  },
}));

jest.mock('@rescript/core/src/Core__Option.bs.js', () => ({
  getOr: jest.fn((val, defaultVal) => val ?? defaultVal),
  map: jest.fn((val, fn) => (val !== undefined && val !== null ? fn(val) : undefined)),
  flatMap: jest.fn((val, fn) => (val !== undefined && val !== null ? fn(val) : undefined)),
}));

describe('WalletType', () => {
  describe('arrayJsonToCamelCase', () => {
    it('transforms array items', () => {
      const arr = [{ test_key: 'value' }, { another_key: 'value2' }];
      const result = arrayJsonToCamelCase(arr);
      expect(result).toHaveLength(2);
    });

    it('returns empty array for empty input', () => {
      const result = arrayJsonToCamelCase([]);
      expect(result).toEqual([]);
    });
  });

  describe('itemToObject', () => {
    it('transforms data to object with expected properties', () => {
      const data = {
        merchant_info: { merchant_id: '123' },
        allowed_payment_methods: [],
        transaction_info: { total_price: '10.00' },
        shipping_address_required: true,
        email_required: false,
      };

      const result = itemToObject(data);

      expect(result.apiVersion).toBe(2);
      expect(result.apiVersionMinor).toBe(0);
    });

    it('handles missing optional fields', () => {
      const data = {
        merchant_info: {},
        allowed_payment_methods: [],
        transaction_info: {},
      };

      const result = itemToObject(data);

      expect(result).toBeDefined();
    });
  });

  describe('getGpayToken', () => {
    it('returns PRODUCTION environment for PROD appEnv', () => {
      const obj = {
        merchant_info: {},
        allowed_payment_methods: [],
        transaction_info: {},
      };

      const result = getGpayToken(obj, 'PROD');

      expect(result.environment).toBe('PRODUCTION');
    });

    it('returns Test environment for non-PROD appEnv', () => {
      const obj = {
        merchant_info: {},
        allowed_payment_methods: [],
        transaction_info: {},
      };

      const result = getGpayToken(obj, 'sandbox');

      expect(result.environment).toBe('Test');
    });

    it('returns Test environment for undefined appEnv', () => {
      const obj = {
        merchant_info: {},
        allowed_payment_methods: [],
        transaction_info: {},
      };

      const result = getGpayToken(obj, undefined);

      expect(result.environment).toBe('Test');
    });
  });

  describe('getGpayTokenStringified', () => {
    it('returns stringified token', () => {
      const obj = {
        merchant_info: {},
        allowed_payment_methods: [],
        transaction_info: {},
      };

      const result = getGpayTokenStringified(obj, 'sandbox');

      expect(typeof result).toBe('string');
    });
  });

  describe('getAllowedPaymentMethods', () => {
    it('returns stringified allowed payment methods', () => {
      const obj = {
        merchant_info: {},
        allowed_payment_methods: [{ type: 'CARD' }],
        transaction_info: {},
      };

      const result = getAllowedPaymentMethods(obj);

      expect(typeof result).toBe('string');
    });
  });

  describe('itemToObjMapper', () => {
    it('maps dict to object with payment method data', () => {
      const dict = {};

      const result = itemToObjMapper(dict);

      expect(result).toHaveProperty('paymentMethodData');
      expect(result).toHaveProperty('email');
      expect(result).toHaveProperty('shippingDetails');
    });
  });

  describe('applePayItemToObjMapper', () => {
    it('maps dict to Apple Pay object', () => {
      const dict = {
        payment_data: 'payment_data_value',
        payment_method: 'payment_method_value',
        transaction_identifier: 'identifier_123',
      };

      const result = applePayItemToObjMapper(dict);

      expect(result.paymentData).toBe('payment_data_value');
      expect(result.paymentMethod).toBe('payment_method_value');
      expect(result.transactionIdentifier).toBe('identifier_123');
    });

    it('handles missing fields', () => {
      const dict = {};

      const result = applePayItemToObjMapper(dict);

      expect(result.paymentData).toBeNull();
      expect(result.paymentMethod).toBeNull();
      expect(result.transactionIdentifier).toBeNull();
    });

    it('extracts email', () => {
      const dict = {
        email: 'test@example.com',
      };

      const result = applePayItemToObjMapper(dict);

      expect(result).toHaveProperty('email');
    });
  });
});
