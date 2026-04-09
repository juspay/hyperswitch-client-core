import { renderHook, act } from '@testing-library/react-native';
import React from 'react';
import { useShowErrorOrWarning, useErrorWarningValidationOnLoad } from '../utility/reusableCodeFromWeb/ErrorHooks.bs.js';
import * as ErrorUtils from '../utility/reusableCodeFromWeb/ErrorUtils.bs.js';

jest.mock('../hooks/AlertHook.bs.js', () => ({
  useAlerts: jest.fn(),
}));

const mockCustomAlert = jest.fn();

beforeEach(() => {
  jest.clearAllMocks();
  (require('../hooks/AlertHook.bs.js').useAlerts as jest.Mock).mockReturnValue(mockCustomAlert);
});

const createMockNativeProp = (overrides = {}) => ({
  env: 'SANDBOX',
  publishableKey: 'pk_snd_test123',
  clientSecret: 'pay_test_secret_abc123',
  sdkState: 'PaymentSheet',
  ...overrides,
});

describe('ErrorHooks', () => {
  describe('useShowErrorOrWarning', () => {
    it('returns a function that handles Error type with Static message', () => {
      const { result } = renderHook(() => useShowErrorOrWarning());

      const showErrorOrWarning = result.current;

      act(() => {
        showErrorOrWarning(ErrorUtils.errorWarning.invalidPk, undefined, undefined);
      });

      expect(mockCustomAlert).toHaveBeenCalledWith(
        'error',
        'INTEGRATION ERROR: Invalid Publishable key, starts with pk_snd_(sandbox/test) or pk_prd_(production/live)'
      );
    });

    it('returns a function that handles Warning type with Static message', () => {
      const { result } = renderHook(() => useShowErrorOrWarning());

      const showErrorOrWarning = result.current;

      act(() => {
        showErrorOrWarning(ErrorUtils.errorWarning.deprecatedLoadStripe, undefined, undefined);
      });

      expect(mockCustomAlert).toHaveBeenCalledWith(
        'warning',
        'loadStripe is deprecated. Please use loadOrca instead.'
      );
    });

    it('handles Error type with Dynamic message and provides dynamic string', () => {
      const { result } = renderHook(() => useShowErrorOrWarning());

      const showErrorOrWarning = result.current;

      act(() => {
        showErrorOrWarning(ErrorUtils.errorWarning.reguirParameter, 'missing_api_key', undefined);
      });

      expect(mockCustomAlert).toHaveBeenCalledWith('error', 'INTEGRATION ERROR: missing_api_key');
    });

    it('handles Warning type with Dynamic message and provides dynamic string', () => {
      const { result } = renderHook(() => useShowErrorOrWarning());

      const showErrorOrWarning = result.current;

      act(() => {
        showErrorOrWarning(ErrorUtils.errorWarning.typeBoolError, 'is_enabled', undefined);
      });

      expect(mockCustomAlert).toHaveBeenCalledWith('warning', "Type Error: 'is_enabled' Expected boolean");
    });

    it('handles Dynamic message with empty dynamic string', () => {
      const { result } = renderHook(() => useShowErrorOrWarning());

      const showErrorOrWarning = result.current;

      act(() => {
        showErrorOrWarning(ErrorUtils.errorWarning.invalidFormat, '', undefined);
      });

      expect(mockCustomAlert).toHaveBeenCalledWith('error', '');
    });

    it('handles invalidFormat error with custom message', () => {
      const { result } = renderHook(() => useShowErrorOrWarning());

      const showErrorOrWarning = result.current;

      act(() => {
        showErrorOrWarning(
          ErrorUtils.errorWarning.invalidFormat,
          'ClientSecret is expected to be in format pay_******_secret_*****',
          undefined
        );
      });

      expect(mockCustomAlert).toHaveBeenCalledWith(
        'error',
        'ClientSecret is expected to be in format pay_******_secret_*****'
      );
    });

    it('handles unknownKey warning with dynamic key name', () => {
      const { result } = renderHook(() => useShowErrorOrWarning());

      const showErrorOrWarning = result.current;

      act(() => {
        showErrorOrWarning(ErrorUtils.errorWarning.unknownKey, 'invalid_config_key', undefined);
      });

      expect(mockCustomAlert).toHaveBeenCalledWith(
        'warning',
        'Unknown Key: invalid_config_key is a unknown/invalid key, please provide a correct key. This might cause issue in the future'
      );
    });

    it('handles unknownValue warning with dynamic value', () => {
      const { result } = renderHook(() => useShowErrorOrWarning());

      const showErrorOrWarning = result.current;

      act(() => {
        showErrorOrWarning(ErrorUtils.errorWarning.unknownValue, 'unsupported_currency', undefined);
      });

      expect(mockCustomAlert).toHaveBeenCalledWith(
        'warning',
        'Unknown Value: unsupported_currency. Please provide a correct value. This might cause issue in the future'
      );
    });

    it('uses empty string when dynamicStrOpt is undefined for Dynamic messages', () => {
      const { result } = renderHook(() => useShowErrorOrWarning());

      const showErrorOrWarning = result.current;

      act(() => {
        showErrorOrWarning(ErrorUtils.errorWarning.typeStringError, undefined, undefined);
      });

      expect(mockCustomAlert).toHaveBeenCalledWith('warning', "Type Error: '' Expected string");
    });
  });

  describe('useErrorWarningValidationOnLoad', () => {
    const { nativePropContext } = require('../contexts/NativePropContext.bs.js');

    const createWrapper = (nativeProp: any) => {
      return ({ children }: { children: React.ReactNode }) =>
        React.createElement(
          nativePropContext.Provider,
          { value: [nativeProp, jest.fn()] },
          children
        );
    };

    it('returns a function that does nothing when both PK and clientSecret are valid for PaymentSheet', () => {
      const nativeProp = createMockNativeProp({
        env: 'SANDBOX',
        publishableKey: 'pk_snd_valid_key',
        clientSecret: 'pay_test_secret_abc123',
        sdkState: 'PaymentSheet',
      });

      const wrapper = createWrapper(nativeProp);
      const { result } = renderHook(() => useErrorWarningValidationOnLoad(), { wrapper });

      act(() => {
        result.current();
      });

      expect(mockCustomAlert).not.toHaveBeenCalled();
    });

    it('returns a function that does nothing when both PK and clientSecret are valid for HostedCheckout', () => {
      const nativeProp = createMockNativeProp({
        env: 'SANDBOX',
        publishableKey: 'pk_snd_valid_key',
        clientSecret: 'pay_test_secret_abc123',
        sdkState: 'HostedCheckout',
      });

      const wrapper = createWrapper(nativeProp);
      const { result } = renderHook(() => useErrorWarningValidationOnLoad(), { wrapper });

      act(() => {
        result.current();
      });

      expect(mockCustomAlert).not.toHaveBeenCalled();
    });

    it('shows invalid PK error when publishable key is invalid for PaymentSheet', () => {
      const nativeProp = createMockNativeProp({
        env: 'SANDBOX',
        publishableKey: 'invalid_key',
        clientSecret: 'pay_test_secret_abc123',
        sdkState: 'PaymentSheet',
      });

      const wrapper = createWrapper(nativeProp);
      const { result } = renderHook(() => useErrorWarningValidationOnLoad(), { wrapper });

      act(() => {
        result.current();
      });

      expect(mockCustomAlert).toHaveBeenCalledWith(
        'error',
        'INTEGRATION ERROR: Invalid Publishable key, starts with pk_snd_(sandbox/test) or pk_prd_(production/live)'
      );
    });

    it('does not show error for invalid PK when sdkState is CardWidget', () => {
      const nativeProp = createMockNativeProp({
        env: 'SANDBOX',
        publishableKey: 'invalid_key',
        clientSecret: 'pay_test_secret_abc123',
        sdkState: 'CardWidget',
      });

      const wrapper = createWrapper(nativeProp);
      const { result } = renderHook(() => useErrorWarningValidationOnLoad(), { wrapper });

      act(() => {
        result.current();
      });

      expect(mockCustomAlert).not.toHaveBeenCalled();
    });

    it('does not show error for invalid PK when sdkState is NoView', () => {
      const nativeProp = createMockNativeProp({
        env: 'SANDBOX',
        publishableKey: 'invalid_key',
        clientSecret: 'pay_test_secret_abc123',
        sdkState: 'NoView',
      });

      const wrapper = createWrapper(nativeProp);
      const { result } = renderHook(() => useErrorWarningValidationOnLoad(), { wrapper });

      act(() => {
        result.current();
      });

      expect(mockCustomAlert).not.toHaveBeenCalled();
    });

    it('shows invalid clientSecret format error for PaymentSheet when clientSecret is invalid', () => {
      const nativeProp = createMockNativeProp({
        env: 'SANDBOX',
        publishableKey: 'pk_snd_valid_key',
        clientSecret: 'completely_invalid_format',
        sdkState: 'PaymentSheet',
      });

      const wrapper = createWrapper(nativeProp);
      const { result } = renderHook(() => useErrorWarningValidationOnLoad(), { wrapper });

      act(() => {
        result.current();
      });

      expect(mockCustomAlert).toHaveBeenCalledWith('error', 'ClientSecret is expected to be in format pay_******_secret_*****');
    });

    it('shows invalid clientSecret format error for HostedCheckout when clientSecret is invalid', () => {
      const nativeProp = createMockNativeProp({
        env: 'SANDBOX',
        publishableKey: 'pk_snd_valid_key',
        clientSecret: 'completely_invalid_format',
        sdkState: 'HostedCheckout',
      });

      const wrapper = createWrapper(nativeProp);
      const { result } = renderHook(() => useErrorWarningValidationOnLoad(), { wrapper });

      act(() => {
        result.current();
      });

      expect(mockCustomAlert).toHaveBeenCalledWith('error', 'ClientSecret is expected to be in format pay_******_secret_*****');
    });

    it('does not show clientSecret error for CardWidget when clientSecret is invalid', () => {
      const nativeProp = createMockNativeProp({
        env: 'SANDBOX',
        publishableKey: 'pk_snd_valid_key',
        clientSecret: 'completely_invalid_format',
        sdkState: 'CardWidget',
      });

      const wrapper = createWrapper(nativeProp);
      const { result } = renderHook(() => useErrorWarningValidationOnLoad(), { wrapper });

      act(() => {
        result.current();
      });

      expect(mockCustomAlert).not.toHaveBeenCalled();
    });

    it('shows clientSecret error for Headless when clientSecret is invalid', () => {
      const nativeProp = createMockNativeProp({
        env: 'SANDBOX',
        publishableKey: 'pk_snd_valid_key',
        clientSecret: 'completely_invalid_format',
        sdkState: 'Headless',
      });

      const wrapper = createWrapper(nativeProp);
      const { result } = renderHook(() => useErrorWarningValidationOnLoad(), { wrapper });

      act(() => {
        result.current();
      });

      expect(mockCustomAlert).toHaveBeenCalledWith('error', 'ClientSecret is expected to be in format pay_******_secret_*****');
    });

    it('works correctly with PROD environment and valid pk_prd_ key', () => {
      const nativeProp = createMockNativeProp({
        env: 'PROD',
        publishableKey: 'pk_prd_live_key',
        clientSecret: 'pay_prod_secret_xyz789',
        sdkState: 'PaymentSheet',
      });

      const wrapper = createWrapper(nativeProp);
      const { result } = renderHook(() => useErrorWarningValidationOnLoad(), { wrapper });

      act(() => {
        result.current();
      });

      expect(mockCustomAlert).not.toHaveBeenCalled();
    });

    it('shows error when pk_prd_ key is used in SANDBOX env', () => {
      const nativeProp = createMockNativeProp({
        env: 'SANDBOX',
        publishableKey: 'pk_prd_live_key',
        clientSecret: 'pay_prod_secret_xyz789',
        sdkState: 'PaymentSheet',
      });

      const wrapper = createWrapper(nativeProp);
      const { result } = renderHook(() => useErrorWarningValidationOnLoad(), { wrapper });

      act(() => {
        result.current();
      });

      expect(mockCustomAlert).toHaveBeenCalledWith(
        'error',
        'INTEGRATION ERROR: Invalid Publishable key, starts with pk_snd_(sandbox/test) or pk_prd_(production/live)'
      );
    });

    it('shows error when pk_snd_ key is used in PROD env', () => {
      const nativeProp = createMockNativeProp({
        env: 'PROD',
        publishableKey: 'pk_snd_test_key',
        clientSecret: 'pay_test_secret_abc123',
        sdkState: 'PaymentSheet',
      });

      const wrapper = createWrapper(nativeProp);
      const { result } = renderHook(() => useErrorWarningValidationOnLoad(), { wrapper });

      act(() => {
        result.current();
      });

      expect(mockCustomAlert).toHaveBeenCalledWith(
        'error',
        'INTEGRATION ERROR: Invalid Publishable key, starts with pk_snd_(sandbox/test) or pk_prd_(production/live)'
      );
    });

    it('handles ExpressCheckoutWidget sdkState correctly - no error shown', () => {
      const nativeProp = createMockNativeProp({
        env: 'SANDBOX',
        publishableKey: 'pk_snd_valid',
        clientSecret: 'completely_invalid_format',
        sdkState: 'ExpressCheckoutWidget',
      });

      const wrapper = createWrapper(nativeProp);
      const { result } = renderHook(() => useErrorWarningValidationOnLoad(), { wrapper });

      act(() => {
        result.current();
      });

      expect(mockCustomAlert).not.toHaveBeenCalled();
    });

    it('handles PaymentMethodsManagement sdkState correctly - no error shown', () => {
      const nativeProp = createMockNativeProp({
        env: 'SANDBOX',
        publishableKey: 'pk_snd_valid',
        clientSecret: 'completely_invalid_format',
        sdkState: 'PaymentMethodsManagement',
      });

      const wrapper = createWrapper(nativeProp);
      const { result } = renderHook(() => useErrorWarningValidationOnLoad(), { wrapper });

      act(() => {
        result.current();
      });

      expect(mockCustomAlert).not.toHaveBeenCalled();
    });

    it('handles empty publishableKey correctly', () => {
      const nativeProp = createMockNativeProp({
        env: 'SANDBOX',
        publishableKey: '',
        clientSecret: 'pay_test_secret_abc123',
        sdkState: 'PaymentSheet',
      });

      const wrapper = createWrapper(nativeProp);
      const { result } = renderHook(() => useErrorWarningValidationOnLoad(), { wrapper });

      act(() => {
        result.current();
      });

      expect(mockCustomAlert).toHaveBeenCalledWith(
        'error',
        'INTEGRATION ERROR: Invalid Publishable key, starts with pk_snd_(sandbox/test) or pk_prd_(production/live)'
      );
    });

    it('handles CustomWidget sdkState correctly (object type)', () => {
      const nativeProp = createMockNativeProp({
        env: 'SANDBOX',
        publishableKey: 'invalid_key',
        clientSecret: 'pay_test_secret_abc123',
        sdkState: { TAG: 'CustomWidget', _0: 'GOOGLE_PAY' },
      });

      const wrapper = createWrapper(nativeProp);
      const { result } = renderHook(() => useErrorWarningValidationOnLoad(), { wrapper });

      act(() => {
        result.current();
      });

      expect(mockCustomAlert).not.toHaveBeenCalled();
    });

    it('handles CustomWidget sdkState with invalid clientSecret correctly (object type)', () => {
      const nativeProp = createMockNativeProp({
        env: 'SANDBOX',
        publishableKey: 'pk_snd_valid',
        clientSecret: 'completely_invalid_format',
        sdkState: { TAG: 'CustomWidget', _0: 'PAYPAL' },
      });

      const wrapper = createWrapper(nativeProp);
      const { result } = renderHook(() => useErrorWarningValidationOnLoad(), { wrapper });

      act(() => {
        result.current();
      });

      expect(mockCustomAlert).not.toHaveBeenCalled();
    });
  });
});
