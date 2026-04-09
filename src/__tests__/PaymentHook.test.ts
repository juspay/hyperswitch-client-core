import { renderHook, act } from '@testing-library/react-native';
import React from 'react';

const mockLaunchGPay = jest.fn();
const mockLaunchApplePay = jest.fn();
const mockFetchAndRedirect = jest.fn();

jest.mock('../hooks/WebKit.bs.js', () => ({
  platform: 'web',
  platformString: 'web',
  useWebKit: jest.fn(() => ({
    exitPaymentSheet: jest.fn(),
    sdkInitialised: jest.fn(),
    launchApplePay: mockLaunchApplePay,
    launchGPay: mockLaunchGPay,
  })),
}));

jest.mock('../hooks/LoggerHook.bs.js', () => ({
  useLoggerHook: jest.fn(() => jest.fn()),
}));

jest.mock('../hooks/AlertHook.bs.js', () => ({
  useAlerts: jest.fn(() => jest.fn()),
}));

jest.mock('../hooks/AllPaymentHooks.bs.js', () => ({
  useRedirectHook: jest.fn(() => mockFetchAndRedirect),
}));

jest.mock('../utility/constants/GlobalHooks.bs.js', () => ({
  useGetBaseUrl: jest.fn(() => () => 'https://sandbox.hyperswitch.io'),
}));

jest.mock('../utility/logics/PaymentUtils.bs.js', () => ({
  generateWalletConfirmBody: jest.fn(() => ({ payment_method: 'wallet' })),
  generateSavedCardConfirmBody: jest.fn(() => ({ payment_method: 'card' })),
}));

jest.mock('../components/modules/HyperModule.bs.js', () => ({
  launchGPay: mockLaunchGPay,
  launchApplePay: mockLaunchApplePay,
}));

jest.mock('../types/SdkTypes.bs.js', () => ({
  walletTypeToStrMapper: jest.fn((wallet) => wallet),
}));

jest.mock('../types/WalletType.bs.js', () => ({
  getGpayTokenStringified: jest.fn(() => JSON.stringify({ token: 'gpay_token' })),
}));

jest.mock('../types/AllApiDataTypes/SessionsType.bs.js', () => ({
  defaultToken: {
    session_token_data: 'token_data',
    payment_request_data: 'payment_data',
  },
}));

const mockNativePropContext = React.createContext([{}, jest.fn()]);
const mockLoadingContext = React.createContext(['FillingDetails', jest.fn()]);

jest.mock('../contexts/NativePropContext.bs.js', () => ({
  nativePropContext: mockNativePropContext,
  defaultValue: {},
  defaultSetter: jest.fn(),
  Provider: mockNativePropContext.Provider,
  make: mockNativePropContext.Provider,
}));

jest.mock('../contexts/LoadingContext.bs.js', () => ({
  loadingContext: mockLoadingContext,
  defaultSetter: jest.fn(),
  Provider: mockLoadingContext.Provider,
  make: mockLoadingContext.Provider,
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
  configuration: {},
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

const { usePayment } = require('../hooks/PaymentHook.bs.js');

describe('PaymentHook', () => {
  let mockErrorCallback: jest.Mock;
  let mockResponseCallback: jest.Mock;
  let mockGPayResponseHandler: jest.Mock;
  let mockApplePayResponseHandler: jest.Mock;

  beforeEach(() => {
    jest.clearAllMocks();
    mockErrorCallback = jest.fn();
    mockResponseCallback = jest.fn();
    mockGPayResponseHandler = jest.fn();
    mockApplePayResponseHandler = jest.fn();
  });

  describe('usePayment', () => {
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

    it('returns a function when called', () => {
      const nativeProp = createMockNativeProp();
      const wrapper = createWrapper(nativeProp);

      const { result } = renderHook(() => usePayment(jest.fn(), jest.fn(), '123'), { wrapper });

      expect(result.current).toBeDefined();
      expect(typeof result.current).toBe('function');
    });

    it('returns a function that accepts wallet name and handlers', () => {
      const nativeProp = createMockNativeProp();
      const wrapper = createWrapper(nativeProp);

      const { result } = renderHook(() => usePayment(mockErrorCallback, mockResponseCallback, '123'), { wrapper });

      const paymentFn = result.current;
      expect(() => {
        paymentFn('GOOGLE_PAY', 'token', 'payment_type', mockGPayResponseHandler, mockApplePayResponseHandler, undefined);
      }).not.toThrow();
    });

    it('handles GOOGLE_PAY wallet on web platform', () => {
      const nativeProp = createMockNativeProp();
      const wrapper = createWrapper(nativeProp);

      const { result } = renderHook(() => usePayment(mockErrorCallback, mockResponseCallback, '123'), { wrapper });

      act(() => {
        result.current('GOOGLE_PAY', 'token', 'payment_type', mockGPayResponseHandler, mockApplePayResponseHandler, undefined);
      });

      expect(mockLaunchGPay).toHaveBeenCalled();
    });

    it('handles APPLE_PAY wallet on non-iOS platform', () => {
      const nativeProp = createMockNativeProp();
      const wrapper = createWrapper(nativeProp);

      const { result } = renderHook(() => usePayment(mockErrorCallback, mockResponseCallback, '123'), { wrapper });

      act(() => {
        result.current('APPLE_PAY', 'token', 'payment_type', mockGPayResponseHandler, mockApplePayResponseHandler, undefined);
      });

      expect(mockLaunchApplePay).toHaveBeenCalled();
    });

    it('handles PAYPAL wallet by calling fetchAndRedirect', () => {
      const nativeProp = createMockNativeProp();
      const wrapper = createWrapper(nativeProp);

      const { result } = renderHook(() => usePayment(mockErrorCallback, mockResponseCallback, '123'), { wrapper });

      act(() => {
        result.current('PAYPAL', 'token', 'payment_type', mockGPayResponseHandler, mockApplePayResponseHandler, undefined);
      });

      expect(mockFetchAndRedirect).toHaveBeenCalled();
    });

    it('handles SAMSUNG_PAY wallet by calling fetchAndRedirect', () => {
      const nativeProp = createMockNativeProp();
      const wrapper = createWrapper(nativeProp);

      const { result } = renderHook(() => usePayment(mockErrorCallback, mockResponseCallback, '123'), { wrapper });

      act(() => {
        result.current('SAMSUNG_PAY', 'token', 'payment_type', mockGPayResponseHandler, mockApplePayResponseHandler, undefined);
      });

      expect(mockFetchAndRedirect).toHaveBeenCalled();
    });

    it('handles NONE wallet (saved card) by calling fetchAndRedirect with card type', () => {
      const nativeProp = createMockNativeProp();
      const wrapper = createWrapper(nativeProp);

      const { result } = renderHook(() => usePayment(mockErrorCallback, mockResponseCallback, 'cvv123'), { wrapper });

      act(() => {
        result.current('NONE', 'token', 'payment_type', mockGPayResponseHandler, mockApplePayResponseHandler, undefined);
      });

      expect(mockFetchAndRedirect).toHaveBeenCalled();
      const callArgs = mockFetchAndRedirect.mock.calls[0];
      expect(callArgs[4]).toBe('card');
    });

    it('passes savedCardCvv for NONE wallet type', () => {
      const nativeProp = createMockNativeProp();
      const wrapper = createWrapper(nativeProp);
      const { generateSavedCardConfirmBody } = require('../utility/logics/PaymentUtils.bs.js');

      const { result } = renderHook(() => usePayment(mockErrorCallback, mockResponseCallback, 'cvv123'), { wrapper });

      act(() => {
        result.current('NONE', 'token', 'payment_type', mockGPayResponseHandler, mockApplePayResponseHandler, undefined);
      });

      expect(generateSavedCardConfirmBody).toHaveBeenCalledWith(
        expect.any(Object),
        'token',
        'cvv123',
        'payment_type',
        undefined,
        undefined,
        undefined,
        undefined
      );
    });

    it('passes correct parameters for PAYPAL wallet', () => {
      const nativeProp = createMockNativeProp();
      const wrapper = createWrapper(nativeProp);
      const { generateWalletConfirmBody } = require('../utility/logics/PaymentUtils.bs.js');

      const { result } = renderHook(() => usePayment(mockErrorCallback, mockResponseCallback, '123'), { wrapper });

      act(() => {
        result.current('PAYPAL', 'paypal_token', 'payment_type', mockGPayResponseHandler, mockApplePayResponseHandler, undefined);
      });

      expect(generateWalletConfirmBody).toHaveBeenCalledWith(
        expect.any(Object),
        'paypal_token',
        'PAYPAL',
        'payment_type'
      );
    });

    it('passes correct parameters for SAMSUNG_PAY wallet', () => {
      const nativeProp = createMockNativeProp();
      const wrapper = createWrapper(nativeProp);
      const { generateWalletConfirmBody } = require('../utility/logics/PaymentUtils.bs.js');

      const { result } = renderHook(() => usePayment(mockErrorCallback, mockResponseCallback, '123'), { wrapper });

      act(() => {
        result.current('SAMSUNG_PAY', 'samsung_token', 'payment_type', mockGPayResponseHandler, mockApplePayResponseHandler, undefined);
      });

      expect(generateWalletConfirmBody).toHaveBeenCalledWith(
        expect.any(Object),
        'samsung_token',
        'SAMSUNG_PAY',
        'payment_type'
      );
    });

    it('handles empty payment token for wallet payments', () => {
      const nativeProp = createMockNativeProp();
      const wrapper = createWrapper(nativeProp);

      const { result } = renderHook(() => usePayment(mockErrorCallback, mockResponseCallback, '123'), { wrapper });

      expect(() => {
        result.current('PAYPAL', '', 'payment_type', mockGPayResponseHandler, mockApplePayResponseHandler, undefined);
      }).not.toThrow();
    });

    it('uses nativeProp publishableKey and clientSecret for wallet payments', () => {
      const nativeProp = createMockNativeProp({
        publishableKey: 'pk_custom_key',
        clientSecret: 'custom_secret',
      });
      const wrapper = createWrapper(nativeProp);

      const { result } = renderHook(() => usePayment(mockErrorCallback, mockResponseCallback, '123'), { wrapper });

      act(() => {
        result.current('PAYPAL', 'token', 'payment_type', mockGPayResponseHandler, mockApplePayResponseHandler, undefined);
      });

      expect(mockFetchAndRedirect).toHaveBeenCalledWith(
        expect.any(String),
        'pk_custom_key',
        'custom_secret',
        mockErrorCallback,
        'wallet',
        undefined,
        mockResponseCallback,
        undefined,
        undefined
      );
    });
  });
});
