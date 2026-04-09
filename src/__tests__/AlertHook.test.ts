import { renderHook, act } from '@testing-library/react-native';
import { useAlerts } from '../hooks/AlertHook.bs.js';

jest.mock('react-native', () => ({
  Platform: {
    OS: 'ios',
  },
  Alert: {
    alert: jest.fn(),
  },
  ToastAndroid: {
    show: jest.fn(),
    LONG: 'LONG',
  },
}));

jest.mock('../hooks/AllPaymentHooks.bs.js', () => ({
  useHandleSuccessFailure: jest.fn(),
}));

const mockHandleSuccessFailure = jest.fn();

beforeEach(() => {
  jest.clearAllMocks();
  (require('../hooks/AllPaymentHooks.bs.js').useHandleSuccessFailure as jest.Mock).mockReturnValue(mockHandleSuccessFailure);
});

describe('AlertHook', () => {
  describe('useAlerts', () => {
    it('returns a function that handles error type "error"', () => {
      const { result } = renderHook(() => useAlerts());

      const alertFn = result.current;

      act(() => {
        alertFn('error', 'Test error message');
      });

      expect(mockHandleSuccessFailure).toHaveBeenCalledWith(
        {
          message: 'Test error message',
          code: '',
          type_: '',
          status: 'failed',
        },
        undefined,
        undefined,
        undefined,
      );
    });

    it('returns a function that handles error type "warning" on iOS', () => {
      const ReactNative = require('react-native');

      const { result } = renderHook(() => useAlerts());

      act(() => {
        result.current('warning', 'Test warning message');
      });

      expect(ReactNative.Alert.alert).toHaveBeenCalledWith('Warning', 'Test warning message');
      expect(mockHandleSuccessFailure).not.toHaveBeenCalled();
    });

    it('constructs apiResStatus object with correct properties for error type', () => {
      const { result } = renderHook(() => useAlerts());

      act(() => {
        result.current('error', 'Payment failed');
      });

      const callArgs = mockHandleSuccessFailure.mock.calls[0][0];
      expect(callArgs).toEqual({
        message: 'Payment failed',
        code: '',
        type_: '',
        status: 'failed',
      });
    });

    it('handles empty message string for error type', () => {
      const { result } = renderHook(() => useAlerts());

      act(() => {
        result.current('error', '');
      });

      expect(mockHandleSuccessFailure).toHaveBeenCalledWith(
        expect.objectContaining({
          message: '',
          status: 'failed',
        }),
        undefined,
        undefined,
        undefined,
      );
    });

    it('handles long error message for error type', () => {
      const { result } = renderHook(() => useAlerts());

      const longMessage = 'A'.repeat(1000);

      act(() => {
        result.current('error', longMessage);
      });

      expect(mockHandleSuccessFailure).toHaveBeenCalledWith(
        expect.objectContaining({
          message: longMessage,
        }),
        undefined,
        undefined,
        undefined,
      );
    });

    it('handles special characters in message', () => {
      const { result } = renderHook(() => useAlerts());

      act(() => {
        result.current('error', 'Error: "invalid" <data> & more');
      });

      expect(mockHandleSuccessFailure).toHaveBeenCalledWith(
        expect.objectContaining({
          message: 'Error: "invalid" <data> & more',
        }),
        undefined,
        undefined,
        undefined,
      );
    });
  });

  describe('useAlerts - platform-specific warning behavior', () => {
    it('calls Alert.alert on iOS for warning type', () => {
      const ReactNative = require('react-native');
      ReactNative.Platform.OS = 'ios';

      const { result } = renderHook(() => useAlerts());

      act(() => {
        result.current('warning', 'iOS warning');
      });

      expect(ReactNative.Alert.alert).toHaveBeenCalledWith('Warning', 'iOS warning');
    });

    it('calls alert() on web platform for warning type', () => {
      const ReactNative = require('react-native');
      ReactNative.Platform.OS = 'web';

      const originalAlert = global.alert;
      global.alert = jest.fn();

      const { result } = renderHook(() => useAlerts());

      act(() => {
        result.current('warning', 'Web warning');
      });

      expect(global.alert).toHaveBeenCalledWith('Web warning');

      global.alert = originalAlert;
      ReactNative.Platform.OS = 'ios';
    });

    it('calls ToastAndroid.show on Android for warning type', () => {
      const ReactNative = require('react-native');
      ReactNative.Platform.OS = 'android';

      const { result } = renderHook(() => useAlerts());

      act(() => {
        result.current('warning', 'Android warning');
      });

      expect(ReactNative.ToastAndroid.show).toHaveBeenCalledWith('Android warning', ReactNative.ToastAndroid.LONG);

      ReactNative.Platform.OS = 'ios';
    });
  });

  describe('useAlerts - default case (unknown error type)', () => {
    it('logs to console.error for unknown error type', () => {
      const consoleSpy = jest.spyOn(console, 'error').mockImplementation();

      const { result } = renderHook(() => useAlerts());

      act(() => {
        result.current('unknown', 'Unknown error type');
      });

      expect(consoleSpy).toHaveBeenCalledWith('Unknown error type');
      expect(mockHandleSuccessFailure).not.toHaveBeenCalled();

      consoleSpy.mockRestore();
    });

    it('logs to console.error for empty string error type', () => {
      const consoleSpy = jest.spyOn(console, 'error').mockImplementation();

      const { result } = renderHook(() => useAlerts());

      act(() => {
        result.current('', 'Empty error type');
      });

      expect(consoleSpy).toHaveBeenCalledWith('Empty error type');

      consoleSpy.mockRestore();
    });
  });
});
