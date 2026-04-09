import { getFunctionFromModule, dummy, initialise } from '../headless/HeadlessNative.bs.js';
import ReactNative from 'react-native';

jest.mock('react-native', () => ({
  AppRegistry: {
    registerComponent: jest.fn(),
    registerHeadlessTask: jest.fn(),
  },
  NativeModules: {},
  Platform: { OS: 'ios' },
}));

describe('HeadlessNative', () => {
  beforeEach(() => {
    jest.clearAllMocks();
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

  describe('dummy', () => {
    it('returns null for any props', () => {
      expect(dummy({})).toBeNull();
    });

    it('returns null for props with values', () => {
      expect(dummy({ foo: 'bar', nested: { value: 123 } })).toBeNull();
    });

    it('returns null for undefined props', () => {
      expect(dummy(undefined)).toBeNull();
    });
  });

  describe('initialise', () => {
    it('registers component and headless task', () => {
      initialise('HyperHeadless');

      expect(ReactNative.AppRegistry.registerComponent).toHaveBeenCalledWith(
        'dummy',
        expect.any(Function)
      );
      expect(ReactNative.AppRegistry.registerHeadlessTask).toHaveBeenCalledWith(
        'dummy',
        expect.any(Function)
      );
    });

    it('returns object with initialisePaymentSession function', () => {
      const result = initialise('HyperHeadless');

      expect(result).toHaveProperty('initialisePaymentSession');
      expect(typeof result.initialisePaymentSession).toBe('function');
    });

    it('returns object with getPaymentSession function', () => {
      const result = initialise('HyperHeadless');

      expect(result).toHaveProperty('getPaymentSession');
      expect(typeof result.getPaymentSession).toBe('function');
    });

    it('returns object with exitHeadless function', () => {
      const result = initialise('HyperHeadless');

      expect(result).toHaveProperty('exitHeadless');
      expect(typeof result.exitHeadless).toBe('function');
    });

    it('headless task returns promise that resolves', async () => {
      initialise('HyperHeadless');

      const headlessTaskFn = (ReactNative.AppRegistry.registerHeadlessTask as jest.Mock).mock.calls[0][1];
      const task = headlessTaskFn();
      const result = await task({});
      expect(result).toBeUndefined();
    });

    it('registerComponent returns dummy component', () => {
      initialise('HyperHeadless');

      const componentGetter = (ReactNative.AppRegistry.registerComponent as jest.Mock).mock.calls[0][1];
      const component = componentGetter();
      expect(component).toBe(dummy);
    });
  });
});
