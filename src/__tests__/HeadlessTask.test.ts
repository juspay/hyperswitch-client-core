import { getFunctionFromModule, reRegisterCallback, make } from '../headless/HeadlessTask.bs.js';

jest.mock('react-native', () => {
  const mockGetPaymentSession = jest.fn();
  const mockExitHeadless = jest.fn();
  return {
    NativeModules: {
      HyperHeadless: {
        getPaymentSession: mockGetPaymentSession,
        exitHeadless: mockExitHeadless,
      },
    },
    Platform: { OS: 'ios' },
  };
});

jest.mock('@rescript/core/src/Core__JSON.bs.js', () => ({
  Decode: {
    object: jest.fn((val) => val),
    string: jest.fn((val) => val),
  },
}));

jest.mock('@rescript/core/src/Core__Option.bs.js', () => ({
  getOr: jest.fn((val, defaultVal) => val !== undefined && val !== null ? val : defaultVal),
  flatMap: jest.fn((val, fn) => val !== undefined && val !== null ? fn(val) : undefined),
  map: jest.fn((val, fn) => val !== undefined && val !== null ? fn(val) : undefined),
}));

jest.mock('@rescript/core/src/Core__Array.bs.js', () => ({
  reduce: jest.fn((arr, init, fn) => arr.reduce(fn, init)),
}));

jest.mock('rescript/lib/es6/caml.js', () => ({
  float_compare: jest.fn((a, b) => a - b),
}));

jest.mock('rescript/lib/es6/caml_option.js', () => ({
  valFromOption: jest.fn((val) => val),
}));

jest.mock('../utility/logics/Utils.bs.js', () => ({
  getJsonObjectFromRecord: jest.fn((obj) => obj),
  getDictFromJson: jest.fn((json) => {
    if (typeof json === 'string') {
      try {
        return JSON.parse(json);
      } catch {
        return {};
      }
    }
    return json || {};
  }),
  getOptionString: jest.fn((dict, key) => dict?.[key]),
  getStringFromJson: jest.fn((val, defaultVal) => {
    if (typeof val === 'string') return val;
    return defaultVal;
  }),
}));

jest.mock('../types/SdkTypes.bs.js', () => ({
  nativeJsonToRecord: jest.fn((props, _num) => ({
    publishableKey: props?.publishableKey || 'pk_test_123',
    clientSecret: props?.clientSecret || 'pi_123_secret_456',
    env: props?.env || 'sandbox',
    customBackendUrl: props?.customBackendUrl,
    customLogUrl: props?.customLogUrl,
    hyperParams: props?.hyperParams || { sdkVersion: '1.0.0', appId: 'test-app' },
  })),
}));

jest.mock('../utility/constants/GlobalVars.bs.js', () => ({
  isValidPK: jest.fn((env, pk) => {
    if (pk && pk.startsWith('pk_')) return true;
    return false;
  }),
}));

jest.mock('../utility/reusableCodeFromWeb/ErrorUtils.bs.js', () => ({
  isError: jest.fn((data) => data && data.error === true),
  getErrorCode: jest.fn((data) => data?.code || null),
  errorWarning: {
    usedCL: { TAG: 'USED_CL', _0: ['Warning', { TAG: 'Static', _0: 'Client secret already used' }] },
    invalidCL: { TAG: 'INVALID_CL', _0: ['Error', { TAG: 'Static', _0: 'Invalid client secret' }] },
    noData: { TAG: 'NO_DATA', _0: ['Error', { TAG: 'Static', _0: 'No data available' }] },
  },
}));

jest.mock('../headless/HeadlessUtils.bs.js', () => ({
  savedPaymentMethodAPICall: jest.fn(() => Promise.resolve(undefined)),
  sessionAPICall: jest.fn(() => Promise.resolve(null)),
  confirmAPICall: jest.fn(() => Promise.resolve({})),
  getDefaultError: { message: 'default error', code: 'no_data', type_: 'no_data', status: 'failed' },
  getErrorFromResponse: jest.fn((data) => ({ message: 'error from response', code: 'err', type_: 'api', status: 'failed' })),
  errorOnApiCalls: jest.fn((key, str) => ({
    message: str || key?._0?.[1]?._0 || 'error',
    code: 'no_data',
    type_: 'no_data',
    status: 'failed',
  })),
  generateWalletConfirmBody: jest.fn(() => JSON.stringify({ client_secret: 'test' })),
  logWrapper: jest.fn(),
}));

jest.mock('../components/modules/HyperModule.bs.js', () => ({
  stringifiedResStatus: jest.fn((status) => JSON.stringify(status)),
  launchGPay: jest.fn(),
  launchApplePay: jest.fn(),
}));

jest.mock('../types/WalletType.bs.js', () => ({
  itemToObjMapper: jest.fn((dict) => ({
    paymentMethodData: { info: { billing_address: {} } },
  })),
  getGpayTokenStringified: jest.fn(() => JSON.stringify({ session_token_data: 'token' })),
}));

jest.mock('../types/AllApiDataTypes/SessionsType.bs.js', () => ({
  defaultToken: { session_token_data: '', payment_request_data: '' },
  itemToObjMapper: jest.fn((dict) => [{ wallet_name: 'google_pay', session_token_data: 'token', payment_request_data: 'data' }]),
}));

jest.mock('../types/AllApiDataTypes/PaymentConfirmTypes.bs.js', () => ({
  itemToObjMapper: jest.fn(() => ({ error: '' })),
  itemToObjMapperJava: jest.fn(() => ({ error: '', paymentMethodData: '{}' })),
}));

jest.mock('../types/AllApiDataTypes/CustomerPaymentMethodType.bs.js', () => ({
  jsonToCustomerPaymentMethodType: jest.fn(() => ({
    customer_payment_methods: [
      { payment_method: 'CARD', payment_token: 'tok_123', default_payment_method_set: true, last_used_at: '2024-01-01T00:00:00Z' },
    ],
  })),
}));

jest.mock('../utility/logics/AddressUtils.bs.js', () => ({
  getApplePayBillingAddress: jest.fn(() => ({ country: 'US' })),
}));

function getNativeModuleMocks() {
  const ReactNative = require('react-native');
  return {
    getPaymentSession: ReactNative.NativeModules.HyperHeadless.getPaymentSession,
    exitHeadless: ReactNative.NativeModules.HyperHeadless.exitHeadless,
  };
}

describe('HeadlessTask', () => {
  let mockGetPaymentSession: jest.Mock;
  let mockExitHeadless: jest.Mock;

  beforeEach(() => {
    jest.clearAllMocks();
    const mocks = getNativeModuleMocks();
    mockGetPaymentSession = mocks.getPaymentSession;
    mockExitHeadless = mocks.exitHeadless;
    reRegisterCallback.contents = () => {};
  });

  describe('getFunctionFromModule', () => {
    it('returns function from dict when key exists', () => {
      const mockFn = jest.fn();
      const dict = { existingKey: mockFn };
      const defaultFn = jest.fn();

      const result = getFunctionFromModule(dict, 'existingKey', defaultFn);
      expect(result).toBe(mockFn);
    });

    it('returns default function when key does not exist', () => {
      const dict = { otherKey: jest.fn() };
      const defaultFn = jest.fn();

      const result = getFunctionFromModule(dict, 'missingKey', defaultFn);
      expect(result).toBe(defaultFn);
    });

    it('returns default function when dict is empty', () => {
      const dict = {};
      const defaultFn = jest.fn();

      const result = getFunctionFromModule(dict, 'anyKey', defaultFn);
      expect(result).toBe(defaultFn);
    });

    it('handles undefined value in dict', () => {
      const dict = { undefinedKey: undefined };
      const defaultFn = jest.fn();

      const result = getFunctionFromModule(dict, 'undefinedKey', defaultFn);
      expect(result).toBe(defaultFn);
    });

    it('handles null value in dict by returning it (not default)', () => {
      const dict = { nullKey: null };
      const defaultFn = jest.fn();

      const result = getFunctionFromModule(dict, 'nullKey', defaultFn);
      expect(result).toBe(null);
    });
  });

  describe('reRegisterCallback', () => {
    it('is an object with contents property', () => {
      expect(reRegisterCallback).toBeDefined();
      expect(reRegisterCallback).toHaveProperty('contents');
    });

    it('contents is a function by default', () => {
      expect(typeof reRegisterCallback.contents).toBe('function');
    });

    it('contents can be reassigned to a new function', () => {
      const newFn = jest.fn();
      reRegisterCallback.contents = newFn;
      expect(reRegisterCallback.contents).toBe(newFn);
    });

    it('calling default contents does not throw', () => {
      expect(() => reRegisterCallback.contents()).not.toThrow();
    });

    it('calling reassigned contents executes the new function', () => {
      const newFn = jest.fn();
      reRegisterCallback.contents = newFn;
      reRegisterCallback.contents();
      expect(newFn).toHaveBeenCalledTimes(1);
    });
  });

  describe('make (HeadlessTask)', () => {
    it('is defined and is a function', () => {
      expect(make).toBeDefined();
      expect(typeof make).toBe('function');
    });

    it('handles invalid publishable key', () => {
      const props = {
        props: {
          publishableKey: 'invalid_key',
          clientSecret: 'pi_123_secret_456',
        },
      };

      make(props);

      expect(mockGetPaymentSession).toHaveBeenCalled();
    });

    it('handles invalid client secret format', () => {
      const props = {
        props: {
          publishableKey: 'pk_test_123',
          clientSecret: 'invalid_secret',
        },
      };

      make(props);

      expect(mockGetPaymentSession).toHaveBeenCalled();
    });

    it('handles valid credentials and triggers apiHandler', async () => {
      const mockSavedPaymentMethodAPICall = require('../headless/HeadlessUtils.bs.js').savedPaymentMethodAPICall;
      mockSavedPaymentMethodAPICall.mockResolvedValueOnce({
        customer_payment_methods: [],
      });

      const props = {
        props: {
          publishableKey: 'pk_test_123',
          clientSecret: 'pi_123_secret_456',
          env: 'sandbox',
        },
      };

      make(props);

      await new Promise(resolve => setTimeout(resolve, 10));

      expect(mockSavedPaymentMethodAPICall).toHaveBeenCalled();
    });

    it('handles empty props object', () => {
      const props = { props: {} };

      expect(() => make(props)).not.toThrow();
    });

    it('handles null props', () => {
      const props = { props: null };

      expect(() => make(props)).not.toThrow();
    });

    it('handles undefined props', () => {
      const props = { props: undefined };

      expect(() => make(props)).not.toThrow();
    });

    it('calls getPaymentSession when customerSavedPMData is undefined', async () => {
      const mockSavedPaymentMethodAPICall = require('../headless/HeadlessUtils.bs.js').savedPaymentMethodAPICall;

      mockSavedPaymentMethodAPICall.mockResolvedValueOnce(undefined);

      const props = {
        props: {
          publishableKey: 'pk_test_123',
          clientSecret: 'pi_123_secret_456',
        },
      };

      make(props);

      await new Promise(resolve => setTimeout(resolve, 10));

      expect(mockSavedPaymentMethodAPICall).toHaveBeenCalled();
    });

    it('handles session API error with IR_16 error code', async () => {
      const mockSavedPaymentMethodAPICall = require('../headless/HeadlessUtils.bs.js').savedPaymentMethodAPICall;
      const mockSessionAPICall = require('../headless/HeadlessUtils.bs.js').sessionAPICall;
      const mockIsError = require('../utility/reusableCodeFromWeb/ErrorUtils.bs.js').isError;
      const mockGetErrorCode = require('../utility/reusableCodeFromWeb/ErrorUtils.bs.js').getErrorCode;

      mockSavedPaymentMethodAPICall.mockResolvedValueOnce({ customer_payment_methods: [] });
      mockSessionAPICall.mockResolvedValueOnce({ error: true, code: '"IR_16"' });
      mockIsError.mockReturnValueOnce(true);
      mockGetErrorCode.mockReturnValueOnce('"IR_16"');

      const props = {
        props: {
          publishableKey: 'pk_test_123',
          clientSecret: 'pi_123_secret_456',
        },
      };

      make(props);

      await new Promise(resolve => setTimeout(resolve, 10));

      expect(mockSavedPaymentMethodAPICall).toHaveBeenCalled();
    });

    it('handles session API error with IR_09 error code', async () => {
      const mockSavedPaymentMethodAPICall = require('../headless/HeadlessUtils.bs.js').savedPaymentMethodAPICall;
      const mockSessionAPICall = require('../headless/HeadlessUtils.bs.js').sessionAPICall;
      const mockIsError = require('../utility/reusableCodeFromWeb/ErrorUtils.bs.js').isError;
      const mockGetErrorCode = require('../utility/reusableCodeFromWeb/ErrorUtils.bs.js').getErrorCode;

      mockSavedPaymentMethodAPICall.mockResolvedValueOnce({ customer_payment_methods: [] });
      mockSessionAPICall.mockResolvedValueOnce({ error: true, code: '"IR_09"' });
      mockIsError.mockReturnValueOnce(true);
      mockGetErrorCode.mockReturnValueOnce('"IR_09"');

      const props = {
        props: {
          publishableKey: 'pk_test_123',
          clientSecret: 'pi_123_secret_456',
        },
      };

      make(props);

      await new Promise(resolve => setTimeout(resolve, 10));

      expect(mockSavedPaymentMethodAPICall).toHaveBeenCalled();
    });

    it('handles session API returning null', async () => {
      const mockSavedPaymentMethodAPICall = require('../headless/HeadlessUtils.bs.js').savedPaymentMethodAPICall;
      const mockSessionAPICall = require('../headless/HeadlessUtils.bs.js').sessionAPICall;
      const mockIsError = require('../utility/reusableCodeFromWeb/ErrorUtils.bs.js').isError;

      mockSavedPaymentMethodAPICall.mockResolvedValueOnce({ customer_payment_methods: [] });
      mockSessionAPICall.mockResolvedValueOnce(null);
      mockIsError.mockReturnValueOnce(false);

      const props = {
        props: {
          publishableKey: 'pk_test_123',
          clientSecret: 'pi_123_secret_456',
        },
      };

      make(props);

      await new Promise(resolve => setTimeout(resolve, 10));

      expect(mockSavedPaymentMethodAPICall).toHaveBeenCalled();
    });

    it('handles custom environment', async () => {
      const mockSavedPaymentMethodAPICall = require('../headless/HeadlessUtils.bs.js').savedPaymentMethodAPICall;
      mockSavedPaymentMethodAPICall.mockResolvedValueOnce(undefined);

      const props = {
        props: {
          publishableKey: 'pk_test_123',
          clientSecret: 'pi_123_secret_456',
          env: 'PROD',
        },
      };

      make(props);

      await new Promise(resolve => setTimeout(resolve, 10));

      expect(mockSavedPaymentMethodAPICall).toHaveBeenCalled();
    });

    it('handles custom backend URL', async () => {
      const mockSavedPaymentMethodAPICall = require('../headless/HeadlessUtils.bs.js').savedPaymentMethodAPICall;
      mockSavedPaymentMethodAPICall.mockResolvedValueOnce(undefined);

      const props = {
        props: {
          publishableKey: 'pk_test_123',
          clientSecret: 'pi_123_secret_456',
          customBackendUrl: 'https://custom.api.com',
        },
      };

      make(props);

      await new Promise(resolve => setTimeout(resolve, 10));

      expect(mockSavedPaymentMethodAPICall).toHaveBeenCalled();
    });

    it('handles customer payment methods with wallet type on Android', async () => {
      const ReactNative = require('react-native');
      ReactNative.Platform.OS = 'android';

      const mockSavedPaymentMethodAPICall = require('../headless/HeadlessUtils.bs.js').savedPaymentMethodAPICall;
      const mockJsonToCustomerPaymentMethodType = require('../types/AllApiDataTypes/CustomerPaymentMethodType.bs.js').jsonToCustomerPaymentMethodType;

      mockSavedPaymentMethodAPICall.mockResolvedValueOnce({ customer_payment_methods: [] });
      mockJsonToCustomerPaymentMethodType.mockReturnValueOnce({
        customer_payment_methods: [
          { payment_method: 'WALLET', payment_method_type_wallet: 'GOOGLE_PAY', payment_token: 'tok_gpay' },
        ],
      });

      const props = {
        props: {
          publishableKey: 'pk_test_123',
          clientSecret: 'pi_123_secret_456',
        },
      };

      make(props);

      await new Promise(resolve => setTimeout(resolve, 10));

      expect(mockSavedPaymentMethodAPICall).toHaveBeenCalled();
    });

    it('handles customer payment methods with wallet type on iOS', async () => {
      const ReactNative = require('react-native');
      ReactNative.Platform.OS = 'ios';

      const mockSavedPaymentMethodAPICall = require('../headless/HeadlessUtils.bs.js').savedPaymentMethodAPICall;
      const mockJsonToCustomerPaymentMethodType = require('../types/AllApiDataTypes/CustomerPaymentMethodType.bs.js').jsonToCustomerPaymentMethodType;

      mockSavedPaymentMethodAPICall.mockResolvedValueOnce({ customer_payment_methods: [] });
      mockJsonToCustomerPaymentMethodType.mockReturnValueOnce({
        customer_payment_methods: [
          { payment_method: 'WALLET', payment_method_type_wallet: 'APPLE_PAY', payment_token: 'tok_apple' },
        ],
      });

      const props = {
        props: {
          publishableKey: 'pk_test_123',
          clientSecret: 'pi_123_secret_456',
        },
      };

      make(props);

      await new Promise(resolve => setTimeout(resolve, 10));

      expect(mockSavedPaymentMethodAPICall).toHaveBeenCalled();
    });

    it('handles customer payment methods with card type', async () => {
      const mockSavedPaymentMethodAPICall = require('../headless/HeadlessUtils.bs.js').savedPaymentMethodAPICall;
      const mockJsonToCustomerPaymentMethodType = require('../types/AllApiDataTypes/CustomerPaymentMethodType.bs.js').jsonToCustomerPaymentMethodType;

      mockSavedPaymentMethodAPICall.mockResolvedValueOnce({ customer_payment_methods: [] });
      mockJsonToCustomerPaymentMethodType.mockReturnValueOnce({
        customer_payment_methods: [
          { payment_method: 'CARD', payment_token: 'tok_card', default_payment_method_set: true },
        ],
      });

      const props = {
        props: {
          publishableKey: 'pk_test_123',
          clientSecret: 'pi_123_secret_456',
        },
      };

      make(props);

      await new Promise(resolve => setTimeout(resolve, 10));

      expect(mockSavedPaymentMethodAPICall).toHaveBeenCalled();
    });

    it('handles session API returning valid sessions', async () => {
      const mockSavedPaymentMethodAPICall = require('../headless/HeadlessUtils.bs.js').savedPaymentMethodAPICall;
      const mockSessionAPICall = require('../headless/HeadlessUtils.bs.js').sessionAPICall;
      const mockIsError = require('../utility/reusableCodeFromWeb/ErrorUtils.bs.js').isError;
      const mockItemToObjMapper = require('../types/AllApiDataTypes/SessionsType.bs.js').itemToObjMapper;

      mockSavedPaymentMethodAPICall.mockResolvedValueOnce({ customer_payment_methods: [] });
      mockSessionAPICall.mockResolvedValueOnce({ sessions: [] });
      mockIsError.mockReturnValueOnce(false);
      mockItemToObjMapper.mockReturnValueOnce([
        { wallet_name: 'google_pay', session_token_data: 'token', payment_request_data: 'data' },
      ]);

      const props = {
        props: {
          publishableKey: 'pk_test_123',
          clientSecret: 'pi_123_secret_456',
        },
      };

      make(props);

      await new Promise(resolve => setTimeout(resolve, 10));

      expect(mockSavedPaymentMethodAPICall).toHaveBeenCalled();
    });

    it('handles session API returning undefined sessions', async () => {
      const mockSavedPaymentMethodAPICall = require('../headless/HeadlessUtils.bs.js').savedPaymentMethodAPICall;
      const mockSessionAPICall = require('../headless/HeadlessUtils.bs.js').sessionAPICall;
      const mockIsError = require('../utility/reusableCodeFromWeb/ErrorUtils.bs.js').isError;
      const mockItemToObjMapper = require('../types/AllApiDataTypes/SessionsType.bs.js').itemToObjMapper;

      mockSavedPaymentMethodAPICall.mockResolvedValueOnce({ customer_payment_methods: [] });
      mockSessionAPICall.mockResolvedValueOnce({ sessions: [] });
      mockIsError.mockReturnValueOnce(false);
      mockItemToObjMapper.mockReturnValueOnce(undefined);

      const props = {
        props: {
          publishableKey: 'pk_test_123',
          clientSecret: 'pi_123_secret_456',
        },
      };

      make(props);

      await new Promise(resolve => setTimeout(resolve, 10));

      expect(mockSavedPaymentMethodAPICall).toHaveBeenCalled();
    });
  });
});
