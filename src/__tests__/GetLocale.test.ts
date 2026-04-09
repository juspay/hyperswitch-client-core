import { renderHook } from '@testing-library/react-native';
import React from 'react';
import { useGetLocalObj, getLocalString } from '../hooks/GetLocale.bs.js';
import { localeDataContext } from '../contexts/LocaleStringDataContext.bs.js';
import { defaultLocale } from '../../shared-code/sdk-utils/types/LocaleDataType.bs.js';

describe('GetLocale', () => {
  const createWrapper = (localeValue: typeof defaultLocale = defaultLocale) => {
    return ({ children }: { children: React.ReactNode }) =>
      React.createElement(
        localeDataContext.Provider,
        { value: [localeValue, jest.fn()] },
        children
      );
  };

  describe('useGetLocalObj', () => {
    it('returns locale object from context', () => {
      const { result } = renderHook(() => useGetLocalObj(), {
        wrapper: createWrapper(),
      });

      expect(result.current).toBeDefined();
      expect(result.current.locale).toBe('en');
      expect(result.current.localeDirection).toBe('ltr');
    });

    it('returns locale object with cardNumberLabel', () => {
      const { result } = renderHook(() => useGetLocalObj(), {
        wrapper: createWrapper(),
      });

      expect(result.current.cardNumberLabel).toBe('Card Number');
    });

    it('returns locale object with emailLabel', () => {
      const { result } = renderHook(() => useGetLocalObj(), {
        wrapper: createWrapper(),
      });

      expect(result.current.emailLabel).toBe('Email');
    });

    it('returns custom locale when provided via context', () => {
      const customLocale = {
        ...defaultLocale,
        locale: 'fr',
        cardNumberLabel: 'Numéro de carte',
        emailLabel: 'E-mail',
      };

      const { result } = renderHook(() => useGetLocalObj(), {
        wrapper: createWrapper(customLocale),
      });

      expect(result.current.locale).toBe('fr');
      expect(result.current.cardNumberLabel).toBe('Numéro de carte');
      expect(result.current.emailLabel).toBe('E-mail');
    });

    it('returns locale object with all required properties', () => {
      const { result } = renderHook(() => useGetLocalObj(), {
        wrapper: createWrapper(),
      });

      expect(result.current).toHaveProperty('locale');
      expect(result.current).toHaveProperty('localeDirection');
      expect(result.current).toHaveProperty('cardNumberLabel');
      expect(result.current).toHaveProperty('cardDetailsLabel');
      expect(result.current).toHaveProperty('payNowButton');
      expect(result.current).toHaveProperty('emailLabel');
      expect(result.current).toHaveProperty('line1Label');
      expect(result.current).toHaveProperty('cityLabel');
      expect(result.current).toHaveProperty('countryLabel');
      expect(result.current).toHaveProperty('postalCodeLabel');
      expect(result.current).toHaveProperty('stateLabel');
    });
  });

  describe('getLocalString', () => {
    it('returns accountNumberText for "Account Number" displayName', () => {
      const { result } = renderHook(() => getLocalString('Account Number'), {
        wrapper: createWrapper(),
      });

      expect(result.current).toBe('Account Number');
    });

    it('returns line1Label for "Address Line 1" displayName', () => {
      const { result } = renderHook(() => getLocalString('Address Line 1'), {
        wrapper: createWrapper(),
      });

      expect(result.current).toBe('Address line 1');
    });

    it('returns line2Label for "Address Line 2" displayName', () => {
      const { result } = renderHook(() => getLocalString('Address Line 2'), {
        wrapper: createWrapper(),
      });

      expect(result.current).toBe('Address line 2');
    });

    it('returns cityLabel for "City" displayName', () => {
      const { result } = renderHook(() => getLocalString('City'), {
        wrapper: createWrapper(),
      });

      expect(result.current).toBe('City');
    });

    it('returns countryLabel for "Country" displayName', () => {
      const { result } = renderHook(() => getLocalString('Country'), {
        wrapper: createWrapper(),
      });

      expect(result.current).toBe('Country');
    });

    it('returns currencyLabel for "Currency" displayName', () => {
      const { result } = renderHook(() => getLocalString('Currency'), {
        wrapper: createWrapper(),
      });

      expect(result.current).toBe('Currency');
    });

    it('returns dateOfBirth for "Date of Birth" displayName', () => {
      const { result } = renderHook(() => getLocalString('Date of Birth'), {
        wrapper: createWrapper(),
      });

      expect(result.current).toBe('Date of Birth');
    });

    it('returns emailLabel for "Email Address" displayName', () => {
      const { result } = renderHook(() => getLocalString('Email Address'), {
        wrapper: createWrapper(),
      });

      expect(result.current).toBe('Email');
    });

    it('returns currencyNetwork for "Network" displayName', () => {
      const { result } = renderHook(() => getLocalString('Network'), {
        wrapper: createWrapper(),
      });

      expect(result.current).toBe('Currency Networks');
    });

    it('returns formFieldPhoneNumberLabel for "Phone Number" displayName', () => {
      const { result } = renderHook(() => getLocalString('Phone Number'), {
        wrapper: createWrapper(),
      });

      expect(result.current).toBe('Phone Number');
    });

    it('returns formFieldACHRoutingNumberLabel for "Routing Number" displayName', () => {
      const { result } = renderHook(() => getLocalString('Routing Number'), {
        wrapper: createWrapper(),
      });

      expect(result.current).toBe('Routing Number');
    });

    it('returns sortCodeText for "Sort Code" displayName', () => {
      const { result } = renderHook(() => getLocalString('Sort Code'), {
        wrapper: createWrapper(),
      });

      expect(result.current).toBe('Sort Code');
    });

    it('returns stateLabel for "State/Province" displayName', () => {
      const { result } = renderHook(() => getLocalString('State/Province'), {
        wrapper: createWrapper(),
      });

      expect(result.current).toBe('State');
    });

    it('returns postalCodeLabel for "ZIP/Postal Code" displayName', () => {
      const { result } = renderHook(() => getLocalString('ZIP/Postal Code'), {
        wrapper: createWrapper(),
      });

      expect(result.current).toBe('Postal Code');
    });

    it('returns displayName as-is for unknown displayName', () => {
      const { result } = renderHook(() => getLocalString('Unknown Field'), {
        wrapper: createWrapper(),
      });

      expect(result.current).toBe('Unknown Field');
    });

    it('returns displayName as-is for empty string', () => {
      const { result } = renderHook(() => getLocalString(''), {
        wrapper: createWrapper(),
      });

      expect(result.current).toBe('');
    });

    it('returns localized string for custom locale', () => {
      const customLocale = {
        ...defaultLocale,
        accountNumberText: 'Numéro de compte',
        line1Label: 'Adresse ligne 1',
      };

      const { result } = renderHook(() => getLocalString('Account Number'), {
        wrapper: createWrapper(customLocale),
      });

      expect(result.current).toBe('Numéro de compte');
    });
  });
});
