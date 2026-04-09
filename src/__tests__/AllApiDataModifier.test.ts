import { renderHook } from '@testing-library/react-native';
import React from 'react';
import ReactNative from 'react-native';

jest.mock('../hooks/WebKit.bs.js', () => ({
  platform: 'web',
  platformString: 'web',
}));

jest.mock('../hooks/SamsungPay.bs.js', () => ({
  useSamsungPayValidityHook: jest.fn(() => 'Valid'),
}));

jest.mock('../components/modules/SamsungPayModule.bs.js', () => ({
  isAvailable: true,
}));

jest.mock('../components/modules/PaypalModule.bs.js', () => ({
  payPalModule: undefined,
}));

jest.mock('../hooks/WebButtonHook.bs.js', () => ({
  usePayButton: jest.fn(() => [
    jest.fn(),
    jest.fn(),
  ]),
}));

jest.mock('../utility/logics/Utils.bs.js', () => ({
  getHeader: jest.fn(() => ({ 'Content-Type': 'application/json' })),
  getObj: jest.fn(() => ({})),
  getOptionString: jest.fn(() => undefined),
  getString: jest.fn(() => ''),
  getBool: jest.fn(() => false),
}));

jest.mock('../../shared-code/sdk-utils/utils/CommonUtils.bs.js', () => ({
  getDisplayName: jest.fn((type) => type || 'Payment Method'),
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
    configuration: {
      displayMergedSavedMethods: false,
      merchantDisplayName: 'Test Merchant',
    },
    env: 'sandbox',
    sdkState: 'PaymentSheet',
    rootTag: 1,
    hyperParams: { appId: 'test-app', country: 'US', sdkVersion: '1.0.0' },
    customParams: {},
  })),
  sdkStateToStrMapper: jest.fn(() => 'PAYMENT_SHEET'),
  defaultAppearance: {},
  defaultButtonElementArr: ['apple_pay', 'google_pay', 'paypal'],
}));

jest.mock('../types/Types.bs.js', () => ({
  defaultButtonElementArr: ['apple_pay', 'google_pay', 'paypal'],
  priorityArr: ['apple_pay', 'google_pay', 'paypal', 'credit'],
}));

jest.mock('../types/AllApiDataTypes/SessionsType.bs.js', () => ({
  defaultToken: {
    wallet_name: 'NONE',
    session_token: '',
    session_id: '',
    connector: '',
  },
  getWallet: jest.fn(() => 'NONE'),
}));

jest.mock('../components/common/Space.bs.js', () => ({
  make: jest.fn(() => null),
}));

jest.mock('../components/common/CustomLoader/CustomLoader.bs.js', () => ({
  make: jest.fn(() => null),
}));

jest.mock('../pages/payment/PaymentMethod.bs.js', () => ({
  make: jest.fn(() => null),
}));

jest.mock('../pages/payment/SavedPaymentSheet.bs.js', () => ({
  make: jest.fn(() => null),
}));

jest.mock('react-native', () => ({
  Platform: { OS: 'web' },
  Animated: {
    Value: jest.fn().mockImplementation((initialValue: number) => ({
      _value: initialValue,
      setValue: jest.fn(),
    })),
  },
  StyleSheet: {
    create: jest.fn((styles) => styles),
    hairlineWidth: 1,
  },
  View: 'View',
  Text: 'Text',
  Image: 'Image',
}));

const mockNativePropContext = React.createContext([{}, jest.fn()]);
const mockAllApiDataContext = React.createContext([undefined, undefined, undefined]);

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
  useAccountPaymentMethodModifier,
  useAddWebPaymentButton,
  useWidgetListModifier
} = require('../hooks/AllApiDataModifier.bs.js');

describe('AllApiDataModifier', () => {
  describe('useAccountPaymentMethodModifier', () => {
    const createWrapper = (nativeProp: any, accountData: any, customerData: any, sessionData: any) => {
      return ({ children }: { children: React.ReactNode }) => {
        return React.createElement(
          mockNativePropContext.Provider,
          { value: [nativeProp, jest.fn()] as any },
          React.createElement(
            mockAllApiDataContext.Provider,
            { value: [accountData, customerData, sessionData] as any },
            children,
          ),
        );
      };
    };

    it('returns array structure when accountPaymentMethodData is undefined', () => {
      const nativeProp = createMockNativeProp();
      const wrapper = createWrapper(nativeProp, undefined, undefined, undefined);
      
      const { result } = renderHook(() => useAccountPaymentMethodModifier(), { wrapper });
      
      expect(result.current).toBeDefined();
      expect(Array.isArray(result.current)).toBe(true);
    });

    it('returns loading elements when sdkState is PaymentSheet and no account data', () => {
      const nativeProp = createMockNativeProp({ sdkState: 'PaymentSheet' });
      const wrapper = createWrapper(nativeProp, undefined, undefined, undefined);
      
      const { result } = renderHook(() => useAccountPaymentMethodModifier(), { wrapper });
      
      expect(result.current).toBeDefined();
      expect(Array.isArray(result.current)).toBe(true);
      expect(result.current.length).toBe(3);
    });

    it('returns empty arrays when sdkState is an object (CustomWidget)', () => {
      const nativeProp = createMockNativeProp({ sdkState: { TAG: 'CustomWidget', _0: 'GOOGLE_PAY' } });
      const wrapper = createWrapper(nativeProp, undefined, undefined, undefined);
      
      const { result } = renderHook(() => useAccountPaymentMethodModifier(), { wrapper });
      
      expect(result.current).toBeDefined();
      expect(result.current).toEqual([[], [], []]);
    });

    it('returns empty arrays when sdkState is NoView', () => {
      const nativeProp = createMockNativeProp({ sdkState: 'NoView' });
      const wrapper = createWrapper(nativeProp, undefined, undefined, undefined);
      
      const { result } = renderHook(() => useAccountPaymentMethodModifier(), { wrapper });
      
      expect(result.current).toBeDefined();
      expect(result.current).toEqual([[], [], []]);
    });

    it('returns loading tab elements when sdkState is TabSheet', () => {
      const nativeProp = createMockNativeProp({ sdkState: 'TabSheet' });
      const wrapper = createWrapper(nativeProp, undefined, undefined, undefined);
      
      const { result } = renderHook(() => useAccountPaymentMethodModifier(), { wrapper });
      
      expect(result.current).toBeDefined();
      expect(Array.isArray(result.current[0])).toBe(true);
      expect(result.current[0].length).toBe(4);
    });

    it('returns loading elements when sdkState is ButtonSheet', () => {
      const nativeProp = createMockNativeProp({ sdkState: 'ButtonSheet' });
      const wrapper = createWrapper(nativeProp, undefined, undefined, undefined);
      
      const { result } = renderHook(() => useAccountPaymentMethodModifier(), { wrapper });
      
      expect(result.current).toBeDefined();
      expect(Array.isArray(result.current[1])).toBe(true);
      expect(result.current[1].length).toBeGreaterThan(0);
    });

    it('handles accountPaymentMethodData with empty payment_methods array', () => {
      const nativeProp = createMockNativeProp({ sdkState: 'PaymentSheet' });
      const accountData = { payment_methods: [], merchant_name: 'Test Merchant' };
      const wrapper = createWrapper(nativeProp, accountData, undefined, undefined);
      
      const { result } = renderHook(() => useAccountPaymentMethodModifier(), { wrapper });
      
      expect(result.current).toBeDefined();
      expect(Array.isArray(result.current)).toBe(true);
    });

    it('handles Headless sdkState returning empty arrays', () => {
      const nativeProp = createMockNativeProp({ sdkState: 'Headless' });
      const wrapper = createWrapper(nativeProp, undefined, undefined, undefined);
      
      const { result } = renderHook(() => useAccountPaymentMethodModifier(), { wrapper });
      
      expect(result.current).toBeDefined();
      expect(result.current).toEqual([[], [], []]);
    });

    it('handles WidgetPaymentSheet sdkState', () => {
      const nativeProp = createMockNativeProp({ sdkState: 'WidgetPaymentSheet' });
      const wrapper = createWrapper(nativeProp, undefined, undefined, undefined);
      
      const { result } = renderHook(() => useAccountPaymentMethodModifier(), { wrapper });
      
      expect(result.current).toBeDefined();
      expect(Array.isArray(result.current)).toBe(true);
    });

    it('handles HostedCheckout sdkState', () => {
      const nativeProp = createMockNativeProp({ sdkState: 'HostedCheckout' });
      const wrapper = createWrapper(nativeProp, undefined, undefined, undefined);
      
      const { result } = renderHook(() => useAccountPaymentMethodModifier(), { wrapper });
      
      expect(result.current).toBeDefined();
      expect(Array.isArray(result.current)).toBe(true);
    });

    it('processes GOOGLE_PAY payment method in PaymentSheet', () => {
      const nativeProp = createMockNativeProp({ sdkState: 'PaymentSheet' });
      const accountData = {
        payment_methods: [{
          payment_method_type: 'google_pay',
          payment_method_type_wallet: 'GOOGLE_PAY',
          payment_method: 'WALLET',
          payment_experience: [{ payment_experience_type_decode: 'INVOKE_SDK_CLIENT' }],
        }],
        merchant_name: 'Test Merchant',
      };
      const sessionData = [{
        wallet_name: 'GOOGLE_PAY',
        session_token: 'token123',
        connector: 'stripe',
      }];
      const wrapper = createWrapper(nativeProp, accountData, undefined, sessionData);
      
      const { result } = renderHook(() => useAccountPaymentMethodModifier(), { wrapper });
      
      expect(result.current).toBeDefined();
      expect(Array.isArray(result.current)).toBe(true);
    });

    it('processes APPLE_PAY payment method in PaymentSheet', () => {
      const nativeProp = createMockNativeProp({ sdkState: 'PaymentSheet' });
      const accountData = {
        payment_methods: [{
          payment_method_type: 'apple_pay',
          payment_method_type_wallet: 'APPLE_PAY',
          payment_method: 'WALLET',
          payment_experience: [{ payment_experience_type_decode: 'INVOKE_SDK_CLIENT' }],
        }],
        merchant_name: 'Test Merchant',
      };
      const sessionData = [{
        wallet_name: 'APPLE_PAY',
        session_token: 'token123',
        connector: 'stripe',
      }];
      const wrapper = createWrapper(nativeProp, accountData, undefined, sessionData);
      
      const { result } = renderHook(() => useAccountPaymentMethodModifier(), { wrapper });
      
      expect(result.current).toBeDefined();
      expect(Array.isArray(result.current)).toBe(true);
    });

    it('processes PAYPAL payment method with INVOKE_SDK_CLIENT experience', () => {
      const nativeProp = createMockNativeProp({ sdkState: 'PaymentSheet' });
      const accountData = {
        payment_methods: [{
          payment_method_type: 'paypal',
          payment_method_type_wallet: 'PAYPAL',
          payment_method: 'WALLET',
          payment_experience: [{ payment_experience_type_decode: 'INVOKE_SDK_CLIENT' }],
        }],
        merchant_name: 'Test Merchant',
      };
      const wrapper = createWrapper(nativeProp, accountData, undefined, undefined);
      
      const { result } = renderHook(() => useAccountPaymentMethodModifier(), { wrapper });
      
      expect(result.current).toBeDefined();
      expect(Array.isArray(result.current)).toBe(true);
    });

    it('processes PAYPAL payment method with REDIRECT_TO_URL experience', () => {
      const nativeProp = createMockNativeProp({ sdkState: 'PaymentSheet' });
      const accountData = {
        payment_methods: [{
          payment_method_type: 'paypal',
          payment_method_type_wallet: 'PAYPAL',
          payment_method: 'WALLET',
          payment_experience: [{ payment_experience_type_decode: 'REDIRECT_TO_URL' }],
        }],
        merchant_name: 'Test Merchant',
      };
      const wrapper = createWrapper(nativeProp, accountData, undefined, undefined);
      
      const { result } = renderHook(() => useAccountPaymentMethodModifier(), { wrapper });
      
      expect(result.current).toBeDefined();
    });

    it('processes SAMSUNG_PAY payment method', () => {
      const nativeProp = createMockNativeProp({ sdkState: 'PaymentSheet' });
      const accountData = {
        payment_methods: [{
          payment_method_type: 'samsung_pay',
          payment_method_type_wallet: 'SAMSUNG_PAY',
          payment_method: 'WALLET',
          payment_experience: [{ payment_experience_type_decode: 'INVOKE_SDK_CLIENT' }],
        }],
        merchant_name: 'Test Merchant',
      };
      const wrapper = createWrapper(nativeProp, accountData, undefined, undefined);
      
      const { result } = renderHook(() => useAccountPaymentMethodModifier(), { wrapper });
      
      expect(result.current).toBeDefined();
    });

    it('processes GIFT_CARD payment method', () => {
      const nativeProp = createMockNativeProp({ sdkState: 'PaymentSheet' });
      const accountData = {
        payment_methods: [{
          payment_method_type: 'gift_card',
          payment_method_type_wallet: 'NONE',
          payment_method: 'GIFT_CARD',
          payment_experience: [],
        }],
        merchant_name: 'Test Merchant',
      };
      const wrapper = createWrapper(nativeProp, accountData, undefined, undefined);
      
      const { result } = renderHook(() => useAccountPaymentMethodModifier(), { wrapper });
      
      expect(result.current).toBeDefined();
      expect(result.current[2].length).toBe(1);
    });

    it('processes CARD_REDIRECT payment method', () => {
      const nativeProp = createMockNativeProp({ sdkState: 'PaymentSheet' });
      const accountData = {
        payment_methods: [{
          payment_method_type: 'card_redirect',
          payment_method_type_wallet: 'NONE',
          payment_method: 'CARD_REDIRECT',
          payment_experience: [],
        }],
        merchant_name: 'Test Merchant',
      };
      const wrapper = createWrapper(nativeProp, accountData, undefined, undefined);
      
      const { result } = renderHook(() => useAccountPaymentMethodModifier(), { wrapper });
      
      expect(result.current).toBeDefined();
    });

    it('processes payment method with NONE wallet and non-wallet payment method', () => {
      const nativeProp = createMockNativeProp({ sdkState: 'PaymentSheet' });
      const accountData = {
        payment_methods: [{
          payment_method_type: 'credit',
          payment_method_type_wallet: 'NONE',
          payment_method: 'CARD',
          payment_experience: [],
        }],
        merchant_name: 'Test Merchant',
      };
      const wrapper = createWrapper(nativeProp, accountData, undefined, undefined);
      
      const { result } = renderHook(() => useAccountPaymentMethodModifier(), { wrapper });
      
      expect(result.current).toBeDefined();
    });

    it('handles displayMergedSavedMethods with customer payment methods', () => {
      const nativeProp = createMockNativeProp({
        sdkState: 'PaymentSheet',
        configuration: {
          ...createMockNativeProp().configuration,
          displayMergedSavedMethods: true,
        },
      });
      const accountData = {
        payment_methods: [],
        merchant_name: 'Test Merchant',
      };
      const customerData = {
        customer_payment_methods: [{
          payment_method: 'CARD',
          payment_method_type: 'credit',
        }],
      };
      const wrapper = createWrapper(nativeProp, accountData, customerData, undefined);
      
      const { result } = renderHook(() => useAccountPaymentMethodModifier(), { wrapper });
      
      expect(result.current).toBeDefined();
      expect(Array.isArray(result.current)).toBe(true);
    });

    it('handles displayMergedSavedMethods with WALLET customer payment methods', () => {
      const nativeProp = createMockNativeProp({
        sdkState: 'PaymentSheet',
        configuration: {
          ...createMockNativeProp().configuration,
          displayMergedSavedMethods: true,
        },
      });
      const accountData = {
        payment_methods: [],
        merchant_name: 'Test Merchant',
      };
      const customerData = {
        customer_payment_methods: [{
          payment_method: 'WALLET',
          payment_method_type: 'google_pay',
        }],
      };
      const wrapper = createWrapper(nativeProp, accountData, customerData, undefined);
      
      const { result } = renderHook(() => useAccountPaymentMethodModifier(), { wrapper });
      
      expect(result.current).toBeDefined();
    });

    it('handles WidgetButtonSheet sdkState', () => {
      const nativeProp = createMockNativeProp({ sdkState: 'WidgetButtonSheet' });
      const wrapper = createWrapper(nativeProp, undefined, undefined, undefined);
      
      const { result } = renderHook(() => useAccountPaymentMethodModifier(), { wrapper });
      
      expect(result.current).toBeDefined();
      expect(Array.isArray(result.current[1])).toBe(true);
      expect(result.current[1].length).toBeGreaterThan(0);
    });

    it('handles WidgetTabSheet sdkState', () => {
      const nativeProp = createMockNativeProp({ sdkState: 'WidgetTabSheet' });
      const wrapper = createWrapper(nativeProp, undefined, undefined, undefined);
      
      const { result } = renderHook(() => useAccountPaymentMethodModifier(), { wrapper });
      
      expect(result.current).toBeDefined();
      expect(Array.isArray(result.current[0])).toBe(true);
    });
  });

  describe('useAddWebPaymentButton', () => {
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

    it('does not throw when called', () => {
      const nativeProp = createMockNativeProp();
      const wrapper = createWrapper(nativeProp, undefined);
      
      expect(() => {
        renderHook(() => useAddWebPaymentButton(), { wrapper });
      }).not.toThrow();
    });

    it('returns undefined (no return value)', () => {
      const nativeProp = createMockNativeProp();
      const wrapper = createWrapper(nativeProp, undefined);
      
      const { result } = renderHook(() => useAddWebPaymentButton(), { wrapper });
      expect(result.current).toBeUndefined();
    });

    it('handles accountPaymentMethodData with payment methods', () => {
      const nativeProp = createMockNativeProp();
      const accountData = {
        payment_methods: [{
          payment_method_type: 'google_pay',
          payment_method_type_wallet: 'GOOGLE_PAY',
          payment_method: 'WALLET',
          payment_experience: [{ payment_experience_type_decode: 'INVOKE_SDK_CLIENT' }],
        }],
      };
      const wrapper = createWrapper(nativeProp, accountData);
      
      const { result } = renderHook(() => useAddWebPaymentButton(), { wrapper });
      expect(result.current).toBeUndefined();
    });
  });

  describe('useWidgetListModifier', () => {
    it('returns undefined (empty function)', () => {
      const { result } = renderHook(() => useWidgetListModifier());
      expect(result.current).toBeUndefined();
    });

    it('does not throw when called', () => {
      expect(() => {
        renderHook(() => useWidgetListModifier());
      }).not.toThrow();
    });

    it('returns same undefined value on multiple calls', () => {
      const { result, rerender } = renderHook(() => useWidgetListModifier());
      const firstResult = result.current;
      rerender();
      expect(result.current).toBe(firstResult);
    });
  });
});
