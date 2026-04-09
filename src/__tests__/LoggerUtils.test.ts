import {
  eventToStrMapper,
  sdkVersionRef,
  logFileToObj,
  sendLogs,
} from '../utility/logics/LoggerUtils.bs.js';

jest.mock('../hooks/WebKit.bs.js', () => ({
  platform: 'web',
}));

jest.mock('../utility/logics/Utils.bs.js', () => ({
  convertToScreamingSnakeCase: jest.fn((str) => str?.toUpperCase() || ''),
  getHeader: jest.fn(() => ({ 'Content-Type': 'application/json' })),
}));

jest.mock('../utility/logics/APIUtils.bs.js', () => ({
  fetchApi: jest.fn(() => Promise.resolve({
    json: () => Promise.resolve({}),
  })),
}));

jest.mock('@rescript/core/src/Core__Promise.bs.js', () => ({
  $$catch: jest.fn(),
}));

jest.mock('@rescript/core/src/Core__Option.bs.js', () => ({
  getOr: jest.fn((val, defaultVal) => val ?? defaultVal),
}));

describe('LoggerUtils', () => {
  describe('eventToStrMapper', () => {
    it('returns the same event name string', () => {
      expect(eventToStrMapper('PAYMENT_INIT')).toBe('PAYMENT_INIT');
    });

    it('handles empty string', () => {
      expect(eventToStrMapper('')).toBe('');
    });

    it('handles various event types', () => {
      expect(eventToStrMapper('CARD_SUBMITTED')).toBe('CARD_SUBMITTED');
      expect(eventToStrMapper('PAYMENT_SUCCESS')).toBe('PAYMENT_SUCCESS');
      expect(eventToStrMapper('PAYMENT_FAILURE')).toBe('PAYMENT_FAILURE');
    });

    it('preserves case', () => {
      expect(eventToStrMapper('lowercase')).toBe('lowercase');
      expect(eventToStrMapper('MixedCase')).toBe('MixedCase');
    });
  });

  describe('logFileToObj', () => {
    it('converts log file entry to JSON object', () => {
      const logFile = {
        timestamp: '2024-01-01T00:00:00Z',
        logType: 'INFO',
        category: 'API',
        version: '1.0.0',
        codePushVersion: '1.0.1',
        clientCoreVersion: '2.0.0',
        value: 'test value',
        internalMetadata: {},
        sessionId: 'session_123',
        merchantId: 'merchant_123',
        paymentId: 'payment_123',
        appId: 'app_123',
        platform: 'ios',
        userAgent: 'Mozilla/5.0',
        eventName: 'PAYMENT_INIT',
        firstEvent: true,
        paymentMethod: 'card',
        paymentExperience: 'CHECKOUT',
        latency: '100ms',
        source: 'sdk',
      };
      const result = logFileToObj(logFile);
      expect(result.timestamp).toBe('2024-01-01T00:00:00Z');
      expect(result.log_type).toBe('INFO');
      expect(result.category).toBe('API');
      expect(result.component).toBe('MOBILE');
      expect(result.version).toBe('1.0.0');
      expect(result.event_name).toBe('PAYMENT_INIT');
      expect(result.first_event).toBe('true');
      expect(result.platform).toBe('IOS');
      expect(result.payment_method).toBe('CARD');
    });

    it('handles DEBUG log type', () => {
      const logFile = {
        timestamp: '2024-01-01T00:00:00Z',
        logType: 'DEBUG',
        category: 'USER_EVENT',
        version: '1.0.0',
        codePushVersion: '',
        clientCoreVersion: '',
        value: '',
        internalMetadata: {},
        sessionId: '',
        merchantId: '',
        paymentId: '',
        appId: undefined,
        platform: 'android',
        userAgent: '',
        eventName: '',
        firstEvent: false,
        paymentMethod: undefined,
        paymentExperience: undefined,
        latency: undefined,
        source: '',
      };
      const result = logFileToObj(logFile);
      expect(result.log_type).toBe('DEBUG');
      expect(result.category).toBe('USER_EVENT');
      expect(result.first_event).toBe('false');
    });

    it('handles ERROR log type', () => {
      const logFile = {
        timestamp: '',
        logType: 'ERROR',
        category: 'USER_ERROR',
        version: '',
        codePushVersion: '',
        clientCoreVersion: '',
        value: 'error details',
        internalMetadata: {},
        sessionId: '',
        merchantId: '',
        paymentId: '',
        appId: undefined,
        platform: '',
        userAgent: '',
        eventName: 'ERROR_OCCURRED',
        firstEvent: false,
        paymentMethod: undefined,
        paymentExperience: undefined,
        latency: undefined,
        source: '',
      };
      const result = logFileToObj(logFile);
      expect(result.log_type).toBe('ERROR');
      expect(result.category).toBe('USER_ERROR');
    });

    it('handles WARNING log type', () => {
      const logFile = {
        timestamp: '',
        logType: 'WARNING',
        category: 'MERCHANT_EVENT',
        version: '',
        codePushVersion: '',
        clientCoreVersion: '',
        value: '',
        internalMetadata: {},
        sessionId: '',
        merchantId: '',
        paymentId: '',
        appId: undefined,
        platform: '',
        userAgent: '',
        eventName: '',
        firstEvent: false,
        paymentMethod: undefined,
        paymentExperience: undefined,
        latency: undefined,
        source: '',
      };
      const result = logFileToObj(logFile);
      expect(result.log_type).toBe('WARNING');
      expect(result.category).toBe('MERCHANT_EVENT');
    });

    it('handles missing optional fields', () => {
      const logFile = {
        timestamp: '',
        logType: 'INFO',
        category: 'API',
        version: '',
        codePushVersion: '',
        clientCoreVersion: '',
        value: '',
        internalMetadata: {},
        sessionId: '',
        merchantId: '',
        paymentId: '',
        appId: undefined,
        platform: '',
        userAgent: '',
        eventName: '',
        firstEvent: false,
        paymentMethod: undefined,
        paymentExperience: undefined,
        latency: undefined,
        source: '',
      };
      const result = logFileToObj(logFile);
      expect(result.payment_method).toBe('');
      expect(result.payment_experience).toBe('');
      expect(result.latency).toBe('');
    });

    it('converts platform to screaming snake case', () => {
      const logFile = {
        timestamp: '',
        logType: 'INFO',
        category: 'API',
        version: '',
        codePushVersion: '',
        clientCoreVersion: '',
        value: '',
        internalMetadata: {},
        sessionId: '',
        merchantId: '',
        paymentId: '',
        appId: undefined,
        platform: 'ios',
        userAgent: '',
        eventName: '',
        firstEvent: false,
        paymentMethod: undefined,
        paymentExperience: undefined,
        latency: undefined,
        source: '',
      };
      const result = logFileToObj(logFile);
      expect(result.platform).toBe('IOS');
    });
  });

  describe('sdkVersionRef', () => {
    it('has initial value', () => {
      expect(sdkVersionRef).toBeDefined();
      expect(sdkVersionRef.contents).toBe('PACKAGE_JSON_NOT_STARTED');
    });

    it('is a mutable reference object', () => {
      expect(typeof sdkVersionRef).toBe('object');
      expect(sdkVersionRef).toHaveProperty('contents');
    });
  });

  describe('sendLogs', () => {
    const APIUtils = require('../utility/logics/APIUtils.bs.js');
    const CorePromise = require('@rescript/core/src/Core__Promise.bs.js');

    beforeEach(() => {
      jest.clearAllMocks();
    });

    it('does not send logs when platform is next', () => {
      jest.resetModules();
      jest.doMock('../hooks/WebKit.bs.js', () => ({ platform: 'next' }));
      const { sendLogs: sendLogsNext } = require('../utility/logics/LoggerUtils.bs.js');

      const logFile = {
        timestamp: '2024-01-01',
        logType: 'INFO',
        category: 'API',
        version: '1.0.0',
        codePushVersion: '',
        clientCoreVersion: '',
        value: '',
        internalMetadata: {},
        sessionId: '',
        merchantId: '',
        paymentId: '',
        appId: undefined,
        platform: '',
        userAgent: '',
        eventName: '',
        firstEvent: false,
        paymentMethod: undefined,
        paymentExperience: undefined,
        latency: undefined,
        source: '',
      };

      sendLogsNext(logFile, 'https://api.example.com/logs', 'pk_test', 'app_id');
      expect(APIUtils.fetchApi).not.toHaveBeenCalled();
    });

    it('does not send logs when uri is undefined', () => {
      const logFile = {
        timestamp: '2024-01-01',
        logType: 'INFO',
        category: 'API',
        version: '1.0.0',
        codePushVersion: '',
        clientCoreVersion: '',
        value: '',
        internalMetadata: {},
        sessionId: '',
        merchantId: '',
        paymentId: '',
        appId: undefined,
        platform: '',
        userAgent: '',
        eventName: '',
        firstEvent: false,
        paymentMethod: undefined,
        paymentExperience: undefined,
        latency: undefined,
        source: '',
      };

      sendLogs(logFile, undefined, 'pk_test', 'app_id');
      expect(APIUtils.fetchApi).not.toHaveBeenCalled();
    });

    it('does not send logs when uri is empty string', () => {
      const logFile = {
        timestamp: '2024-01-01',
        logType: 'INFO',
        category: 'API',
        version: '1.0.0',
        codePushVersion: '',
        clientCoreVersion: '',
        value: '',
        internalMetadata: {},
        sessionId: '',
        merchantId: '',
        paymentId: '',
        appId: undefined,
        platform: '',
        userAgent: '',
        eventName: '',
        firstEvent: false,
        paymentMethod: undefined,
        paymentExperience: undefined,
        latency: undefined,
        source: '',
      };

      sendLogs(logFile, '', 'pk_test', 'app_id');
      expect(APIUtils.fetchApi).not.toHaveBeenCalled();
    });

    it('sends logs when uri is valid', () => {
      const logFile = {
        timestamp: '2024-01-01T00:00:00Z',
        logType: 'INFO',
        category: 'API',
        version: '1.0.0',
        codePushVersion: '1.0.1',
        clientCoreVersion: '2.0.0',
        value: 'test log',
        internalMetadata: { key: 'value' },
        sessionId: 'session_123',
        merchantId: 'merchant_123',
        paymentId: 'payment_123',
        appId: 'app_123',
        platform: 'web',
        userAgent: 'Mozilla/5.0',
        eventName: 'PAYMENT_INIT',
        firstEvent: true,
        paymentMethod: 'card',
        paymentExperience: 'CHECKOUT',
        latency: '100ms',
        source: 'sdk',
      };

      sendLogs(logFile, 'https://api.example.com/logs', 'pk_test_123', 'app_id_123');

      expect(APIUtils.fetchApi).toHaveBeenCalledWith(
        'https://api.example.com/logs',
        expect.any(String),
        expect.any(Object),
        'POST',
        'no-cors',
        undefined
      );
      expect(CorePromise.$$catch).toHaveBeenCalled();
    });

    it('sends logs with correct JSON data', () => {
      const logFile = {
        timestamp: '2024-01-01',
        logType: 'DEBUG',
        category: 'USER_EVENT',
        version: '1.0.0',
        codePushVersion: '',
        clientCoreVersion: '',
        value: 'debug message',
        internalMetadata: {},
        sessionId: '',
        merchantId: '',
        paymentId: '',
        appId: undefined,
        platform: 'android',
        userAgent: '',
        eventName: 'TEST_EVENT',
        firstEvent: false,
        paymentMethod: undefined,
        paymentExperience: undefined,
        latency: undefined,
        source: 'test',
      };

      sendLogs(logFile, 'https://logs.example.com', 'pk_test', 'app_id');

      const callArgs = APIUtils.fetchApi.mock.calls[0];
      const jsonData = JSON.parse(callArgs[1]);
      expect(jsonData.log_type).toBe('DEBUG');
      expect(jsonData.category).toBe('USER_EVENT');
      expect(jsonData.event_name).toBe('TEST_EVENT');
    });
  });
});
