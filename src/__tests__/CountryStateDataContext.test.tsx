import * as React from 'react';
import { renderHook, act } from '@testing-library/react-native';
import {
  countryStateDataContext,
  make as CountryStateDataContext,
} from '../contexts/CountryStateDataContext.bs.js';

jest.mock('../hooks/S3ApiHook.bs.js', () => ({
  useFetchDataFromS3WithGZipDecoding: jest.fn(() => jest.fn(() => Promise.resolve(undefined))),
  decodeJsonTocountryStateData: jest.fn((data) => data || { countries: [], states: {} }),
}));

jest.mock('../hooks/LoggerHook.bs.js', () => ({
  useLoggerHook: jest.fn(() => jest.fn()),
}));

jest.mock('../../shared-code/assets/v2/jsons/location/en.json', () => ({
  country: [{ country_code: 'US', country_name: 'United States', phone_number_code: '+1', timeZones: [] }],
  states: { US: [{ label: 'California', value: 'CA', code: 'CA' }] },
}), { virtual: true });

describe('CountryStateDataContext', () => {
  describe('countryStateDataContext', () => {
    it('has default value with "Loading" state and empty function', () => {
      expect(countryStateDataContext._currentValue[0]).toBe('Loading');
      expect(typeof countryStateDataContext._currentValue[1]).toBe('function');
    });

    it('is a valid React context', () => {
      expect(countryStateDataContext.Provider).toBeDefined();
      expect(countryStateDataContext.Consumer).toBeDefined();
    });

    it('default fetcher function returns undefined', () => {
      const fetcher = countryStateDataContext._currentValue[1];
      expect(fetcher()).toBeUndefined();
    });
  });

  describe('CountryStateDataContext component', () => {
    beforeEach(() => {
      jest.clearAllMocks();
    });

    it('renders children when wrapped', () => {
      const wrapper = ({ children }: { children: React.ReactNode }) => (
        <CountryStateDataContext>{children}</CountryStateDataContext>
      );

      const { result } = renderHook(() => React.useContext(countryStateDataContext), { wrapper });

      expect(result.current[0]).toBeDefined();
      expect(typeof result.current[1]).toBe('function');
    });

    it('provides a fetcher function that can be called', () => {
      const wrapper = ({ children }: { children: React.ReactNode }) => (
        <CountryStateDataContext>{children}</CountryStateDataContext>
      );

      const { result } = renderHook(() => React.useContext(countryStateDataContext), { wrapper });

      expect(() => {
        act(() => {
          result.current[1]();
        });
      }).not.toThrow();
    });

    it('provides Loading state initially', () => {
      const wrapper = ({ children }: { children: React.ReactNode }) => (
        <CountryStateDataContext>{children}</CountryStateDataContext>
      );

      const { result } = renderHook(() => React.useContext(countryStateDataContext), { wrapper });

      const state = result.current[0];
      if (typeof state === 'string') {
        expect(state).toBe('Loading');
      } else {
        expect(state.TAG).toBeDefined();
      }
    });
  });

  describe('context value structure', () => {
    it('returns array with state and fetcher function', () => {
      const wrapper = ({ children }: { children: React.ReactNode }) => (
        <CountryStateDataContext>{children}</CountryStateDataContext>
      );

      const { result } = renderHook(() => React.useContext(countryStateDataContext), { wrapper });

      expect(Array.isArray(result.current)).toBe(true);
      expect(result.current).toHaveLength(2);
      expect(typeof result.current[1]).toBe('function');
    });
  });
});
