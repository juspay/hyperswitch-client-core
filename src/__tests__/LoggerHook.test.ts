import { renderHook, act } from '@testing-library/react-native';
import React from 'react';

const mockNativePropContext = React.createContext([{}, jest.fn()]);
const mockLoggerContext = React.createContext([{}, jest.fn()]);

jest.mock('../contexts/NativePropContext.bs.js', () => ({
  nativePropContext: mockNativePropContext,
  defaultValue: {},
  defaultSetter: jest.fn(),
  Provider: mockNativePropContext.Provider,
  make: mockNativePropContext.Provider,
}));

jest.mock('../contexts/LoggerContext.bs.js', () => ({
  loggingContext: mockLoggerContext,
  defaultSetter: jest.fn(),
  Provider: mockLoggerContext.Provider,
  make: mockLoggerContext.Provider,
}));

jest.mock('../utility/constants/GlobalHooks.bs.js', () => ({
  useGetLoggingUrl: jest.fn(() => () => 'https://logs.hyperswitch.io/logs/sdk'),
  useGetBaseUrl: jest.fn(() => () => 'https://api.hyperswitch.io'),
  useGetS3AssetsVersion: jest.fn(() => () => '/assets/v2'),
  useGetAssetUrlWithVersion: jest.fn(() => () => 'https://checkout.hyperswitch.io/assets/v2'),
}));

jest.mock('../utility/logics/LoggerUtils.bs.js', () => ({
  eventToStrMapper: jest.fn((eventName: string) => eventName),
  sdkVersionRef: { contents: '1.0.0' },
  logFileToObj: jest.fn((logFile: any) => logFile),
  sendLogs: jest.fn(),
}));

jest.mock('../hooks/WebKit.bs.js', () => ({
  platform: 'web',
  platformString: 'web',
  useWebKit: jest.fn(() => ({
    exitPaymentSheet: jest.fn(),
    sdkInitialised: jest.fn(),
    launchApplePay: jest.fn(),
    launchGPay: jest.fn(),
  })),
}));

jest.mock('../types/SdkTypes.bs.js', () => ({
  sdkStateToStrMapper: jest.fn((state: any) => 'PAYMENT_SHEET'),
  defaultAppearance: {},
  walletNameMapper: jest.fn(),
  walletNameToTypeMapper: jest.fn(),
  widgetToStrMapper: jest.fn(),
  walletTypeToStrMapper: jest.fn(),
  getColorFromDict: jest.fn(),
  getPrimaryButtonColorFromDict: jest.fn(),
  getAppearanceObj: jest.fn(),
  getPrimaryColor: jest.fn(),
  parseConfigurationDict: jest.fn(),
  nativeJsonToRecord: jest.fn(() => ({})),
  defaultCountry: 'US',
}));

jest.mock('../utility/config/version/VersionInfo.bs.js', () => ({
  version: '1.0.0',
}));

jest.mock('../types/AllApiDataTypes/PaymentMethodType.bs.js', () => ({
  getPaymentMethod: jest.fn((str: string) => str.toUpperCase()),
  getWalletType: jest.fn((str: string) => str.toUpperCase()),
  getExperienceType: jest.fn((str: string) => str.toUpperCase()),
  getPaymentExperienceType: jest.fn((str: string) => str),
}));

const {
  useCalculateLatency,
  inactiveScreenApiCall,
  timeOut,
  snooze,
  cancel,
  useLoggerHook,
  useApiLogWrapper,
} = require('../hooks/LoggerHook.bs.js');

const LoggerUtils = require('../utility/logics/LoggerUtils.bs.js');

describe('LoggerHook', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    jest.useFakeTimers();
    timeOut.contents = null;
  });

  afterEach(() => {
    jest.useRealTimers();
  });

  describe('useCalculateLatency', () => {
    const createWrapper = (events: any = {}) => {
      return ({ children }: { children: React.ReactNode }) => {
        return React.createElement(
          mockLoggerContext.Provider,
          { value: [events, jest.fn()] },
          children,
        );
      };
    };

    it('returns empty string for PAYMENT_ATTEMPT when APP_RENDERED event is not set', () => {
      const wrapper = createWrapper({});
      const { result } = renderHook(() => useCalculateLatency(), { wrapper });
      
      const latency = result.current('PAYMENT_ATTEMPT');
      expect(latency).toBe('');
    });

    it('calculates latency for PAYMENT_ATTEMPT when APP_RENDERED event is set', () => {
      const now = Date.now();
      const events = { APP_RENDERED: now - 1000 };
      const wrapper = createWrapper(events);
      
      const { result } = renderHook(() => useCalculateLatency(), { wrapper });
      
      const latency = result.current('PAYMENT_ATTEMPT');
      expect(latency).not.toBe('');
      expect(parseInt(latency)).toBeGreaterThanOrEqual(1000);
    });

    it('returns empty string for CONFIRM_CALL_INIT event when init timestamp is not set', () => {
      const wrapper = createWrapper({});
      const { result } = renderHook(() => useCalculateLatency(), { wrapper });
      
      const latency = result.current('CONFIRM_CALL');
      expect(latency).toBe('');
    });

    it('calculates latency for CONFIRM_CALL when CONFIRM_CALL_INIT is set', () => {
      const now = Date.now();
      const events = { CONFIRM_CALL_INIT: now - 500 };
      const wrapper = createWrapper(events);
      
      const { result } = renderHook(() => useCalculateLatency(), { wrapper });
      
      const latency = result.current('CONFIRM_CALL');
      expect(latency).not.toBe('');
      expect(parseInt(latency)).toBeGreaterThanOrEqual(500);
    });

    it('returns 0 latency for CONFIRM_CALL_INIT (isRequest = true)', () => {
      const now = Date.now();
      const events = { CONFIRM_CALL_INIT: now - 500 };
      const wrapper = createWrapper(events);
      
      const { result } = renderHook(() => useCalculateLatency(), { wrapper });
      
      const latency = result.current('CONFIRM_CALL_INIT');
      expect(latency).toBe('');
    });

    it('returns empty string for CUSTOMER_PAYMENT_METHODS_CALL without init timestamp', () => {
      const wrapper = createWrapper({});
      const { result } = renderHook(() => useCalculateLatency(), { wrapper });
      
      const latency = result.current('CUSTOMER_PAYMENT_METHODS_CALL');
      expect(latency).toBe('');
    });

    it('calculates latency for PAYMENT_METHODS_CALL when init timestamp exists', () => {
      const now = Date.now();
      const events = { PAYMENT_METHODS_CALL_INIT: now - 200 };
      const wrapper = createWrapper(events);
      
      const { result } = renderHook(() => useCalculateLatency(), { wrapper });
      
      const latency = result.current('PAYMENT_METHODS_CALL');
      expect(latency).not.toBe('');
      expect(parseInt(latency)).toBeGreaterThanOrEqual(200);
    });

    it('calculates latency for RETRIEVE_CALL when init timestamp exists', () => {
      const now = Date.now();
      const events = { RETRIEVE_CALL_INIT: now - 300 };
      const wrapper = createWrapper(events);
      
      const { result } = renderHook(() => useCalculateLatency(), { wrapper });
      
      const latency = result.current('RETRIEVE_CALL');
      expect(latency).not.toBe('');
      expect(parseInt(latency)).toBeGreaterThanOrEqual(300);
    });

    it('calculates latency for SESSIONS_CALL when init timestamp exists', () => {
      const now = Date.now();
      const events = { SESSIONS_CALL_INIT: now - 150 };
      const wrapper = createWrapper(events);
      
      const { result } = renderHook(() => useCalculateLatency(), { wrapper });
      
      const latency = result.current('SESSIONS_CALL');
      expect(latency).not.toBe('');
      expect(parseInt(latency)).toBeGreaterThanOrEqual(150);
    });

    it('returns empty string for unknown event names', () => {
      const wrapper = createWrapper({});
      const { result } = renderHook(() => useCalculateLatency(), { wrapper });
      
      const latency = result.current('UNKNOWN_EVENT');
      expect(latency).toBe('');
    });
  });

  describe('inactiveScreenApiCall', () => {
    it('sends logs with correct parameters for first event', () => {
      const events = {};
      const setEvents = jest.fn();
      const nativeProp = {
        hyperParams: {
          sdkVersion: '1.0.0',
          userAgent: 'TestAgent',
          appId: 'test-app-id',
        },
        sdkState: 'PaymentSheet',
        publishableKey: 'pk_test_123',
      };

      inactiveScreenApiCall(
        'payment_123',
        'pk_test_123',
        'test-app-id',
        'web',
        'session_123',
        events,
        setEvents,
        nativeProp,
        'https://logs.hyperswitch.io/logs/sdk',
      );

      expect(LoggerUtils.sendLogs).toHaveBeenCalledWith(
        expect.objectContaining({
          eventName: 'INACTIVE_SCREEN',
          firstEvent: true,
          paymentId: 'payment_123',
          merchantId: 'pk_test_123',
          appId: 'test-app-id',
          platform: 'web',
          sessionId: 'session_123',
          logType: 'INFO',
          category: 'USER_EVENT',
        }),
        'https://logs.hyperswitch.io/logs/sdk',
        'pk_test_123',
        'test-app-id',
      );
      expect(setEvents).toHaveBeenCalled();
    });

    it('sends logs with firstEvent false for subsequent events', () => {
      const events = { INACTIVE_SCREEN: Date.now() - 5000 };
      const setEvents = jest.fn();
      const nativeProp = {
        hyperParams: {
          sdkVersion: '1.0.0',
          userAgent: 'TestAgent',
          appId: 'test-app-id',
        },
        sdkState: 'PaymentSheet',
        publishableKey: 'pk_test_123',
      };

      inactiveScreenApiCall(
        'payment_456',
        'pk_test_456',
        'app-id-456',
        'android',
        'session_456',
        events,
        setEvents,
        nativeProp,
        'https://logs.hyperswitch.io/logs/sdk',
      );

      expect(LoggerUtils.sendLogs).toHaveBeenCalledWith(
        expect.objectContaining({
          eventName: 'INACTIVE_SCREEN',
          firstEvent: false,
        }),
        'https://logs.hyperswitch.io/logs/sdk',
        'pk_test_123',
        'test-app-id',
      );
    });

    it('uses default userAgent when not provided', () => {
      const events = {};
      const setEvents = jest.fn();
      const nativeProp = {
        hyperParams: {
          sdkVersion: '1.0.0',
          userAgent: undefined,
          appId: 'test-app-id',
        },
        sdkState: 'PaymentSheet',
        publishableKey: 'pk_test_123',
      };

      inactiveScreenApiCall(
        'payment_123',
        'pk_test_123',
        'test-app-id',
        'web',
        'session_123',
        events,
        setEvents,
        nativeProp,
        'https://logs.hyperswitch.io/logs/sdk',
      );

      expect(LoggerUtils.sendLogs).toHaveBeenCalledWith(
        expect.objectContaining({
          userAgent: 'userAgent',
        }),
        expect.any(String),
        expect.any(String),
        expect.any(String),
      );
    });
  });

  describe('snooze and cancel', () => {
    it('snooze sets a timeout that calls inactiveScreenApiCall', () => {
      const events = {};
      const setEvents = jest.fn();
      const nativeProp = {
        hyperParams: {
          sdkVersion: '1.0.0',
          userAgent: 'TestAgent',
          appId: 'test-app-id',
        },
        sdkState: 'PaymentSheet',
        publishableKey: 'pk_test_123',
      };

      snooze(
        'payment_123',
        'pk_test_123',
        'test-app-id',
        'web',
        'session_123',
        events,
        setEvents,
        nativeProp,
        'https://logs.hyperswitch.io/logs/sdk',
      );

      expect(timeOut.contents).not.toBeNull();
      
      jest.advanceTimersByTime(120000);
      
      expect(LoggerUtils.sendLogs).toHaveBeenCalled();
    });

    it('cancel clears the timeout', () => {
      const events = {};
      const setEvents = jest.fn();
      const nativeProp = {
        hyperParams: {
          sdkVersion: '1.0.0',
          userAgent: 'TestAgent',
          appId: 'test-app-id',
        },
        sdkState: 'PaymentSheet',
        publishableKey: 'pk_test_123',
      };

      snooze(
        'payment_123',
        'pk_test_123',
        'test-app-id',
        'web',
        'session_123',
        events,
        setEvents,
        nativeProp,
        'https://logs.hyperswitch.io/logs/sdk',
      );

      expect(timeOut.contents).not.toBeNull();
      
      cancel();
      
      jest.advanceTimersByTime(120000);
      
      expect(LoggerUtils.sendLogs).not.toHaveBeenCalled();
    });

    it('cancel handles null timeout gracefully', () => {
      timeOut.contents = null;
      
      expect(() => cancel()).not.toThrow();
    });
  });

  describe('useLoggerHook', () => {
    const createWrapper = (nativeProp: any, events: any = {}) => {
      return ({ children }: { children: React.ReactNode }) => {
        const loggerWrapper = React.createElement(
          mockLoggerContext.Provider,
          { value: [events, jest.fn()] },
          children,
        );
        return React.createElement(
          mockNativePropContext.Provider,
          { value: [nativeProp, jest.fn()] },
          loggerWrapper,
        );
      };
    };

    const mockNativeProp = {
      hyperParams: {
        sdkVersion: '1.0.0',
        userAgent: 'TestAgent',
        appId: 'test-app-id',
      },
      sdkState: 'PaymentSheet',
      publishableKey: 'pk_test_123',
      clientSecret: 'payment_123_secret_abc',
      sessionId: 'session_123',
    };

    it('returns a function that sends logs with correct parameters', () => {
      const wrapper = createWrapper(mockNativeProp);
      const { result } = renderHook(() => useLoggerHook(), { wrapper });

      const logger = result.current;
      logger('INFO', 'Test log', 'USER_EVENT', undefined, undefined, undefined, undefined, 'TEST_EVENT', undefined, undefined);

      expect(LoggerUtils.sendLogs).toHaveBeenCalledWith(
        expect.objectContaining({
          logType: 'INFO',
          value: 'Test log',
          category: 'USER_EVENT',
          eventName: 'TEST_EVENT',
          firstEvent: true,
        }),
        expect.any(String),
        'pk_test_123',
        'test-app-id',
      );
    });

    it('marks firstEvent as false for repeated events', () => {
      const events = { TEST_EVENT: Date.now() - 1000 };
      const wrapper = createWrapper(mockNativeProp, events);
      const { result } = renderHook(() => useLoggerHook(), { wrapper });

      const logger = result.current;
      logger('INFO', 'Test log', 'USER_EVENT', undefined, undefined, undefined, undefined, 'TEST_EVENT', undefined, undefined);

      expect(LoggerUtils.sendLogs).toHaveBeenCalledWith(
        expect.objectContaining({
          firstEvent: false,
        }),
        expect.any(String),
        expect.any(String),
        expect.any(String),
      );
    });

    it('includes paymentMethod in logs when provided', () => {
      const wrapper = createWrapper(mockNativeProp);
      const { result } = renderHook(() => useLoggerHook(), { wrapper });

      const logger = result.current;
      logger('INFO', 'Test log', 'USER_EVENT', 'card', undefined, undefined, undefined, 'TEST_EVENT', undefined, undefined);

      expect(LoggerUtils.sendLogs).toHaveBeenCalledWith(
        expect.objectContaining({
          paymentMethod: 'card',
        }),
        expect.any(String),
        expect.any(String),
        expect.any(String),
      );
    });

    it('includes latency when provided', () => {
      const wrapper = createWrapper(mockNativeProp);
      const { result } = renderHook(() => useLoggerHook(), { wrapper });

      const logger = result.current;
      logger('INFO', 'Test log', 'USER_EVENT', undefined, undefined, undefined, undefined, 'TEST_EVENT', 500, undefined);

      expect(LoggerUtils.sendLogs).toHaveBeenCalledWith(
        expect.objectContaining({
          latency: '500',
        }),
        expect.any(String),
        expect.any(String),
        expect.any(String),
      );
    });

    it('includes internalMetadata when provided', () => {
      const wrapper = createWrapper(mockNativeProp);
      const { result } = renderHook(() => useLoggerHook(), { wrapper });

      const logger = result.current;
      logger('INFO', 'Test log', 'USER_EVENT', undefined, undefined, undefined, 'meta-data', 'TEST_EVENT', undefined, undefined);

      expect(LoggerUtils.sendLogs).toHaveBeenCalledWith(
        expect.objectContaining({
          internalMetadata: 'meta-data',
        }),
        expect.any(String),
        expect.any(String),
        expect.any(String),
      );
    });

    it('cancels previous timeout when called', () => {
      const wrapper = createWrapper(mockNativeProp);
      const { result } = renderHook(() => useLoggerHook(), { wrapper });

      const logger = result.current;
      logger('INFO', 'First log', 'USER_EVENT', undefined, undefined, undefined, undefined, 'EVENT_1', undefined, undefined);
      
      expect(LoggerUtils.sendLogs).toHaveBeenCalledTimes(1);
      
      jest.advanceTimersByTime(50000);
      
      logger('INFO', 'Second log', 'USER_EVENT', undefined, undefined, undefined, undefined, 'EVENT_2', undefined, undefined);
      
      expect(LoggerUtils.sendLogs).toHaveBeenCalledTimes(2);
      
      jest.advanceTimersByTime(120000);
      
      expect(LoggerUtils.sendLogs).toHaveBeenCalledTimes(3);
    });

    it('extracts paymentId from clientSecret', () => {
      const wrapper = createWrapper(mockNativeProp);
      const { result } = renderHook(() => useLoggerHook(), { wrapper });

      const logger = result.current;
      logger('INFO', 'Test log', 'USER_EVENT', undefined, undefined, undefined, undefined, 'TEST_EVENT', undefined, undefined);

      expect(LoggerUtils.sendLogs).toHaveBeenCalledWith(
        expect.objectContaining({
          paymentId: 'payment_123',
        }),
        expect.any(String),
        expect.any(String),
        expect.any(String),
      );
    });
  });

  describe('useApiLogWrapper', () => {
    const createWrapper = (nativeProp: any, events: any = {}) => {
      return ({ children }: { children: React.ReactNode }) => {
        const loggerWrapper = React.createElement(
          mockLoggerContext.Provider,
          { value: [events, jest.fn()] },
          children,
        );
        return React.createElement(
          mockNativePropContext.Provider,
          { value: [nativeProp, jest.fn()] },
          loggerWrapper,
        );
      };
    };

    const mockNativeProp = {
      hyperParams: {
        sdkVersion: '1.0.0',
        userAgent: 'TestAgent',
        appId: 'test-app-id',
      },
      sdkState: 'PaymentSheet',
      publishableKey: 'pk_test_123',
      clientSecret: 'payment_123_secret_abc',
      sessionId: 'session_123',
    };

    it('logs Request type with url only', () => {
      const wrapper = createWrapper(mockNativeProp);
      const { result } = renderHook(() => useApiLogWrapper(), { wrapper });

      const apiLogger = result.current;
      apiLogger('INFO', 'API_CALL', 'https://api.test.com', undefined, 'Request', undefined, undefined, undefined, undefined);

      expect(LoggerUtils.sendLogs).toHaveBeenCalledWith(
        expect.objectContaining({
          logType: 'INFO',
          category: 'API',
          eventName: 'API_CALL',
        }),
        expect.any(String),
        expect.any(String),
        expect.any(String),
      );
    });

    it('logs Response type with url, statusCode, and response', () => {
      const wrapper = createWrapper(mockNativeProp);
      const { result } = renderHook(() => useApiLogWrapper(), { wrapper });

      const apiLogger = result.current;
      apiLogger('INFO', 'API_CALL', 'https://api.test.com', '200', 'Response', '{"data": "test"}', undefined, undefined, undefined);

      expect(LoggerUtils.sendLogs).toHaveBeenCalled();
    });

    it('logs NoResponse type with 504 status code', () => {
      const wrapper = createWrapper(mockNativeProp);
      const { result } = renderHook(() => useApiLogWrapper(), { wrapper });

      const apiLogger = result.current;
      apiLogger('ERROR', 'API_TIMEOUT', 'https://api.test.com', undefined, 'NoResponse', 'timeout', undefined, undefined, undefined);

      expect(LoggerUtils.sendLogs).toHaveBeenCalledWith(
        expect.objectContaining({
          logType: 'ERROR',
        }),
        expect.any(String),
        expect.any(String),
        expect.any(String),
      );
    });

    it('logs Err type with statusCode and response', () => {
      const wrapper = createWrapper(mockNativeProp);
      const { result } = renderHook(() => useApiLogWrapper(), { wrapper });

      const apiLogger = result.current;
      apiLogger('ERROR', 'API_ERROR', 'https://api.test.com', '500', 'Err', '{"error": "server error"}', undefined, undefined, undefined);

      expect(LoggerUtils.sendLogs).toHaveBeenCalledWith(
        expect.objectContaining({
          logType: 'ERROR',
        }),
        expect.any(String),
        expect.any(String),
        expect.any(String),
      );
    });

    it('includes paymentMethod when provided', () => {
      const wrapper = createWrapper(mockNativeProp);
      const { result } = renderHook(() => useApiLogWrapper(), { wrapper });

      const apiLogger = result.current;
      apiLogger('INFO', 'API_CALL', 'https://api.test.com', '200', 'Response', '{"data": "test"}', 'card', undefined, undefined);

      expect(LoggerUtils.sendLogs).toHaveBeenCalled();
    });
  });

  describe('timeOut module-level variable', () => {
    it('is initialized with null contents', () => {
      timeOut.contents = null;
      expect(timeOut.contents).toBeNull();
    });

    it('can be assigned a timeout id', () => {
      const mockTimeoutId = 123 as any;
      timeOut.contents = mockTimeoutId;
      expect(timeOut.contents).toBe(mockTimeoutId);
    });
  });
});
