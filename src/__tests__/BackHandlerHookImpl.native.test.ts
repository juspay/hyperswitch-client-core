import { renderHook } from '@testing-library/react-native';

const mockHandleSuccessFailure = jest.fn();
const mockBackHandlerRemove = jest.fn();
const mockBackHandlerAddEventListener = jest.fn(() => ({ remove: mockBackHandlerRemove }));

jest.mock('react-native', () => ({
  BackHandler: {
    addEventListener: jest.fn(() => ({ remove: jest.fn() })),
  },
}));

jest.mock('../hooks/AllPaymentHooks.bs.js', () => ({
  useHandleSuccessFailure: jest.fn(),
}));

jest.mock('../types/AllApiDataTypes/PaymentConfirmTypes.bs.js', () => ({
  defaultCancelError: {
    message: '',
    code: '',
    type_: '',
    status: 'cancelled',
  },
}));

const { useBackHandler } = require('../hooks/BackHandlerHook/BackHandlerHookImpl.native.bs.js');
const ReactNative = require('react-native');

describe('BackHandlerHookImpl.native', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    (ReactNative.BackHandler.addEventListener as jest.Mock).mockReturnValue({ remove: mockBackHandlerRemove });
    (require('../hooks/AllPaymentHooks.bs.js').useHandleSuccessFailure as jest.Mock).mockReturnValue(mockHandleSuccessFailure);
  });

  describe('useBackHandler', () => {
    it('registers hardware back press listener on mount', () => {
      renderHook(() => useBackHandler('FillingDetails', 'PaymentSheet'));

      expect(ReactNative.BackHandler.addEventListener).toHaveBeenCalledWith(
        'hardwareBackPress',
        expect.any(Function)
      );
      expect(ReactNative.BackHandler.addEventListener).toHaveBeenCalledTimes(1);
    });

    it('removes back handler on unmount', () => {
      const { unmount } = renderHook(() => useBackHandler('FillingDetails', 'PaymentSheet'));

      expect(mockBackHandlerRemove).not.toHaveBeenCalled();

      unmount();

      expect(mockBackHandlerRemove).toHaveBeenCalledTimes(1);
    });

    it('calls handleSuccessFailure with cancel error when sdkState is PaymentSheet and back pressed', () => {
      renderHook(() => useBackHandler('FillingDetails', 'PaymentSheet'));

      const backHandlerCallback = (ReactNative.BackHandler.addEventListener as jest.Mock).mock.calls[0][1];
      
      const result = backHandlerCallback();

      expect(result).toBe(true);
      expect(mockHandleSuccessFailure).toHaveBeenCalledWith(
        { message: '', code: '', type_: '', status: 'cancelled' },
        true,
        false,
        undefined
      );
    });

    it('calls handleSuccessFailure with cancel error when sdkState is HostedCheckout and back pressed', () => {
      renderHook(() => useBackHandler('FillingDetails', 'HostedCheckout'));

      const backHandlerCallback = (ReactNative.BackHandler.addEventListener as jest.Mock).mock.calls[0][1];
      
      const result = backHandlerCallback();

      expect(result).toBe(true);
      expect(mockHandleSuccessFailure).toHaveBeenCalledWith(
        { message: '', code: '', type_: '', status: 'cancelled' },
        true,
        false,
        undefined
      );
    });

    it('does not call handleSuccessFailure when loading is ProcessingPayments', () => {
      renderHook(() => useBackHandler('ProcessingPayments', 'PaymentSheet'));

      const backHandlerCallback = (ReactNative.BackHandler.addEventListener as jest.Mock).mock.calls[0][1];
      
      const result = backHandlerCallback();

      expect(result).toBe(true);
      expect(mockHandleSuccessFailure).not.toHaveBeenCalled();
    });

    it('does not call handleSuccessFailure when loading is ProcessingPaymentsWithOverlay', () => {
      renderHook(() => useBackHandler('ProcessingPaymentsWithOverlay', 'HostedCheckout'));

      const backHandlerCallback = (ReactNative.BackHandler.addEventListener as jest.Mock).mock.calls[0][1];
      
      const result = backHandlerCallback();

      expect(result).toBe(true);
      expect(mockHandleSuccessFailure).not.toHaveBeenCalled();
    });

    it('does not call handleSuccessFailure when sdkState is neither PaymentSheet nor HostedCheckout', () => {
      renderHook(() => useBackHandler('FillingDetails', 'Headless'));

      const backHandlerCallback = (ReactNative.BackHandler.addEventListener as jest.Mock).mock.calls[0][1];
      
      const result = backHandlerCallback();

      expect(result).toBe(true);
      expect(mockHandleSuccessFailure).not.toHaveBeenCalled();
    });

    it('re-registers listener when loading state changes', () => {
      const { rerender } = renderHook(
        ({ loading, sdkState }) => useBackHandler(loading, sdkState),
        { initialProps: { loading: 'FillingDetails', sdkState: 'PaymentSheet' } }
      );

      expect(ReactNative.BackHandler.addEventListener).toHaveBeenCalledTimes(1);

      rerender({ loading: 'ProcessingPayments', sdkState: 'PaymentSheet' });

      expect(mockBackHandlerRemove).toHaveBeenCalledTimes(1);
      expect(ReactNative.BackHandler.addEventListener).toHaveBeenCalledTimes(2);
    });

    it('re-registers listener when sdkState changes', () => {
      const { rerender } = renderHook(
        ({ loading, sdkState }) => useBackHandler(loading, sdkState),
        { initialProps: { loading: 'FillingDetails', sdkState: 'PaymentSheet' } }
      );

      expect(ReactNative.BackHandler.addEventListener).toHaveBeenCalledTimes(1);

      rerender({ loading: 'FillingDetails', sdkState: 'HostedCheckout' });

      expect(mockBackHandlerRemove).toHaveBeenCalledTimes(1);
      expect(ReactNative.BackHandler.addEventListener).toHaveBeenCalledTimes(2);
    });
  });
});
