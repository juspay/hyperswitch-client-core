import { renderHook, act } from '@testing-library/react-native';
import React from 'react';

jest.mock('../components/modules/Netcetera3dsModule.bs.js', () => ({
  initialiseNetceteraSDK: jest.fn((apiKey, env, callback) => {
    callback({ status: 'success', message: 'Initialized' });
  }),
  generateAReqParams: jest.fn((messageVersion, directoryServerId, callback) => {
    callback({ status: 'success', message: 'Generated' }, {
      sdkAppId: 'app-123',
      sdkTransId: 'trans-123',
      sdkReferenceNo: 'ref-123',
      deviceData: 'device-data',
      sdkEphemeralKey: '{"kty":"EC","crv":"P-256","x":"test","y":"test"}',
    });
  }),
  recieveChallengeParamsFromRN: jest.fn((acsSignedContent, acsRefNumber, acsTransactionId, threeDSServerTransId, callback, returnUrl) => {
    callback({ status: 'success', message: 'Received' });
  }),
  generateChallenge: jest.fn((callback) => {
    callback({ status: 'success', message: 'Challenge generated' });
  }),
  isAvailable: true,
}));

jest.mock('../utility/logics/APIUtils.bs.js', () => ({
  fetchApi: jest.fn(() => Promise.resolve({
    status: 200,
    json: () => Promise.resolve({
      status: 'completed',
      three_ds_auth: {
        acs_signed_content: 'signed-content',
        acs_ref_number: 'ref-number',
        acs_transaction_id: 'acs-trans-id',
        three_ds_server_trans_id: 'server-trans-id',
        three_ds_requestor_app_url: 'https://return.url',
        trans_status: 'C',
      },
    }),
  })),
}));

jest.mock('../utility/logics/ThreeDsUtils.bs.js', () => ({
  getThreeDsDataObj: jest.fn(() => ({
    threeDsAuthenticationUrl: 'https://auth.url',
    threeDsAuthorizeUrl: 'https://authorize.url',
    messageVersion: '2.1.0',
    directoryServerId: 'dir-server-id',
    pollConfig: { pollId: 'poll-123', delayInSecs: 1, frequency: 5 },
  })),
  getThreeDsNextActionObj: jest.fn(() => ({
    threeDsData: {
      threeDsAuthenticationUrl: 'https://auth.url',
      threeDsAuthorizeUrl: 'https://authorize.url',
      messageVersion: '2.1.0',
      directoryServerId: 'dir-server-id',
      pollConfig: { pollId: 'poll-123', delayInSecs: 1, frequency: 5 },
    },
  })),
  isStatusSuccess: jest.fn((status) => status && status.status === 'success'),
  sdkEnvironmentToStrMapper: jest.fn((env) => env),
  getAuthCallHeaders: jest.fn((pk) => ({
    'Content-Type': 'application/json',
    'api-key': pk,
    'Accept': 'application/json',
  })),
  generateAuthenticationCallBody: jest.fn(() => JSON.stringify({ client_secret: 'test' })),
}));

jest.mock('../utility/logics/Utils.bs.js', () => ({
  getReturnUrl: jest.fn(() => 'https://return.url'),
  getError: jest.fn((err, msg) => msg),
  getString: jest.fn(() => ''),
  getDictFromJson: jest.fn(() => ({})),
}));

jest.mock('../types/ExternalThreeDsTypes.bs.js', () => ({
  pollResponseItemToObjMapper: jest.fn((obj) => ({ status: 'completed' })),
  authResponseItemToObjMapper: jest.fn((res) => ({
    TAG: 'AUTH_RESPONSE',
    _0: {
      acsSignedContent: 'signed-content',
      acsRefNumber: 'ref-number',
      acsTransactionId: 'acs-trans-id',
      threeDSServerTransId: 'server-trans-id',
      threeDSRequestorAppURL: 'https://return.url',
      transStatus: 'C',
    },
  })),
}));

jest.mock('../utility/constants/SdkStatusMessages.bs.js', () => ({
  externalThreeDsModuleStatus: { errorMsg: 'SDK not available' },
  retrievePaymentStatus: {
    successMsg: 'Payment succeeded',
    errorMsg: 'Payment failed',
    apiCallFailure: 'API call failed',
  },
}));

const mockLoadingContext = React.createContext(['FillingDetails', jest.fn()]);
const mockLoggerContext = React.createContext([{}, jest.fn()]);
const mockNativePropContext = React.createContext([{
  publishableKey: 'pk_test_123',
  clientSecret: 'pi_123_secret_456',
  sessionId: 'session_123',
  sdkState: 'PaymentSheet',
  hyperParams: { appId: 'test-app', sdkVersion: '1.0.0', userAgent: 'test-agent' },
}, jest.fn()]);

jest.mock('../contexts/LoadingContext.bs.js', () => ({
  loadingContext: mockLoadingContext,
  Provider: mockLoadingContext.Provider,
}));

jest.mock('../contexts/LoggerContext.bs.js', () => ({
  loggingContext: mockLoggerContext,
  Provider: mockLoggerContext.Provider,
}));

jest.mock('../contexts/NativePropContext.bs.js', () => ({
  nativePropContext: mockNativePropContext,
  Provider: mockNativePropContext.Provider,
}));

jest.mock('../hooks/LoggerHook.bs.js', () => ({
  useLoggerHook: jest.fn(() => jest.fn()),
  useApiLogWrapper: jest.fn(() => jest.fn()),
}));

const {
  initialisedNetceteraOnce,
  useInitNetcetera,
  useExternalThreeDs,
  isInitialisedPromiseRef,
} = require('../hooks/NetceteraThreeDsHooks.bs.js');

describe('NetceteraThreeDsHooks', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    isInitialisedPromiseRef.contents = undefined;
  });

  describe('initialisedNetceteraOnce', () => {
    it('returns a promise that resolves with success status', async () => {
      const promise = initialisedNetceteraOnce('test-api-key', 'SANDBOX');
      
      expect(promise).toBeInstanceOf(Promise);
      
      const result = await promise;
      expect(result).toEqual({ status: 'success', message: 'Initialized' });
    });

    it('caches the promise and returns the same instance on subsequent calls', async () => {
      const promise1 = initialisedNetceteraOnce('test-api-key', 'SANDBOX');
      const promise2 = initialisedNetceteraOnce('test-api-key', 'SANDBOX');
      
      expect(promise1).toBe(promise2);
    });

    it('stores the promise in isInitialisedPromiseRef', () => {
      initialisedNetceteraOnce('test-api-key', 'SANDBOX');
      
      expect(isInitialisedPromiseRef.contents).toBeDefined();
      expect(isInitialisedPromiseRef.contents).toBeInstanceOf(Promise);
    });

    it('returns cached promise when already initialized', async () => {
      const promise1 = initialisedNetceteraOnce('test-api-key', 'SANDBOX');
      await promise1;
      
      isInitialisedPromiseRef.contents = Promise.resolve({ status: 'cached', message: 'Cached' });
      
      const promise2 = initialisedNetceteraOnce('another-key', 'PROD');
      const result = await promise2;
      
      expect(result).toEqual({ status: 'cached', message: 'Cached' });
    });
  });

  describe('useInitNetcetera', () => {
    const createWrapper = () => {
      return ({ children }: { children: React.ReactNode }) => {
        return React.createElement(
          mockNativePropContext.Provider,
          { value: [{ 
            publishableKey: 'pk_test',
            clientSecret: 'pi_secret',
            sessionId: 'session',
            sdkState: 'PaymentSheet',
            hyperParams: { appId: 'app', sdkVersion: '1.0', userAgent: 'agent' },
          }, jest.fn()] as any },
          React.createElement(
            mockLoggerContext.Provider,
            { value: [{}, jest.fn()] as any },
            children,
          ),
        );
      };
    };

    it('returns a function that initializes netcetera', () => {
      const wrapper = createWrapper();
      
      const { result } = renderHook(() => useInitNetcetera(), { wrapper });
      
      expect(result.current).toBeDefined();
      expect(typeof result.current).toBe('function');
    });

    it('calls the initialization function with api key and environment', async () => {
      const wrapper = createWrapper();
      
      const { result } = renderHook(() => useInitNetcetera(), { wrapper });
      
      await act(async () => {
        result.current('test-api-key', 'SANDBOX');
      });
      
      expect(require('../components/modules/Netcetera3dsModule.bs.js').initialiseNetceteraSDK).toHaveBeenCalled();
    });

    it('returns function that returns undefined (no explicit return)', async () => {
      const wrapper = createWrapper();
      
      const { result } = renderHook(() => useInitNetcetera(), { wrapper });
      
      const initFn = result.current;
      const returnVal = initFn('api-key', 'PROD');
      
      expect(returnVal).toBeUndefined();
    });
  });

  describe('useExternalThreeDs', () => {
    const createWrapper = () => {
      return ({ children }: { children: React.ReactNode }) => {
        return React.createElement(
          mockNativePropContext.Provider,
          { value: [{ 
            publishableKey: 'pk_test',
            clientSecret: 'pi_secret',
            sessionId: 'session',
            sdkState: 'PaymentSheet',
            hyperParams: { appId: 'app', sdkVersion: '1.0', userAgent: 'agent' },
          }, jest.fn()] as any },
          React.createElement(
            mockLoggerContext.Provider,
            { value: [{}, jest.fn()] as any },
            React.createElement(
              mockLoadingContext.Provider,
              { value: ['FillingDetails', jest.fn()] as any },
              children,
            ),
          ),
        );
      };
    };

    it('returns a function that handles external 3DS flow', () => {
      const wrapper = createWrapper();
      
      const { result } = renderHook(() => useExternalThreeDs(), { wrapper });
      
      expect(result.current).toBeDefined();
      expect(typeof result.current).toBe('function');
    });

    it('accepts all required parameters for 3DS flow', async () => {
      const wrapper = createWrapper();
      
      const { result } = renderHook(() => useExternalThreeDs(), { wrapper });
      
      const onSuccess = jest.fn();
      const onFailure = jest.fn();
      const retrievePayment = jest.fn(() => Promise.resolve({ status: 'succeeded' }));
      
      await act(async () => {
        result.current(
          'https://base.url',
          'app-id',
          'netcetera-api-key',
          'client-secret',
          'pk-test',
          { threeDsData: {} },
          'SANDBOX',
          retrievePayment,
          onSuccess,
          onFailure,
        );
      });
    });

    it('executes async flow without throwing errors', async () => {
      const wrapper = createWrapper();
      
      const { result } = renderHook(() => useExternalThreeDs(), { wrapper });
      
      const onSuccess = jest.fn();
      const onFailure = jest.fn();
      const retrievePayment = jest.fn(() => Promise.resolve(null));
      
      await act(async () => {
        expect(() => {
          result.current(
            'https://base.url',
            'app-id',
            'netcetera-api-key',
            'client-secret',
            'pk-test',
            {},
            'SANDBOX',
            retrievePayment,
            onSuccess,
            onFailure,
          );
        }).not.toThrow();
      });
    });
  });
});
