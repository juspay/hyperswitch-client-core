import { renderHook } from '@testing-library/react-native';

const { usePayButton } = require('../hooks/ButtonHook/ButtonHookImpl.native.bs.js');

describe('ButtonHookImpl.native', () => {
  describe('usePayButton', () => {
    it('exists as a function', () => {
      expect(usePayButton).toBeDefined();
      expect(typeof usePayButton).toBe('function');
    });

    it('returns an array with two functions', () => {
      const { result } = renderHook(() => usePayButton());

      expect(Array.isArray(result.current)).toBe(true);
      expect(result.current.length).toBe(2);
      expect(typeof result.current[0]).toBe('function');
      expect(typeof result.current[1]).toBe('function');
    });

    it('returns functions that can be called without throwing', () => {
      const { result } = renderHook(() => usePayButton());

      const [addApplePay, addGooglePay] = result.current;

      expect(() => addApplePay({}, undefined)).not.toThrow();
      expect(() => addGooglePay({})).not.toThrow();
    });

    it('first function (addApplePay) accepts session object and undefined param', () => {
      const { result } = renderHook(() => usePayButton());

      const [addApplePay] = result.current;

      expect(() => addApplePay({ session_token_data: 'token' }, undefined)).not.toThrow();
    });

    it('second function (addGooglePay) accepts session object', () => {
      const { result } = renderHook(() => usePayButton());

      const [, addGooglePay] = result.current;

      expect(() => addGooglePay({ session_token: 'gpay_token' })).not.toThrow();
    });

    it('returns consistent function references on re-render', () => {
      const { result, rerender } = renderHook(() => usePayButton());

      const firstResult = result.current;

      rerender({});

      expect(result.current.length).toBe(2);
    });

    it('handles being called with no arguments in returned functions', () => {
      const { result } = renderHook(() => usePayButton());

      const [addApplePay, addGooglePay] = result.current;

      expect(() => addApplePay()).not.toThrow();
      expect(() => addGooglePay()).not.toThrow();
    });

    it('handles null arguments in returned functions', () => {
      const { result } = renderHook(() => usePayButton());

      const [addApplePay, addGooglePay] = result.current;

      expect(() => addApplePay(null, null)).not.toThrow();
      expect(() => addGooglePay(null)).not.toThrow();
    });

    it('handles undefined arguments in returned functions', () => {
      const { result } = renderHook(() => usePayButton());

      const [addApplePay, addGooglePay] = result.current;

      expect(() => addApplePay(undefined, undefined)).not.toThrow();
      expect(() => addGooglePay(undefined)).not.toThrow();
    });

    it('handles complex session objects in returned functions', () => {
      const { result } = renderHook(() => usePayButton());

      const [addApplePay, addGooglePay] = result.current;

      const complexSessionObject = {
        session_token_data: {
          merchantIdentifier: 'merchant.com.example',
          displayName: 'Example Merchant',
          initiativeContext: 'example.com'
        },
        payment_request_data: {
          countryCode: 'US',
          currencyCode: 'USD',
          supportedNetworks: ['visa', 'masterCard'],
          merchantCapabilities: ['supports3DS'],
          total: {
            label: 'Total',
            amount: '10.00'
          }
        }
      };

      expect(() => addApplePay(complexSessionObject, undefined)).not.toThrow();
      expect(() => addGooglePay(complexSessionObject)).not.toThrow();
    });
  });
});
