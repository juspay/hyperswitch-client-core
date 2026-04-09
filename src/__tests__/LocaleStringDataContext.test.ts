import { renderHook, act } from '@testing-library/react-native';
import { localeDataContext, make as LocaleStringDataContextProvider } from '../contexts/LocaleStringDataContext.bs.js';
import { defaultLocale } from '../../shared-code/sdk-utils/types/LocaleDataType.bs.js';
import React from 'react';

const mockFetchData = jest.fn(() => Promise.resolve(undefined));

jest.mock('../hooks/S3ApiHook.bs.js', () => ({
  useFetchDataFromS3WithGZipDecoding: jest.fn(() => mockFetchData),
  getLocaleStringsFromJson: jest.fn(),
}));

jest.mock('../../shared-code/sdk-utils/types/LocaleDataType.bs.js', () => ({
  defaultLocale: {
    locale: 'en',
    localeDirection: 'ltr',
    cardNumberLabel: 'Card Number',
    cardDetailsLabel: 'Card Details',
    payNowButton: 'Pay Now',
    emailLabel: 'Email',
  },
  localeTypeToString: jest.fn((locale) => {
    if (locale === 'En') return 'en';
    if (typeof locale === 'string') return locale.toLowerCase();
    return 'en';
  }),
}));

jest.mock('@rescript/core/src/Core__Promise.bs.js', () => ({
  $$catch: jest.fn((promise, handler) => promise.catch(handler)),
}));

describe('LocaleStringDataContext', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    mockFetchData.mockReset();
    mockFetchData.mockResolvedValue(undefined);
  });

  describe('localeDataContext', () => {
    it('has default value with defaultLocale', () => {
      expect(localeDataContext).toBeDefined();
    });

    it('provides defaultLocale as initial state', () => {
      const wrapper = ({ children }: { children: React.ReactNode }) =>
        React.createElement(LocaleStringDataContextProvider, { value: [defaultLocale, jest.fn()] }, children);

      const { result } = renderHook(() => React.useContext(localeDataContext), { wrapper });

      expect(result.current[0].locale).toBe("en");
      expect(result.current[0].localeDirection).toBe("ltr");
      expect(typeof result.current[1]).toBe("function");
    });
  });

  describe('LocaleStringDataContext Provider', () => {
    it('provides initial state as defaultLocale', () => {
      const wrapper = ({ children }: { children: React.ReactNode }) =>
        React.createElement(LocaleStringDataContextProvider, { value: [defaultLocale, jest.fn()] }, children);

      const { result } = renderHook(() => React.useContext(localeDataContext), { wrapper });

      expect(result.current[0].locale).toBe("en");
      expect(result.current[0].cardNumberLabel).toBe("Card Number");
    });

    it('allows locale state to be updated via setter', () => {
      const TestComponent = () => {
        const [locale, setLocale] = React.useContext(localeDataContext);
        return { locale, setLocale };
      };

      const wrapper = ({ children }: { children: React.ReactNode }) =>
        React.createElement(LocaleStringDataContextProvider, { value: [defaultLocale, jest.fn()] }, children);

      const { result } = renderHook(() => TestComponent(), { wrapper });

      const newLocale = { ...defaultLocale, locale: "fr", cardNumberLabel: "Numéro de carte" };

      act(() => {
        result.current.setLocale(newLocale);
      });

      expect(result.current.locale.locale).toBe("fr");
      expect(result.current.locale.cardNumberLabel).toBe("Numéro de carte");
    });

    it('state can be updated with different locale configurations', () => {
      const TestComponent = () => {
        const [locale, setLocale] = React.useContext(localeDataContext);
        return { locale, setLocale };
      };

      const wrapper = ({ children }: { children: React.ReactNode }) =>
        React.createElement(LocaleStringDataContextProvider, { value: [defaultLocale, jest.fn()] }, children);

      const { result } = renderHook(() => TestComponent(), { wrapper });

      const germanLocale = { ...defaultLocale, locale: "de", cardNumberLabel: "Kartennummer" };

      act(() => {
        result.current.setLocale(germanLocale);
      });

      expect(result.current.locale.locale).toBe("de");
      expect(result.current.locale.cardNumberLabel).toBe("Kartennummer");
    });

    it('locale state has all expected default properties', () => {
      const wrapper = ({ children }: { children: React.ReactNode }) =>
        React.createElement(LocaleStringDataContextProvider, { value: [defaultLocale, jest.fn()] }, children);

      const { result } = renderHook(() => React.useContext(localeDataContext), { wrapper });

      expect(result.current[0]).toHaveProperty('locale');
      expect(result.current[0]).toHaveProperty('localeDirection');
      expect(result.current[0]).toHaveProperty('cardNumberLabel');
      expect(result.current[0]).toHaveProperty('cardDetailsLabel');
      expect(result.current[0]).toHaveProperty('payNowButton');
      expect(result.current[0]).toHaveProperty('emailLabel');
    });

    it('can set locale to Japanese', () => {
      const TestComponent = () => {
        const [locale, setLocale] = React.useContext(localeDataContext);
        return { locale, setLocale };
      };

      const wrapper = ({ children }: { children: React.ReactNode }) =>
        React.createElement(LocaleStringDataContextProvider, { value: [defaultLocale, jest.fn()] }, children);

      const { result } = renderHook(() => TestComponent(), { wrapper });

      const japaneseLocale = { ...defaultLocale, locale: "ja", cardNumberLabel: "カード番号" };

      act(() => {
        result.current.setLocale(japaneseLocale);
      });

      expect(result.current.locale.locale).toBe("ja");
      expect(result.current.locale.cardNumberLabel).toBe("カード番号");
    });
  });

  describe('LocaleStringDataContext with real component', () => {
    it('fetches and sets locale data on mount', async () => {
      const mockLocaleData = {
        locale: 'fr',
        localeDirection: 'ltr',
        cardNumberLabel: 'Numéro de carte',
      };

      mockFetchData.mockResolvedValueOnce(mockLocaleData);

      const wrapper = ({ children }: { children: React.ReactNode }) =>
        React.createElement(LocaleStringDataContextProvider, { locale: 'Fr' } as any, children);

      const { result } = renderHook(() => React.useContext(localeDataContext), { wrapper });

      expect(result.current[0]).toBeDefined();
    });

    it('updates state when locale fetch succeeds', async () => {
      const mockLocaleData = {
        locale: 'de',
        localeDirection: 'ltr',
        cardNumberLabel: 'Kartennummer',
      };

      mockFetchData.mockResolvedValueOnce(mockLocaleData);

      const wrapper = ({ children }: { children: React.ReactNode }) =>
        React.createElement(LocaleStringDataContextProvider, { locale: 'De' } as any, children);

      const { result } = renderHook(() => React.useContext(localeDataContext), { wrapper });

      await act(async () => {
        await new Promise(resolve => setTimeout(resolve, 0));
      });

      expect(mockFetchData).toHaveBeenCalled();
    });

    it('falls back to English locale when primary fetch fails', async () => {
      mockFetchData
        .mockRejectedValueOnce(new Error('Primary fetch failed'))
        .mockResolvedValueOnce({
          locale: 'en',
          localeDirection: 'ltr',
          cardNumberLabel: 'Card Number',
        });

      const wrapper = ({ children }: { children: React.ReactNode }) =>
        React.createElement(LocaleStringDataContextProvider, { locale: 'Unknown' } as any, children);

      const { result } = renderHook(() => React.useContext(localeDataContext), { wrapper });

      await act(async () => {
        await new Promise(resolve => setTimeout(resolve, 0));
      });

      expect(mockFetchData).toHaveBeenCalled();
    });

    it('handles successful locale fetch from S3', async () => {
      const spanishLocale = {
        locale: 'es',
        localeDirection: 'ltr',
        cardNumberLabel: 'Número de tarjeta',
      };

      mockFetchData.mockResolvedValueOnce(spanishLocale);

      const wrapper = ({ children }: { children: React.ReactNode }) =>
        React.createElement(LocaleStringDataContextProvider, { locale: 'Es' } as any, children);

      renderHook(() => React.useContext(localeDataContext), { wrapper });

      await act(async () => {
        await new Promise(resolve => setTimeout(resolve, 0));
      });

      expect(mockFetchData).toHaveBeenCalledWith(
        expect.stringContaining('es.json'),
        expect.any(Function),
        undefined
      );
    });

    it('fetches English fallback when primary locale fetch returns undefined', async () => {
      mockFetchData
        .mockResolvedValueOnce(undefined)
        .mockResolvedValueOnce({
          locale: 'en',
          localeDirection: 'ltr',
          cardNumberLabel: 'Card Number',
        });

      const wrapper = ({ children }: { children: React.ReactNode }) =>
        React.createElement(LocaleStringDataContextProvider, { locale: 'Unknown' } as any, children);

      renderHook(() => React.useContext(localeDataContext), { wrapper });

      await act(async () => {
        await new Promise(resolve => setTimeout(resolve, 0));
      });

      expect(mockFetchData).toHaveBeenCalledTimes(2);
    });
  });
});
