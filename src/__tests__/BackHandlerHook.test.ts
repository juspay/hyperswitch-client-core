import { renderHook } from '@testing-library/react-native';

const mockUseBackHandlerImpl = jest.fn();

jest.mock('../hooks/BackHandlerHook/BackHandlerHookImpl.native.bs.js', () => ({
  useBackHandler: () => mockUseBackHandlerImpl(),
}));

const { useBackHandler } = require('../hooks/BackHandlerHook/BackHandlerHook.bs.js');

describe('BackHandlerHook', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('calls useBackHandler from BackHandlerHookImpl', () => {
    const loading = 'FillingDetails';
    const sdkState = 'PaymentSheet';

    renderHook(() => useBackHandler(loading, sdkState));

    expect(mockUseBackHandlerImpl).toHaveBeenCalled();
  });

  it('passes different loading states to the implementation', () => {
    const loading = 'ProcessingPayments';
    const sdkState = 'HostedCheckout';

    renderHook(() => useBackHandler(loading, sdkState));

    expect(mockUseBackHandlerImpl).toHaveBeenCalled();
  });

  it('handles undefined arguments', () => {
    renderHook(() => useBackHandler(undefined, undefined));

    expect(mockUseBackHandlerImpl).toHaveBeenCalled();
  });
});
