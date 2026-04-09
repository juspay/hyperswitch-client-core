import {
  getBaseUrl,
  errorOnApiCalls,
  getDefaultError,
  getErrorFromResponse,
  generateWalletConfirmBody,
  savedPaymentMethodAPICall,
  sessionAPICall,
  confirmAPICall,
  logWrapper,
} from '../headless/HeadlessUtils.bs.js';
import { errorWarning } from '../utility/reusableCodeFromWeb/ErrorUtils.bs.js';

describe('HeadlessUtils', () => {
  describe('getBaseUrl', () => {
    it('returns customBackendUrl when provided', () => {
      const nativeProp = {
        customBackendUrl: 'https://custom.api.com',
        env: 'SANDBOX',
      };
      expect(getBaseUrl(nativeProp)).toBe('https://custom.api.com');
    });

    it('returns undefined when no custom URL and no env matches', () => {
      const nativeProp = {
        env: 'UNKNOWN',
      };
      expect(getBaseUrl(nativeProp)).toBeUndefined();
    });

    it('returns process.env.HYPERSWITCH_INTEG_URL for INTEG env', () => {
      const nativeProp = {
        env: 'INTEG',
      };
      const result = getBaseUrl(nativeProp);
      expect(result).toBe(process.env.HYPERSWITCH_INTEG_URL);
    });

    it('returns process.env.HYPERSWITCH_SANDBOX_URL for SANDBOX env', () => {
      const nativeProp = {
        env: 'SANDBOX',
      };
      const result = getBaseUrl(nativeProp);
      expect(result).toBe(process.env.HYPERSWITCH_SANDBOX_URL);
    });

    it('returns process.env.HYPERSWITCH_PRODUCTION_URL for PROD env', () => {
      const nativeProp = {
        env: 'PROD',
      };
      const result = getBaseUrl(nativeProp);
      expect(result).toBe(process.env.HYPERSWITCH_PRODUCTION_URL);
    });

    it('prioritizes customBackendUrl over env', () => {
      const nativeProp = {
        customBackendUrl: 'https://override.com',
        env: 'PROD',
      };
      expect(getBaseUrl(nativeProp)).toBe('https://override.com');
    });
  });

  describe('errorOnApiCalls', () => {
    it('returns error object with static message for Error type', () => {
      const inputKey = {
        TAG: 'INVALID_PK',
        _0: [
          'Error',
          { TAG: 'Static', _0: 'Invalid publishable key' },
        ],
      };
      const result = errorOnApiCalls(inputKey, undefined);
      expect(result).toEqual({
        message: 'Invalid publishable key',
        code: 'no_data',
        type_: 'no_data',
        status: 'failed',
      });
    });

    it('returns error object with dynamic message for Dynamic type', () => {
      const inputKey = {
        TAG: 'INVALID_PK',
        _0: [
          'Error',
          { TAG: 'Dynamic', _0: (str: string) => `Error: ${str}` },
        ],
      };
      const result = errorOnApiCalls(inputKey, 'test error');
      expect(result).toEqual({
        message: 'Error: test error',
        code: 'no_data',
        type_: 'no_data',
        status: 'failed',
      });
    });

    it('returns error object with static message for non-Error type', () => {
      const inputKey = {
        TAG: 'SOME_ERROR',
        _0: [
          'Warning',
          { TAG: 'Static', _0: 'Some warning message' },
        ],
      };
      const result = errorOnApiCalls(inputKey, undefined);
      expect(result).toEqual({
        message: 'Some warning message',
        code: 'no_data',
        type_: 'no_data',
        status: 'failed',
      });
    });

    it('returns error object with dynamic message for non-Error type', () => {
      const inputKey = {
        TAG: 'SOME_ERROR',
        _0: [
          'Warning',
          { TAG: 'Dynamic', _0: (str: string) => `Warning: ${str}` },
        ],
      };
      const result = errorOnApiCalls(inputKey, 'dynamic value');
      expect(result).toEqual({
        message: 'Warning: dynamic value',
        code: 'no_data',
        type_: 'no_data',
        status: 'failed',
      });
    });

    it('uses empty string as default dynamicStr', () => {
      const inputKey = {
        TAG: 'TEST',
        _0: [
          'Error',
          { TAG: 'Dynamic', _0: (str: string) => `Message: ${str}` },
        ],
      };
      const result = errorOnApiCalls(inputKey, undefined);
      expect(result.message).toBe('Message: ');
    });
  });

  describe('getDefaultError', () => {
    it('returns default error object', () => {
      const result = getDefaultError;
      expect(result).toHaveProperty('message');
      expect(result).toHaveProperty('code');
      expect(result).toHaveProperty('type_');
      expect(result).toHaveProperty('status');
      expect(result.status).toBe('failed');
    });

    it('has consistent structure', () => {
      const result = getDefaultError;
      expect(typeof result.message).toBe('string');
      expect(typeof result.code).toBe('string');
      expect(typeof result.type_).toBe('string');
      expect(typeof result.status).toBe('string');
    });
  });

  describe('getErrorFromResponse', () => {
    it('extracts error from response with error object', () => {
      const data = {
        error: {
          message: 'Something went wrong',
          code: 'ERR_001',
          type: 'api_error',
        },
        status: 'failed',
      };
      const result = getErrorFromResponse(data);
      expect(result.message).toBe('Something went wrong');
      expect(result.code).toBe('ERR_001');
      expect(result.type_).toBe('api_error');
      expect(result.status).toBe('failed');
    });

    it('returns default error for undefined data', () => {
      const result = getErrorFromResponse(undefined);
      expect(result).toEqual(getDefaultError);
    });

    it('extracts error_message when error object is missing', () => {
      const data = {
        error_message: 'Fallback error message',
        error_code: 'FALLBACK_CODE',
        status: 'failed',
      };
      const result = getErrorFromResponse(data);
      expect(result.message).toBe('Fallback error message');
      expect(result.code).toBe('FALLBACK_CODE');
    });

    it('extracts error string when no error object or error_message', () => {
      const data = {
        error: 'Simple error string',
        status: 'failed',
      };
      const result = getErrorFromResponse(data);
      expect(result.message).toBe('Simple error string');
    });

    it('handles nested error object with fallback to top-level fields', () => {
      const data = {
        error: {
          message: 'Nested error',
        },
        error_code: 'TOP_LEVEL_CODE',
        type: 'top_level_type',
        status: 'error',
      };
      const result = getErrorFromResponse(data);
      expect(result.message).toBe('Nested error');
      expect(result.code).toBe('TOP_LEVEL_CODE');
      expect(result.type_).toBe('top_level_type');
    });

    it('handles empty error object', () => {
      const data = {
        error: {},
        status: 'failed',
      };
      const result = getErrorFromResponse(data);
      expect(result.status).toBe('failed');
    });
  });

  describe('generateWalletConfirmBody', () => {
    it('generates valid JSON string for wallet confirm body', () => {
      const nativeProp = {
        clientSecret: 'cs_test_123_secret_abc',
        hyperParams: {
          sdkVersion: '1.0.0',
          userAgent: 'TestAgent/1.0',
        },
      };
      const data = {
        payment_method_type: 'google_pay',
      };
      const paymentMethodData = {
        wallet: { google_pay: { token: 'test_token' } },
        billing: { country: 'US' },
      };

      const result = generateWalletConfirmBody(
        nativeProp,
        data,
        paymentMethodData,
        undefined
      );
      const parsed = JSON.parse(result);

      expect(parsed.client_secret).toBe('cs_test_123_secret_abc');
      expect(parsed.payment_method).toBe('wallet');
      expect(parsed.payment_method_type).toBe('google_pay');
      expect(parsed.payment_method_data).toEqual(paymentMethodData);
      expect(parsed.setup_future_usage).toBe('off_session');
      expect(parsed.payment_type).toBeNull();
      expect(parsed.customer_acceptance).toBeDefined();
      expect(parsed.customer_acceptance.acceptance_type).toBe('online');
    });

    it('includes payment_type when provided', () => {
      const nativeProp = {
        clientSecret: 'cs_test_123',
        hyperParams: {
          sdkVersion: '1.0.0',
          userAgent: 'TestAgent',
        },
      };
      const data = { payment_method_type: 'apple_pay' };
      const paymentMethodData = { wallet: {} };

      const result = generateWalletConfirmBody(
        nativeProp,
        data,
        paymentMethodData,
        'one_time'
      );
      const parsed = JSON.parse(result);

      expect(parsed.payment_type).toBe('one_time');
    });

    it('includes customer_acceptance with correct structure', () => {
      const nativeProp = {
        clientSecret: 'cs_test',
        hyperParams: {
          sdkVersion: '1.0.0',
          userAgent: 'MyUserAgent',
        },
      };
      const data = { payment_method_type: 'google_pay' };
      const paymentMethodData = {};

      const result = generateWalletConfirmBody(
        nativeProp,
        data,
        paymentMethodData,
        undefined
      );
      const parsed = JSON.parse(result);

      expect(parsed.customer_acceptance.acceptance_type).toBe('online');
      expect(parsed.customer_acceptance.online.user_agent).toBe('MyUserAgent');
      expect(parsed.customer_acceptance.accepted_at).toBeDefined();
    });

    it('handles missing userAgent gracefully', () => {
      const nativeProp = {
        clientSecret: 'cs_test',
        hyperParams: {
          sdkVersion: '1.0.0',
          userAgent: undefined,
        },
      };
      const data = { payment_method_type: 'paypal' };
      const paymentMethodData = {};

      const result = generateWalletConfirmBody(
        nativeProp,
        data,
        paymentMethodData,
        undefined
      );
      const parsed = JSON.parse(result);

      expect(parsed.customer_acceptance.online.user_agent).toBe('');
    });
  });

  describe('savedPaymentMethodAPICall', () => {
    it('returns a promise', () => {
      const nativeProp = {
        publishableKey: 'pk_test_123',
        clientSecret: 'pi_123_secret_456',
        env: 'sandbox',
        hyperParams: { appId: 'test-app', sdkVersion: '1.0.0' },
      };

      const result = savedPaymentMethodAPICall(nativeProp);
      expect(result).toBeInstanceOf(Promise);
    });

    it('constructs correct URL with client secret', async () => {
      const nativeProp = {
        publishableKey: 'pk_test_123',
        clientSecret: 'pi_123_secret_456',
        env: 'sandbox',
        hyperParams: { appId: 'test-app', sdkVersion: '1.0.0' },
      };

      await savedPaymentMethodAPICall(nativeProp);
    });

    it('handles custom backend URL', async () => {
      const nativeProp = {
        publishableKey: 'pk_test_123',
        clientSecret: 'pi_123_secret_456',
        customBackendUrl: 'https://custom.api.com',
        hyperParams: { appId: 'test-app', sdkVersion: '1.0.0' },
      };

      await savedPaymentMethodAPICall(nativeProp);
    });
  });

  describe('sessionAPICall', () => {
    it('returns a promise', () => {
      const nativeProp = {
        publishableKey: 'pk_test_123',
        clientSecret: 'pi_123_secret_456',
        env: 'sandbox',
        hyperParams: { appId: 'test-app', sdkVersion: '1.0.0' },
      };

      const result = sessionAPICall(nativeProp);
      expect(result).toBeInstanceOf(Promise);
    });

    it('handles custom backend URL', async () => {
      const nativeProp = {
        publishableKey: 'pk_test_123',
        clientSecret: 'pi_123_secret_456',
        customBackendUrl: 'https://custom.api.com',
        hyperParams: { appId: 'test-app', sdkVersion: '1.0.0' },
      };

      await sessionAPICall(nativeProp);
    });
  });

  describe('confirmAPICall', () => {
    it('returns a promise', () => {
      const nativeProp = {
        publishableKey: 'pk_test_123',
        clientSecret: 'pi_123_secret_456',
        env: 'sandbox',
        hyperParams: { appId: 'test-app', sdkVersion: '1.0.0' },
      };
      const body = JSON.stringify({ payment_method: 'card' });

      const result = confirmAPICall(nativeProp, body);
      expect(result).toBeInstanceOf(Promise);
    });

    it('handles custom backend URL', async () => {
      const nativeProp = {
        publishableKey: 'pk_test_123',
        clientSecret: 'pi_123_secret_456',
        customBackendUrl: 'https://custom.api.com',
        hyperParams: { appId: 'test-app', sdkVersion: '1.0.0' },
      };
      const body = JSON.stringify({ payment_method: 'wallet' });

      await confirmAPICall(nativeProp, body);
    });
  });

  describe('logWrapper', () => {
    it('calls logWrapper without throwing', () => {
      const nativeProp = {
        publishableKey: 'pk_test_123',
        env: 'sandbox',
        customLogUrl: undefined,
        hyperParams: { sdkVersion: '1.0.0' },
      };

      expect(() => {
        logWrapper(
          'INFO',
          'TEST_EVENT',
          'https://api.test.com',
          '200',
          'Request',
          'API',
          { data: 'test' },
          'card',
          'default',
          nativeProp.publishableKey,
          'payment_123',
          Date.now(),
          100,
          nativeProp.env,
          nativeProp.customLogUrl,
          nativeProp.hyperParams.sdkVersion,
          undefined
        );
      }).not.toThrow();
    });

    it('handles undefined apiLogType', () => {
      const nativeProp = {
        publishableKey: 'pk_test_123',
        env: 'sandbox',
        customLogUrl: undefined,
        hyperParams: { sdkVersion: '1.0.0' },
      };

      expect(() => {
        logWrapper(
          'DEBUG',
          'ANOTHER_EVENT',
          '',
          '',
          undefined,
          'API',
          null,
          undefined,
          undefined,
          nativeProp.publishableKey,
          '',
          Date.now(),
          0,
          nativeProp.env,
          nativeProp.customLogUrl,
          nativeProp.hyperParams.sdkVersion,
          undefined
        );
      }).not.toThrow();
    });

    it('handles Response apiLogType', () => {
      const nativeProp = {
        publishableKey: 'pk_test_123',
        env: 'sandbox',
        hyperParams: { sdkVersion: '1.0.0' },
      };

      expect(() => {
        logWrapper(
          'INFO',
          'API_RESPONSE',
          'https://api.test.com/endpoint',
          '200',
          'Response',
          'API',
          { status: 'success' },
          'wallet',
          'google_pay',
          nativeProp.publishableKey,
          'payment_456',
          Date.now(),
          50,
          nativeProp.env,
          undefined,
          nativeProp.hyperParams.sdkVersion,
          undefined
        );
      }).not.toThrow();
    });

    it('handles Err apiLogType', () => {
      const nativeProp = {
        publishableKey: 'pk_test_123',
        env: 'sandbox',
        hyperParams: { sdkVersion: '1.0.0' },
      };

      expect(() => {
        logWrapper(
          'ERROR',
          'API_ERROR',
          'https://api.test.com/endpoint',
          '500',
          'Err',
          'API',
          { error: 'server error' },
          'card',
          'default',
          nativeProp.publishableKey,
          'payment_789',
          Date.now(),
          200,
          nativeProp.env,
          undefined,
          nativeProp.hyperParams.sdkVersion,
          undefined
        );
      }).not.toThrow();
    });

    it('handles NoResponse apiLogType', () => {
      const nativeProp = {
        publishableKey: 'pk_test_123',
        env: 'sandbox',
        hyperParams: { sdkVersion: '1.0.0' },
      };

      expect(() => {
        logWrapper(
          'ERROR',
          'API_TIMEOUT',
          'https://api.test.com/endpoint',
          '504',
          'NoResponse',
          'API',
          { timeout: true },
          undefined,
          undefined,
          nativeProp.publishableKey,
          'payment_000',
          Date.now(),
          5000,
          nativeProp.env,
          undefined,
          nativeProp.hyperParams.sdkVersion,
          undefined
        );
      }).not.toThrow();
    });
  });
});
