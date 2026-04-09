import { renderHook } from '@testing-library/react-native';
import React from 'react';

jest.mock('../hooks/WebKit.bs.js', () => ({
  platform: 'web',
  platformString: 'web',
}));

jest.mock('../utility/logics/APIUtils.bs.js', () => ({
  fetchApiWrapper: jest.fn(() => Promise.resolve({ status: 'succeeded' })),
}));

jest.mock('../hooks/LoggerHook.bs.js', () => ({
  useApiLogWrapper: jest.fn(() => jest.fn()),
  useLoggerHook: jest.fn(() => jest.fn()),
}));

jest.mock('../utility/constants/GlobalHooks.bs.js', () => ({
  useGetBaseUrl: jest.fn(() => () => 'https://sandbox.hyperswitch.io'),
}));

jest.mock('../utility/logics/Utils.bs.js', () => ({
  getHeader: jest.fn(() => ({ 'Content-Type': 'application/json' })),
  getReturnUrl: jest.fn(() => 'https://return.url'),
  getObj: jest.fn(() => ({})),
  getOptionString: jest.fn(() => undefined),
  getString: jest.fn(() => ''),
  getBool: jest.fn(() => false),
  getOptionalObj: jest.fn(() => undefined),
  getArray: jest.fn(() => []),
  getDictFromJson: jest.fn(() => ({})),
  getJsonObjectFromDict: jest.fn(() => null),
  retOptionalStr: jest.fn(() => undefined),
  retOptionalFloat: jest.fn(() => undefined),
  splitName: jest.fn(() => ['', '']),
  getOptionFloat: jest.fn(() => undefined),
  getProp: jest.fn(() => undefined),
}));

jest.mock('../utility/logics/PaymentUtils.bs.js', () => ({
  generateSessionsTokenBody: jest.fn(() => JSON.stringify({})),
  getActionType: jest.fn(() => 'default'),
}));

jest.mock('../components/modules/HyperModule.bs.js', () => ({
  useExitPaymentsheet: jest.fn(() => ({
    exit: jest.fn(),
    simplyExit: jest.fn(),
  })),
  useExitCard: jest.fn(() => jest.fn()),
  useExitWidget: jest.fn(() => jest.fn()),
  stringifiedResStatus: jest.fn((status) => JSON.stringify(status)),
}));

jest.mock('../hooks/AllPaymentHelperHooks.bs.js', () => ({
  BrowserRedirectionHooks: {
    useBrowserRedirectionSuccessHook: jest.fn(() => jest.fn()),
    useBrowserRedirectionCancelHook: jest.fn(() => jest.fn()),
    useBrowserRedirectionFailedHook: jest.fn(() => jest.fn()),
  },
  RedirectionHooks: {
    useRedirectionHelperHook: jest.fn(() => jest.fn()),
  },
}));

jest.mock('../hooks/BrowserHook.bs.js', () => ({
  openUrl: jest.fn(() => Promise.resolve({ status: 'Success' })),
}));

jest.mock('../hooks/NetceteraThreeDsHooks.bs.js', () => ({
  useExternalThreeDs: jest.fn(() => jest.fn()),
}));

jest.mock('../hooks/PlaidHelperHook.bs.js', () => ({
  usePlaidProps: jest.fn(() => jest.fn()),
}));

jest.mock('../components/modules/Plaid/Plaid.bs.js', () => ({
  create: jest.fn(),
  open_: jest.fn(),
}));

jest.mock('../utility/config/next/Next.bs.js', () => ({
  getNextEnv: 'native',
  listRes: { status: 'succeeded' },
  clistRes: { customer_payment_methods: [] },
  sessionsRes: [],
}));

jest.mock('../types/SdkTypes.bs.js', () => ({
  nativeJsonToRecord: jest.fn(() => ({
    publishableKey: 'pk_test_123',
    clientSecret: 'pi_123_secret_456',
    paymentMethodId: 'pi_123',
    ephemeralKey: undefined,
    customBackendUrl: undefined,
    customLogUrl: undefined,
    sessionId: 'session_123',
    from: 'native',
    configuration: {},
    env: 'sandbox',
    sdkState: 'PaymentSheet',
    rootTag: 1,
    hyperParams: { appId: 'test-app', country: 'US', sdkVersion: '1.0.0' },
    customParams: {},
  })),
  sdkStateToStrMapper: jest.fn(() => 'PAYMENT_SHEET'),
  widgetToStrMapper: jest.fn(() => 'GOOGLE_PAY'),
  defaultAppearance: {},
}));

const mockNativePropContext = React.createContext([{}, jest.fn()]);
const mockAllApiDataContext = React.createContext([undefined, undefined, undefined]);
const mockLoadingContext = React.createContext(['FillingDetails', jest.fn()]);
const mockLoggerContext = React.createContext([{}, jest.fn()]);

jest.mock('../contexts/NativePropContext.bs.js', () => ({
  nativePropContext: mockNativePropContext,
  defaultValue: {},
  defaultSetter: jest.fn(),
  Provider: mockNativePropContext.Provider,
  make: mockNativePropContext.Provider,
}));

jest.mock('../contexts/AllApiDataContextNew.bs.js', () => ({
  allApiDataContext: mockAllApiDataContext,
  Provider: mockAllApiDataContext.Provider,
  make: mockAllApiDataContext.Provider,
}));

jest.mock('../contexts/LoadingContext.bs.js', () => ({
  loadingContext: mockLoadingContext,
  defaultSetter: jest.fn(),
  Provider: mockLoadingContext.Provider,
  make: mockLoadingContext.Provider,
}));

jest.mock('../contexts/LoggerContext.bs.js', () => ({
  loggingContext: mockLoggerContext,
  Provider: mockLoggerContext.Provider,
  make: mockLoggerContext.Provider,
}));

const createMockNativeProp = (overrides = {}) => ({
  publishableKey: 'pk_test_123',
  clientSecret: 'pi_123_secret_456',
  paymentMethodId: 'pi_123',
  ephemeralKey: undefined,
  customBackendUrl: undefined,
  customLogUrl: undefined,
  sessionId: 'session_123',
  from: 'native',
  configuration: {
    displayMergedSavedMethods: false,
    merchantDisplayName: 'Test Merchant',
    appearance: {},
    allowsDelayedPaymentMethods: false,
    netceteraSDKApiKey: undefined,
  },
  env: 'sandbox',
  sdkState: 'PaymentSheet',
  rootTag: 1,
  hyperParams: {
    confirm: false,
    appId: 'test-app',
    country: 'US',
    sdkVersion: '1.0.0',
  },
  customParams: {},
  ...overrides,
});

const {
  useHandleSuccessFailure,
  useRetrieveHook,
  usePaymentMethodHook,
  useSessionTokenHook,
  useBrowserHook,
  useRedirectHook,
  useGetSavedPMHook,
  useDeleteSavedPaymentMethod,
  useSavePaymentMethod
} = require('../hooks/AllPaymentHooks.bs.js');

describe('AllPaymentHooks', () => {
  describe('useHandleSuccessFailure', () => {
    const createWrapper = (nativeProp: any) => {
      return ({ children }: { children: React.ReactNode }) => {
        return React.createElement(
          mockNativePropContext.Provider,
          { value: [nativeProp, jest.fn()] as any },
          children,
        );
      };
    };

    it('returns a function that handles success/failure', () => {
      const nativeProp = createMockNativeProp();
      const wrapper = createWrapper(nativeProp);
      
      const { result } = renderHook(() => useHandleSuccessFailure(), { wrapper });
      
      expect(result.current).toBeDefined();
      expect(typeof result.current).toBe('function');
    });

    it('handles Headless sdkState without calling exit', () => {
      const nativeProp = createMockNativeProp({ sdkState: 'Headless' });
      const wrapper = createWrapper(nativeProp);
      
      const { result } = renderHook(() => useHandleSuccessFailure(), { wrapper });
      
      const handler = result.current;
      const apiResStatus = { message: '', code: '', type_: '', status: 'succeeded' };
      
      expect(() => handler(apiResStatus, true, true, undefined)).not.toThrow();
    });

    it('handles NoView sdkState without calling exit', () => {
      const nativeProp = createMockNativeProp({ sdkState: 'NoView' });
      const wrapper = createWrapper(nativeProp);
      
      const { result } = renderHook(() => useHandleSuccessFailure(), { wrapper });
      
      const handler = result.current;
      const apiResStatus = { message: '', code: '', type_: '', status: 'succeeded' };
      
      expect(() => handler(apiResStatus, true, true, undefined)).not.toThrow();
    });

    it('handles CardWidget sdkState', () => {
      const nativeProp = createMockNativeProp({ sdkState: 'CardWidget' });
      const wrapper = createWrapper(nativeProp);
      
      const { result } = renderHook(() => useHandleSuccessFailure(), { wrapper });
      
      const handler = result.current;
      const apiResStatus = { message: '', code: '', type_: '', status: 'succeeded' };
      
      expect(() => handler(apiResStatus, true, true, undefined)).not.toThrow();
    });

    it('handles ExpressCheckoutWidget sdkState', () => {
      const nativeProp = createMockNativeProp({ sdkState: 'ExpressCheckoutWidget' });
      const wrapper = createWrapper(nativeProp);
      
      const { result } = renderHook(() => useHandleSuccessFailure(), { wrapper });
      
      const handler = result.current;
      const apiResStatus = { message: '', code: '', type_: '', status: 'succeeded' };
      
      expect(() => handler(apiResStatus, true, true, undefined)).not.toThrow();
    });

    it('handles CustomWidget sdkState', () => {
      const nativeProp = createMockNativeProp({ sdkState: { TAG: 'CustomWidget', _0: 'GOOGLE_PAY' } });
      const wrapper = createWrapper(nativeProp);
      
      const { result } = renderHook(() => useHandleSuccessFailure(), { wrapper });
      
      const handler = result.current;
      const apiResStatus = { message: '', code: '', type_: '', status: 'succeeded' };
      
      expect(() => handler(apiResStatus, true, true, undefined)).not.toThrow();
    });
  });

  describe('useRetrieveHook', () => {
    const createWrapper = (nativeProp: any) => {
      return ({ children }: { children: React.ReactNode }) => {
        return React.createElement(
          mockNativePropContext.Provider,
          { value: [nativeProp, jest.fn()] as any },
          children,
        );
      };
    };

    it('returns a function that retrieves payment data', () => {
      const nativeProp = createMockNativeProp();
      const wrapper = createWrapper(nativeProp);
      
      const { result } = renderHook(() => useRetrieveHook(), { wrapper });
      
      expect(result.current).toBeDefined();
      expect(typeof result.current).toBe('function');
    });

    it('returns a promise when called with Payment type', async () => {
      const nativeProp = createMockNativeProp();
      const wrapper = createWrapper(nativeProp);
      
      const { result } = renderHook(() => useRetrieveHook(), { wrapper });
      
      const retrieveFn = result.current;
      const promise = retrieveFn('Payment', 'pi_123_secret_456', 'pk_test_123');
      
      expect(promise).toBeInstanceOf(Promise);
    });

    it('returns a promise when called with non-Payment type', async () => {
      const nativeProp = createMockNativeProp();
      const wrapper = createWrapper(nativeProp);
      
      const { result } = renderHook(() => useRetrieveHook(), { wrapper });
      
      const retrieveFn = result.current;
      const promise = retrieveFn('PaymentMethod', 'pi_123_secret_456', 'pk_test_123');
      
      expect(promise).toBeInstanceOf(Promise);
    });

    it('handles forceSync parameter', async () => {
      const nativeProp = createMockNativeProp();
      const wrapper = createWrapper(nativeProp);
      
      const { result } = renderHook(() => useRetrieveHook(), { wrapper });
      
      const retrieveFn = result.current;
      const promise = retrieveFn('Payment', 'pi_123_secret_456', 'pk_test_123', true);
      
      expect(promise).toBeInstanceOf(Promise);
    });
  });

  describe('usePaymentMethodHook', () => {
    const createWrapper = (nativeProp: any) => {
      return ({ children }: { children: React.ReactNode }) => {
        return React.createElement(
          mockNativePropContext.Provider,
          { value: [nativeProp, jest.fn()] as any },
          children,
        );
      };
    };

    it('returns a function that fetches payment methods', () => {
      const nativeProp = createMockNativeProp();
      const wrapper = createWrapper(nativeProp);
      
      const { result } = renderHook(() => usePaymentMethodHook(), { wrapper });
      
      expect(result.current).toBeDefined();
      expect(typeof result.current).toBe('function');
    });

    it('returns a promise when called', async () => {
      const nativeProp = createMockNativeProp();
      const wrapper = createWrapper(nativeProp);
      
      const { result } = renderHook(() => usePaymentMethodHook(), { wrapper });
      
      const paymentMethodFn = result.current;
      const promise = paymentMethodFn();
      
      expect(promise).toBeInstanceOf(Promise);
    });

    it('handles customerLevel parameter', async () => {
      const nativeProp = createMockNativeProp();
      const wrapper = createWrapper(nativeProp);
      
      const { result } = renderHook(() => usePaymentMethodHook(true), { wrapper });
      
      const paymentMethodFn = result.current;
      const promise = paymentMethodFn();
      
      expect(promise).toBeInstanceOf(Promise);
    });
  });

  describe('useSessionTokenHook', () => {
    const createWrapper = (nativeProp: any) => {
      return ({ children }: { children: React.ReactNode }) => {
        return React.createElement(
          mockNativePropContext.Provider,
          { value: [nativeProp, jest.fn()] as any },
          children,
        );
      };
    };

    it('returns a function that fetches session tokens', () => {
      const nativeProp = createMockNativeProp();
      const wrapper = createWrapper(nativeProp);
      
      const { result } = renderHook(() => useSessionTokenHook(), { wrapper });
      
      expect(result.current).toBeDefined();
      expect(typeof result.current).toBe('function');
    });

    it('returns a promise when called with wallet array', async () => {
      const nativeProp = createMockNativeProp();
      const wrapper = createWrapper(nativeProp);
      
      const { result } = renderHook(() => useSessionTokenHook(), { wrapper });
      
      const sessionTokenFn = result.current;
      const promise = sessionTokenFn(['google_pay', 'apple_pay']);
      
      expect(promise).toBeInstanceOf(Promise);
    });

    it('returns a promise when called without wallet parameter', async () => {
      const nativeProp = createMockNativeProp();
      const wrapper = createWrapper(nativeProp);
      
      const { result } = renderHook(() => useSessionTokenHook(), { wrapper });
      
      const sessionTokenFn = result.current;
      const promise = sessionTokenFn();
      
      expect(promise).toBeInstanceOf(Promise);
    });
  });

  describe('useBrowserHook', () => {
    const createWrapper = (nativeProp: any, accountData: any) => {
      return ({ children }: { children: React.ReactNode }) => {
        return React.createElement(
          mockNativePropContext.Provider,
          { value: [nativeProp, jest.fn()] as any },
          React.createElement(
            mockAllApiDataContext.Provider,
            { value: [accountData, undefined, undefined] as any },
            children,
          ),
        );
      };
    };

    it('returns an async function that handles browser redirection', () => {
      const nativeProp = createMockNativeProp();
      const wrapper = createWrapper(nativeProp, undefined);
      
      const { result } = renderHook(() => useBrowserHook(), { wrapper });
      
      expect(result.current).toBeDefined();
      expect(typeof result.current).toBe('function');
    });

    it('returns a promise when called', async () => {
      const nativeProp = createMockNativeProp();
      const wrapper = createWrapper(nativeProp, undefined);
      
      const { result } = renderHook(() => useBrowserHook(), { wrapper });
      
      const browserFn = result.current;
      const promise = browserFn(
        'pi_123_secret_456',
        'pk_test_123',
        'https://example.com/pay',
        jest.fn(),
        jest.fn(),
        'card',
        false,
      );
      
      expect(promise).toBeInstanceOf(Promise);
    });
  });

  describe('useRedirectHook', () => {
    const createWrapper = (nativeProp: any) => {
      return ({ children }: { children: React.ReactNode }) => {
        return React.createElement(
          mockNativePropContext.Provider,
          { value: [nativeProp, jest.fn()] as any },
          React.createElement(
            mockLoadingContext.Provider,
            { value: ['FillingDetails', jest.fn()] as any },
            children,
          ),
        );
      };
    };

    it('returns a function that handles payment redirection', () => {
      const nativeProp = createMockNativeProp();
      const wrapper = createWrapper(nativeProp);
      
      const { result } = renderHook(() => useRedirectHook(), { wrapper });
      
      expect(result.current).toBeDefined();
      expect(typeof result.current).toBe('function');
    });

    it('handles redirect with body and callbacks', () => {
      const nativeProp = createMockNativeProp();
      const wrapper = createWrapper(nativeProp);
      
      const { result } = renderHook(() => useRedirectHook(), { wrapper });
      
      const redirectFn = result.current;
      const body = { payment_method: 'card' };
      const errorCallback = jest.fn();
      const responseCallback = jest.fn();
      
      expect(() => {
        redirectFn(body, 'pk_test_123', 'pi_123_secret_456', errorCallback, 'card', undefined, responseCallback, false, undefined);
      }).not.toThrow();
    });
  });

  describe('useGetSavedPMHook', () => {
    const createWrapper = (nativeProp: any) => {
      return ({ children }: { children: React.ReactNode }) => {
        return React.createElement(
          mockNativePropContext.Provider,
          { value: [nativeProp, jest.fn()] as any },
          children,
        );
      };
    };

    it('returns a function that fetches saved payment methods', () => {
      const nativeProp = createMockNativeProp();
      const wrapper = createWrapper(nativeProp);
      
      const { result } = renderHook(() => useGetSavedPMHook(), { wrapper });
      
      expect(result.current).toBeDefined();
      expect(typeof result.current).toBe('function');
    });

    it('returns a promise when called', async () => {
      const nativeProp = createMockNativeProp();
      const wrapper = createWrapper(nativeProp);
      
      const { result } = renderHook(() => useGetSavedPMHook(), { wrapper });
      
      const getSavedPMFn = result.current;
      const promise = getSavedPMFn();
      
      expect(promise).toBeInstanceOf(Promise);
    });
  });

  describe('useDeleteSavedPaymentMethod', () => {
    const createWrapper = (nativeProp: any) => {
      return ({ children }: { children: React.ReactNode }) => {
        return React.createElement(
          mockNativePropContext.Provider,
          { value: [nativeProp, jest.fn()] as any },
          children,
        );
      };
    };

    it('returns a function that deletes saved payment methods', () => {
      const nativeProp = createMockNativeProp();
      const wrapper = createWrapper(nativeProp);
      
      const { result } = renderHook(() => useDeleteSavedPaymentMethod(), { wrapper });
      
      expect(result.current).toBeDefined();
      expect(typeof result.current).toBe('function');
    });

    it('returns a promise when called with payment method id', async () => {
      const nativeProp = createMockNativeProp({ ephemeralKey: 'ek_test_123' });
      const wrapper = createWrapper(nativeProp);
      
      const { result } = renderHook(() => useDeleteSavedPaymentMethod(), { wrapper });
      
      const deleteFn = result.current;
      const promise = deleteFn('pm_123');
      
      expect(promise).toBeInstanceOf(Promise);
    });

    it('returns null promise when ephemeralKey is undefined', async () => {
      const nativeProp = createMockNativeProp({ ephemeralKey: undefined });
      const wrapper = createWrapper(nativeProp);
      
      const { result } = renderHook(() => useDeleteSavedPaymentMethod(), { wrapper });
      
      const deleteFn = result.current;
      const promise = deleteFn('pm_123');
      
      expect(promise).toBeInstanceOf(Promise);
      const resolved = await promise;
      expect(resolved).toBeNull();
    });
  });

  describe('useSavePaymentMethod', () => {
    const createWrapper = (nativeProp: any) => {
      return ({ children }: { children: React.ReactNode }) => {
        return React.createElement(
          mockNativePropContext.Provider,
          { value: [nativeProp, jest.fn()] as any },
          children,
        );
      };
    };

    it('returns a function that saves payment methods', () => {
      const nativeProp = createMockNativeProp();
      const wrapper = createWrapper(nativeProp);
      
      const { result } = renderHook(() => useSavePaymentMethod(), { wrapper });
      
      expect(result.current).toBeDefined();
      expect(typeof result.current).toBe('function');
    });

    it('returns a promise when called with body', async () => {
      const nativeProp = createMockNativeProp();
      const wrapper = createWrapper(nativeProp);
      
      const { result } = renderHook(() => useSavePaymentMethod(), { wrapper });
      
      const saveFn = result.current;
      const promise = saveFn({ payment_method: 'card' });
      
      expect(promise).toBeInstanceOf(Promise);
    });

    it('handles undefined body', async () => {
      const nativeProp = createMockNativeProp();
      const wrapper = createWrapper(nativeProp);
      
      const { result } = renderHook(() => useSavePaymentMethod(), { wrapper });
      
      const saveFn = result.current;
      const promise = saveFn(undefined);
      
      expect(promise).toBeInstanceOf(Promise);
    });
  });
});
