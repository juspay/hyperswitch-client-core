import { renderHook, act } from '@testing-library/react-native';
import React from 'react';

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

jest.mock('../../shared-code/sdk-utils/hooks/ConfigurationService.bs.js', () => ({
  useConfigurationService: jest.fn(() => () => [[], [], {}]),
}));

jest.mock('../../shared-code/sdk-utils/utils/SuperpositionHelper.bs.js', () => ({
  extractFieldValuesFromPML: jest.fn(() => ({})),
}));

jest.mock('../types/AllApiDataTypes/AccountPaymentMethodType.bs.js', () => ({
  getEligibleConnectorFromCardNetwork: jest.fn(() => []),
  getEligibleConnectorFromPaymentExperience: jest.fn(() => []),
}));

jest.mock('../utility/logics/PaymentUtils.bs.js', () => ({
  getCardNetworks: jest.fn(() => []),
}));

const {
  dynamicFieldsContext,
  make: DynamicFieldsContextProvider,
} = require('../contexts/DynamicFieldsContext.bs.js');

const { defaultCountry } = require('../types/SdkTypes.bs.js');

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

describe('DynamicFieldsContext', () => {
  describe('dynamicFieldsContext', () => {
    it('has default value with expected structure', () => {
      expect(dynamicFieldsContext).toBeDefined();
    });

    it('provides default sheetType as "ButtonSheet"', () => {
      const defaultValue = dynamicFieldsContext._currentValue;
      expect(defaultValue.sheetType).toBe('ButtonSheet');
    });

    it('provides default country as defaultCountry constant', () => {
      const defaultValue = dynamicFieldsContext._currentValue;
      expect(defaultValue.country).toBe(defaultCountry);
    });

    it('provides isNicknameSelected as false by default', () => {
      const defaultValue = dynamicFieldsContext._currentValue;
      expect(defaultValue.isNicknameSelected).toBe(false);
    });

    it('provides isNicknameValid as false by default', () => {
      const defaultValue = dynamicFieldsContext._currentValue;
      expect(defaultValue.isNicknameValid).toBe(false);
    });

    it('provides walletData with expected default structure', () => {
      const defaultValue = dynamicFieldsContext._currentValue;
      expect(defaultValue.walletData).toBeDefined();
      expect(defaultValue.walletData.missingRequiredFields).toEqual([]);
      expect(defaultValue.walletData.initialValues).toEqual({});
      expect(defaultValue.walletData.isCardPayment).toBe(false);
      expect(defaultValue.walletData.enabledCardSchemes).toEqual([]);
    });

    it('provides getRequiredFieldsForTabs function that returns expected structure', () => {
      const defaultValue = dynamicFieldsContext._currentValue;
      const result = defaultValue.getRequiredFieldsForTabs({}, {}, false);
      expect(Array.isArray(result)).toBe(true);
      expect(result).toHaveLength(6);
      expect(Array.isArray(result[0])).toBe(true);
      expect(typeof result[1]).toBe('object');
      expect(typeof result[2]).toBe('boolean');
      expect(Array.isArray(result[3])).toBe(true);
      expect(typeof result[4]).toBe('boolean');
      expect(typeof result[5]).toBe('string');
    });

    it('provides getRequiredFieldsForButton function that returns expected structure', () => {
      const defaultValue = dynamicFieldsContext._currentValue;
      const mockPaymentMethodData = {
        payment_method: 'CARD',
        payment_method_str: 'card',
        payment_method_type: 'debit',
        payment_method_type_wallet: 'NONE',
        card_networks: [],
        bank_names: [],
        payment_experience: [],
        required_fields: {},
      };
      const result = defaultValue.getRequiredFieldsForButton(
        mockPaymentMethodData,
        {},
        undefined,
        undefined,
        false,
        {}
      );
      expect(Array.isArray(result)).toBe(true);
      expect(result).toHaveLength(3);
      expect(typeof result[0]).toBe('boolean');
      expect(typeof result[1]).toBe('object');
      expect(typeof result[2]).toBe('string');
    });

    it('getRequiredFieldsForTabs returns array with empty missingRequiredFields by default', () => {
      const defaultValue = dynamicFieldsContext._currentValue;
      const result = defaultValue.getRequiredFieldsForTabs({}, {}, false);
      expect(result[0]).toEqual([]);
    });

    it('getRequiredFieldsForTabs returns empty initialValues by default', () => {
      const defaultValue = dynamicFieldsContext._currentValue;
      const result = defaultValue.getRequiredFieldsForTabs({}, {}, false);
      expect(result[1]).toEqual({});
    });

    it('getRequiredFieldsForButton returns true for isFieldsMissing by default', () => {
      const defaultValue = dynamicFieldsContext._currentValue;
      const mockPaymentMethodData = {
        payment_method: 'CARD',
        payment_method_str: 'card',
        payment_method_type: 'debit',
        card_networks: [],
        payment_experience: [],
        required_fields: {},
      };
      const result = defaultValue.getRequiredFieldsForButton(
        mockPaymentMethodData,
        {},
        undefined,
        undefined,
        false,
        {}
      );
      expect(result[0]).toBe(true);
    });
  });

  describe('DynamicFieldsContext Provider with real component', () => {
    const createRealWrapper = (nativeProp: any, accountData: any) => {
      return ({ children }: { children: React.ReactNode }) => {
        return React.createElement(
          mockNativePropContext.Provider,
          { value: [nativeProp, jest.fn()] as any },
          React.createElement(
            mockAllApiDataContext.Provider,
            { value: [accountData, undefined, undefined] as any },
            React.createElement(DynamicFieldsContextProvider, {}, children)
          )
        );
      };
    };

    it('provides default sheetType as ButtonSheet', () => {
      const nativeProp = createMockNativeProp();
      const wrapper = createRealWrapper(nativeProp, undefined);

      const { result } = renderHook(() => React.useContext(dynamicFieldsContext), { wrapper });

      expect(result.current.sheetType).toBe('ButtonSheet');
    });

    it('provides country from nativeProp hyperParams', () => {
      const nativeProp = createMockNativeProp({
        hyperParams: { ...createMockNativeProp().hyperParams, country: 'GB' }
      });
      const wrapper = createRealWrapper(nativeProp, undefined);

      const { result } = renderHook(() => React.useContext(dynamicFieldsContext), { wrapper });

      expect(result.current.country).toBe('GB');
    });

    it('provides isNicknameSelected as false initially', () => {
      const nativeProp = createMockNativeProp();
      const wrapper = createRealWrapper(nativeProp, undefined);

      const { result } = renderHook(() => React.useContext(dynamicFieldsContext), { wrapper });

      expect(result.current.isNicknameSelected).toBe(false);
    });

    it('provides isNicknameValid as true initially', () => {
      const nativeProp = createMockNativeProp();
      const wrapper = createRealWrapper(nativeProp, undefined);

      const { result } = renderHook(() => React.useContext(dynamicFieldsContext), { wrapper });

      expect(result.current.isNicknameValid).toBe(true);
    });

    it('provides walletData with default structure', () => {
      const nativeProp = createMockNativeProp();
      const wrapper = createRealWrapper(nativeProp, undefined);

      const { result } = renderHook(() => React.useContext(dynamicFieldsContext), { wrapper });

      expect(result.current.walletData).toBeDefined();
      expect(result.current.walletData.missingRequiredFields).toEqual([]);
      expect(result.current.walletData.initialValues).toEqual({});
      expect(result.current.walletData.isCardPayment).toBe(false);
    });

    it('allows setSheetType to change sheetType', () => {
      const nativeProp = createMockNativeProp();
      const wrapper = createRealWrapper(nativeProp, undefined);

      const { result } = renderHook(() => React.useContext(dynamicFieldsContext), { wrapper });

      act(() => {
        result.current.setSheetType('DynamicFieldsSheet');
      });

      expect(result.current.sheetType).toBe('DynamicFieldsSheet');
    });

    it('allows setCountry to change country', () => {
      const nativeProp = createMockNativeProp();
      const wrapper = createRealWrapper(nativeProp, undefined);

      const { result } = renderHook(() => React.useContext(dynamicFieldsContext), { wrapper });

      act(() => {
        result.current.setCountry('CA');
      });

      expect(result.current.country).toBe('CA');
    });

    it('allows setIsNicknameSelected to change value', () => {
      const nativeProp = createMockNativeProp();
      const wrapper = createRealWrapper(nativeProp, undefined);

      const { result } = renderHook(() => React.useContext(dynamicFieldsContext), { wrapper });

      act(() => {
        result.current.setIsNicknameSelected(true);
      });

      expect(result.current.isNicknameSelected).toBe(true);
    });

    it('allows setNickname to change value', () => {
      const nativeProp = createMockNativeProp();
      const wrapper = createRealWrapper(nativeProp, undefined);

      const { result } = renderHook(() => React.useContext(dynamicFieldsContext), { wrapper });

      act(() => {
        result.current.setNickname('MyCard');
      });

      expect(result.current.nickname).toBe('MyCard');
    });

    it('allows setIsNicknameValid to change value', () => {
      const nativeProp = createMockNativeProp();
      const wrapper = createRealWrapper(nativeProp, undefined);

      const { result } = renderHook(() => React.useContext(dynamicFieldsContext), { wrapper });

      act(() => {
        result.current.setIsNicknameValid(false);
      });

      expect(result.current.isNicknameValid).toBe(false);
    });

    it('resets nickname when isNicknameSelected becomes false', () => {
      const nativeProp = createMockNativeProp();
      const wrapper = createRealWrapper(nativeProp, undefined);

      const { result } = renderHook(() => React.useContext(dynamicFieldsContext), { wrapper });

      act(() => {
        result.current.setNickname('MyCard');
        result.current.setIsNicknameSelected(true);
      });

      expect(result.current.nickname).toBe('MyCard');

      act(() => {
        result.current.setIsNicknameSelected(false);
      });

      expect(result.current.nickname).toBeUndefined();
      expect(result.current.isNicknameValid).toBe(true);
    });

    it('getRequiredFieldsForTabs returns expected structure', () => {
      const nativeProp = createMockNativeProp();
      const wrapper = createRealWrapper(nativeProp, undefined);

      const { result } = renderHook(() => React.useContext(dynamicFieldsContext), { wrapper });

      const paymentMethodData = {
        payment_method: 'CARD',
        payment_method_str: 'card',
        payment_method_type: 'debit',
        payment_method_type_wallet: 'NONE',
        card_networks: [],
        bank_names: [],
        payment_experience: [],
        required_fields: {},
      };

      const fields = result.current.getRequiredFieldsForTabs(paymentMethodData, {}, false);

      expect(Array.isArray(fields)).toBe(true);
      expect(fields.length).toBe(6);
      expect(Array.isArray(fields[0])).toBe(true);
      expect(typeof fields[1]).toBe('object');
      expect(typeof fields[2]).toBe('boolean');
      expect(Array.isArray(fields[3])).toBe(true);
      expect(typeof fields[4]).toBe('boolean');
      expect(typeof fields[5]).toBe('string');
    });

    it('getRequiredFieldsForTabs handles non-CARD payment method', () => {
      const nativeProp = createMockNativeProp();
      const wrapper = createRealWrapper(nativeProp, undefined);

      const { result } = renderHook(() => React.useContext(dynamicFieldsContext), { wrapper });

      const paymentMethodData = {
        payment_method: 'BANK_TRANSFER',
        payment_method_str: 'bank_transfer',
        payment_method_type: 'ach',
        payment_method_type_wallet: 'NONE',
        card_networks: [],
        bank_names: [],
        payment_experience: [],
        required_fields: {},
      };

      const fields = result.current.getRequiredFieldsForTabs(paymentMethodData, {}, true);

      expect(fields[2]).toBe(false);
    });

    it('getRequiredFieldsForButton returns expected structure', () => {
      const nativeProp = createMockNativeProp();
      const wrapper = createRealWrapper(nativeProp, undefined);

      const { result } = renderHook(() => React.useContext(dynamicFieldsContext), { wrapper });

      const paymentMethodData = {
        payment_method: 'CARD',
        payment_method_str: 'card',
        payment_method_type: 'debit',
        payment_method_type_wallet: 'NONE',
        card_networks: [],
        bank_names: [],
        payment_experience: [],
        required_fields: {},
      };

      const fields = result.current.getRequiredFieldsForButton(
        paymentMethodData,
        {},
        undefined,
        undefined,
        false,
        {}
      );

      expect(Array.isArray(fields)).toBe(true);
      expect(fields.length).toBe(3);
      expect(typeof fields[0]).toBe('boolean');
      expect(typeof fields[1]).toBe('object');
      expect(typeof fields[2]).toBe('string');
    });

    it('getRequiredFieldsForButton handles account payment method data', () => {
      const nativeProp = createMockNativeProp();
      const accountData = {
        payment_methods: [],
        merchant_name: 'Test Merchant',
        collect_billing_details_from_wallets: true,
        payment_type: 'NORMAL',
      };
      const wrapper = createRealWrapper(nativeProp, accountData);

      const { result } = renderHook(() => React.useContext(dynamicFieldsContext), { wrapper });

      const paymentMethodData = {
        payment_method: 'CARD',
        payment_method_str: 'card',
        payment_method_type: 'debit',
        payment_method_type_wallet: 'NONE',
        card_networks: [],
        bank_names: [],
        payment_experience: [],
        required_fields: {},
      };

      const fields = result.current.getRequiredFieldsForButton(
        paymentMethodData,
        {},
        undefined,
        undefined,
        false,
        {}
      );

      expect(Array.isArray(fields)).toBe(true);
    });

    it('getRequiredFieldsForButton handles useIntentData true', () => {
      const nativeProp = createMockNativeProp();
      const accountData = {
        payment_methods: [],
        merchant_name: 'Test Merchant',
        collect_billing_details_from_wallets: true,
        payment_type: 'NORMAL',
      };
      const wrapper = createRealWrapper(nativeProp, accountData);

      const { result } = renderHook(() => React.useContext(dynamicFieldsContext), { wrapper });

      const paymentMethodData = {
        payment_method: 'CARD',
        payment_method_str: 'card',
        payment_method_type: 'debit',
        payment_method_type_wallet: 'NONE',
        card_networks: [],
        bank_names: [],
        payment_experience: [],
        required_fields: {},
      };

      const fields = result.current.getRequiredFieldsForButton(
        paymentMethodData,
        {},
        undefined,
        undefined,
        true,
        {}
      );

      expect(Array.isArray(fields)).toBe(true);
    });

    it('getRequiredFieldsForButton handles billing address', () => {
      const nativeProp = createMockNativeProp();
      const accountData = {
        payment_methods: [],
        merchant_name: 'Test Merchant',
        collect_billing_details_from_wallets: true,
        payment_type: 'NORMAL',
      };
      const wrapper = createRealWrapper(nativeProp, accountData);

      const { result } = renderHook(() => React.useContext(dynamicFieldsContext), { wrapper });

      const paymentMethodData = {
        payment_method: 'CARD',
        payment_method_str: 'card',
        payment_method_type: 'debit',
        payment_method_type_wallet: 'NONE',
        card_networks: [],
        bank_names: [],
        payment_experience: [],
        required_fields: {},
      };

      const billingAddress = {
        address: {
          line1: '123 Main St',
          city: 'San Francisco',
          state: 'CA',
          postal_code: '94102',
          country: 'US',
        },
      };

      const fields = result.current.getRequiredFieldsForButton(
        paymentMethodData,
        {},
        billingAddress,
        undefined,
        false,
        {}
      );

      expect(Array.isArray(fields)).toBe(true);
    });

    it('handles mandate payment type', () => {
      const nativeProp = createMockNativeProp();
      const accountData = {
        payment_methods: [],
        merchant_name: 'Test Merchant',
        collect_billing_details_from_wallets: false,
        payment_type: 'MANDATE',
      };
      const wrapper = createRealWrapper(nativeProp, accountData);

      const { result } = renderHook(() => React.useContext(dynamicFieldsContext), { wrapper });

      const paymentMethodData = {
        payment_method: 'CARD',
        payment_method_str: 'card',
        payment_method_type: 'debit',
        payment_method_type_wallet: 'NONE',
        card_networks: [],
        bank_names: [],
        payment_experience: [],
        required_fields: {},
      };

      const fields = result.current.getRequiredFieldsForTabs(paymentMethodData, {}, false);

      expect(Array.isArray(fields)).toBe(true);
    });

    it('handles setInitialValueCountry', () => {
      const nativeProp = createMockNativeProp();
      const wrapper = createRealWrapper(nativeProp, undefined);

      const { result } = renderHook(() => React.useContext(dynamicFieldsContext), { wrapper });

      act(() => {
        result.current.setInitialValueCountry('DE');
      });

      expect(typeof result.current.setInitialValueCountry).toBe('function');
    });
  });
});
