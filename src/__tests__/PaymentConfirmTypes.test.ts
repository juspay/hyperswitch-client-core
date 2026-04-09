import {
  defaultNextAction,
  defaultConfirmError,
  defaultCancelError,
  defaultSuccess,
  getACH_bank_transfer,
  getACH_details,
  getNextAction,
  itemToObjMapper,
  itemToObjMapperJava,
} from '../types/AllApiDataTypes/PaymentConfirmTypes.bs.js';

jest.mock('../utility/logics/Utils.bs.js', () => ({
  getString: jest.fn((dict, key, defaultVal) => dict?.[key] ?? defaultVal),
  getOptionFloat: jest.fn((dict, key) => dict?.[key]),
  getBool: jest.fn((dict, key, defaultVal) => dict?.[key] ?? defaultVal),
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

describe('PaymentConfirmTypes', () => {
  describe('defaultNextAction', () => {
    it('has expected structure', () => {
      expect(defaultNextAction).toEqual({
        redirectToUrl: '',
        type_: '',
      });
    });
  });

  describe('defaultConfirmError', () => {
    it('has expected structure', () => {
      expect(defaultConfirmError).toHaveProperty('message');
      expect(defaultConfirmError).toHaveProperty('code');
      expect(defaultConfirmError).toHaveProperty('type_');
      expect(defaultConfirmError).toHaveProperty('status');
      expect(defaultConfirmError.status).toBe('failed');
    });
  });

  describe('defaultCancelError', () => {
    it('has expected structure', () => {
      expect(defaultCancelError.status).toBe('cancelled');
    });
  });

  describe('defaultSuccess', () => {
    it('has expected structure', () => {
      expect(defaultSuccess.status).toBe('Processing');
    });
  });

  describe('getACH_bank_transfer', () => {
    it('returns ach_credit_transfer when data is provided', () => {
      const data = {
        ach_credit_transfer: {
          account_number: '123456789',
          bank_name: 'Test Bank',
          routing_number: '987654321',
          swift_code: 'TESTUS33',
        },
      };

      const result = getACH_bank_transfer(data);

      expect(result.account_number).toBe('123456789');
      expect(result.bank_name).toBe('Test Bank');
    });

    it('returns default object when data is undefined', () => {
      const result = getACH_bank_transfer(undefined);

      expect(result).toEqual({
        account_number: '',
        bank_name: '',
        routing_number: '',
        swift_code: '',
      });
    });

    it('handles missing ach_credit_transfer property', () => {
      const data = {};

      const result = getACH_bank_transfer(data);

      expect(result).toBeUndefined();
    });
  });

  describe('getACH_details', () => {
    it('returns data when provided', () => {
      const data = {
        account_number: '111222333',
        bank_name: 'Bank A',
        routing_number: '444555666',
        swift_code: 'BANKAUS',
      };

      const result = getACH_details(data);

      expect(result.account_number).toBe('111222333');
    });

    it('returns default object when data is undefined', () => {
      const result = getACH_details(undefined);

      expect(result).toEqual({
        account_number: '',
        bank_name: '',
        routing_number: '',
        swift_code: '',
      });
    });
  });

  describe('itemToObjMapper', () => {
    it('maps dict to object with expected properties', () => {
      const dict = {
        status: 'succeeded',
        error: null,
      };

      const result = itemToObjMapper(dict);

      expect(result).toHaveProperty('nextAction');
      expect(result).toHaveProperty('status');
      expect(result).toHaveProperty('error');
    });

    it('extracts status from dict', () => {
      const dict = {
        status: 'failed',
        error: { message: 'Test error' },
      };

      const result = itemToObjMapper(dict);

      expect(result.status).toBe('failed');
    });

    it('handles empty dict', () => {
      const dict = {};

      const result = itemToObjMapper(dict);

      expect(result).toBeDefined();
    });

    it('handles null dict', () => {
      const dict = { error: null };

      const result = itemToObjMapper(dict);

      expect(result).toBeDefined();
    });
  });

  describe('itemToObjMapperJava', () => {
    it('maps dict to object with expected properties', () => {
      const dict = {
        paymentMethodData: '{"token": "abc"}',
        clientSecret: 'cs_test_123',
        paymentMethodType: 'card',
        publishableKey: 'pk_test_123',
        error: '',
        confirm: true,
      };

      const result = itemToObjMapperJava(dict);

      expect(result.paymentMethodData).toBe('{"token": "abc"}');
      expect(result.clientSecret).toBe('cs_test_123');
      expect(result.paymentMethodType).toBe('card');
      expect(result.publishableKey).toBe('pk_test_123');
    });

    it('handles missing fields with defaults', () => {
      const dict = {};

      const result = itemToObjMapperJava(dict);

      expect(result.paymentMethodData).toBe('');
      expect(result.clientSecret).toBe('');
      expect(result.error).toBe('');
      expect(result.confirm).toBe(false);
    });

    it('extracts error field', () => {
      const dict = {
        error: 'Payment failed',
      };

      const result = itemToObjMapperJava(dict);

      expect(result.error).toBe('Payment failed');
    });

    it('handles confirm boolean', () => {
      const dict = { confirm: true };
      const result = itemToObjMapperJava(dict);
      expect(result.confirm).toBe(true);
    });
  });

  describe('getNextAction', () => {
    it('returns defaultNextAction when dict key does not exist', () => {
      const dict = {};
      const result = getNextAction(dict, 'next_action');
      expect(result).toEqual(defaultNextAction);
    });

    it('returns defaultNextAction when dict key is null', () => {
      const dict = { next_action: null };
      const result = getNextAction(dict, 'next_action');
      expect(result).toEqual(defaultNextAction);
    });

    it('parses next_action with basic fields', () => {
      const dict = {
        next_action: {
          redirect_to_url: 'https://example.com',
          type: 'redirect',
        },
      };
      const result = getNextAction(dict, 'next_action');
      expect(result.redirectToUrl).toBe('https://example.com');
      expect(result.type_).toBe('redirect');
    });

    it('parses next_action with three_ds_data', () => {
      const dict = {
        next_action: {
          redirect_to_url: 'https://example.com',
          type: 'three_ds',
          three_ds_data: {
            three_ds_authentication_url: 'https://auth.example.com',
            three_ds_authorize_url: 'https://authorize.example.com',
            message_version: '2.1.0',
            directory_server_id: 'ds123',
            poll_config: {
              poll_id: 'poll123',
              delay_in_secs: 5,
              frequency: 10,
            },
          },
        },
      };
      const result = getNextAction(dict, 'next_action');
      expect(result.threeDsData.threeDsAuthenticationUrl).toBe('https://auth.example.com');
      expect(result.threeDsData.threeDsAuthorizeUrl).toBe('https://authorize.example.com');
      expect(result.threeDsData.messageVersion).toBe('2.1.0');
      expect(result.threeDsData.directoryServerId).toBe('ds123');
      expect(result.threeDsData.pollConfig.pollId).toBe('poll123');
    });

    it('parses next_action with session_token', () => {
      const dict = {
        next_action: {
          session_token: {
            wallet_name: 'test_wallet',
            open_banking_session_token: 'token123',
          },
        },
      };
      const result = getNextAction(dict, 'next_action');
      expect(result.session_token.wallet_name).toBe('test_wallet');
      expect(result.session_token.open_banking_session_token).toBe('token123');
    });

    it('parses next_action with bank_transfer_steps_and_charges_details', () => {
      const dict = {
        next_action: {
          bank_transfer_steps_and_charges_details: {
            ach_credit_transfer: {
              account_number: '123456789',
              bank_name: 'Test Bank',
              routing_number: '987654321',
              swift_code: 'TESTUS',
            },
          },
        },
      };
      const result = getNextAction(dict, 'next_action');
      expect(result.bank_transfer_steps_and_charges_detail.ach_credit_transfer.account_number).toBe('123456789');
      expect(result.bank_transfer_steps_and_charges_detail.ach_credit_transfer.bank_name).toBe('Test Bank');
    });

    it('handles empty nested objects', () => {
      const dict = {
        next_action: {
          three_ds_data: null,
          session_token: null,
          bank_transfer_steps_and_charges_details: null,
        },
      };
      const result = getNextAction(dict, 'next_action');
      expect(result.threeDsData).toBeDefined();
      expect(result.session_token).toBeDefined();
      expect(result.bank_transfer_steps_and_charges_detail).toBeDefined();
    });

    it('handles partial three_ds_data without poll_config', () => {
      const dict = {
        next_action: {
          three_ds_data: {
            three_ds_authentication_url: 'https://auth.example.com',
          },
        },
      };
      const result = getNextAction(dict, 'next_action');
      expect(result.threeDsData.threeDsAuthenticationUrl).toBe('https://auth.example.com');
      expect(result.threeDsData.pollConfig.pollId).toBe('');
    });

    it('handles empty poll_config', () => {
      const dict = {
        next_action: {
          three_ds_data: {
            poll_config: null,
          },
        },
      };
      const result = getNextAction(dict, 'next_action');
      expect(result.threeDsData.pollConfig).toBeDefined();
    });
  });
});
