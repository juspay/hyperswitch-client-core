import {
  decodeCountryArray,
  decodeStateJson,
  decodeJsonTocountryStateData,
  getLocaleStrings,
  getLocaleStringsFromJson,
} from '../hooks/S3ApiHook.bs.js';
import { defaultLocale } from '../../shared-code/sdk-utils/types/LocaleDataType.bs.js';
import { defaultTimeZone } from '../../shared-code/sdk-utils/types/CountryStateDataHookTypes.bs.js';

describe('S3ApiHook', () => {
  describe('decodeCountryArray', () => {
    it('decodes array of country objects', () => {
      const data = [
        {
          country_code: 'US',
          country_name: 'United States',
          country_flag: '🇺🇸',
          phone_number_code: '+1',
          validation_regex: '^\\d{10}$',
          format_example: '1234567890',
          format_regex: '\\d{3}-\\d{3}-\\d{4}',
          timeZones: ['America/New_York', 'America/Los_Angeles'],
        },
      ];

      const result = decodeCountryArray(data);

      expect(result).toHaveLength(1);
      expect(result[0].country_code).toBe('US');
      expect(result[0].country_name).toBe('United States');
      expect(result[0].country_flag).toBe('🇺🇸');
      expect(result[0].phone_number_code).toBe('+1');
      expect(result[0].validation_regex).toBe('^\\d{10}$');
      expect(result[0].timeZones).toEqual(['America/New_York', 'America/Los_Angeles']);
    });

    it('returns defaultTimeZone for invalid items', () => {
      const data = [null, 'invalid', 123];
      const result = decodeCountryArray(data);
      expect(result).toHaveLength(3);
      result.forEach((item) => {
        expect(item).toEqual(defaultTimeZone);
      });
    });

    it('handles missing optional fields', () => {
      const data = [
        {
          country_code: 'GB',
          country_name: 'United Kingdom',
          phone_number_code: '+44',
        },
      ];

      const result = decodeCountryArray(data);

      expect(result[0].country_flag).toBeUndefined();
      expect(result[0].validation_regex).toBeUndefined();
      expect(result[0].timeZones).toEqual([]);
    });

    it('handles empty array', () => {
      const result = decodeCountryArray([]);
      expect(result).toEqual([]);
    });

    it('processes multiple countries', () => {
      const data = [
        { country_code: 'US', country_name: 'United States', phone_number_code: '+1', timeZones: [] },
        { country_code: 'GB', country_name: 'United Kingdom', phone_number_code: '+44', timeZones: [] },
        { country_code: 'DE', country_name: 'Germany', phone_number_code: '+49', timeZones: [] },
      ];

      const result = decodeCountryArray(data);
      expect(result).toHaveLength(3);
      expect(result[0].country_code).toBe('US');
      expect(result[1].country_code).toBe('GB');
      expect(result[2].country_code).toBe('DE');
    });
  });

  describe('decodeStateJson', () => {
    it('decodes state JSON into state data objects', () => {
      const data = {
        US: [
          { label: 'California', value: 'CA', code: 'CA' },
          { label: 'New York', value: 'NY', code: 'NY' },
        ],
        GB: [
          { label: 'England', value: 'ENG', code: 'ENG' },
        ],
      };

      const result = decodeStateJson(data);

      expect(result['US']).toBeDefined();
      expect(result['US']).toHaveLength(2);
      expect(result['US'][0].label).toBe('California');
      expect(result['US'][0].value).toBe('CA');
      expect(result['US'][0].code).toBe('CA');
      expect(result['GB']).toHaveLength(1);
    });

    it('handles empty object', () => {
      const result = decodeStateJson({});
      expect(Object.keys(result)).toHaveLength(0);
    });

    it('handles non-array values by returning empty arrays', () => {
      const data = {
        US: 'not an array',
        GB: null,
      };

      const result = decodeStateJson(data);
      expect(result['US']).toEqual([]);
      expect(result['GB']).toEqual([]);
    });

    it('extracts state fields from dict items', () => {
      const data = {
        CA: [
          { label: 'Ontario', value: 'ON', code: 'ON' },
          { label: 'Quebec', value: 'QC', code: 'QC' },
        ],
      };

      const result = decodeStateJson(data);

      expect(result['CA'][0]).toEqual({
        label: 'Ontario',
        value: 'ON',
        code: 'ON',
      });
    });

    it('handles missing fields with defaults', () => {
      const data = {
        US: [{ label: 'State1' }],
      };

      const result = decodeStateJson(data);

      expect(result['US'][0].label).toBe('State1');
      expect(result['US'][0].value).toBe('');
      expect(result['US'][0].code).toBe('');
    });
  });

  describe('decodeJsonTocountryStateData', () => {
    it('decodes complete JSON with countries and states', () => {
      const jsonData = {
        country: [
          {
            country_code: 'US',
            country_name: 'United States',
            phone_number_code: '+1',
            timeZones: ['America/New_York'],
          },
        ],
        states: {
          US: [
            { label: 'California', value: 'CA', code: 'CA' },
          ],
        },
      };

      const result = decodeJsonTocountryStateData(jsonData);

      expect(result.countries).toHaveLength(1);
      expect(result.countries[0].country_code).toBe('US');
      expect(result.states['US']).toBeDefined();
      expect(result.states['US'][0].value).toBe('CA');
    });

    it('returns empty structure for null input', () => {
      const result = decodeJsonTocountryStateData(null);
      expect(result).toEqual({ countries: [], states: {} });
    });

    it('returns empty structure for non-object input', () => {
      const result = decodeJsonTocountryStateData('string');
      expect(result).toEqual({ countries: [], states: {} });
    });

    it('handles missing country array', () => {
      const jsonData = {
        states: { US: [] },
      };

      const result = decodeJsonTocountryStateData(jsonData);
      expect(result.countries).toEqual([]);
      expect(result.states).toEqual({ US: [] });
    });

    it('handles missing states object', () => {
      const jsonData = {
        country: [
          { country_code: 'US', country_name: 'US', phone_number_code: '+1', timeZones: [] },
        ],
      };

      const result = decodeJsonTocountryStateData(jsonData);
      expect(result.countries).toHaveLength(1);
      expect(result.states).toEqual({});
    });

    it('handles empty JSON object', () => {
      const result = decodeJsonTocountryStateData({});
      expect(result).toEqual({ countries: [], states: {} });
    });
  });

  describe('getLocaleStrings', () => {
    it('returns locale strings from valid data', () => {
      const data = {
        locale: 'en-GB',
        localeDirection: 'ltr',
        cardNumberLabel: 'Card Number',
        emailLabel: 'Email Address',
        payNowButton: 'Pay',
      };

      const result = getLocaleStrings(data);

      expect(result.locale).toBe('en-GB');
      expect(result.localeDirection).toBe('ltr');
      expect(result.cardNumberLabel).toBe('Card Number');
      expect(result.emailLabel).toBe('Email Address');
      expect(result.payNowButton).toBe('Pay');
    });

    it('returns defaultLocale for undefined input', () => {
      const result = getLocaleStrings(undefined);
      expect(result).toEqual(defaultLocale);
    });

    it('returns defaultLocale for null input', () => {
      const result = getLocaleStrings(null);
      expect(result).toEqual(defaultLocale);
    });

    it('uses default values for missing fields', () => {
      const data = {};
      const result = getLocaleStrings(data);

      expect(result.locale).toBe(defaultLocale.locale);
      expect(result.localeDirection).toBe(defaultLocale.localeDirection);
      expect(result.cardNumberLabel).toBe(defaultLocale.cardNumberLabel);
    });

    it('preserves all provided locale fields', () => {
      const data = {
        locale: 'fr',
        localeDirection: 'ltr',
        cardNumberLabel: 'Numéro de carte',
        cardDetailsLabel: 'Détails de la carte',
        inValidCardErrorText: 'Numéro de carte invalide',
        emailLabel: 'Courriel',
        payNowButton: 'Payer maintenant',
        billingDetails: 'Détails de facturation',
      };

      const result = getLocaleStrings(data);

      expect(result.locale).toBe('fr');
      expect(result.cardNumberLabel).toBe('Numéro de carte');
      expect(result.cardDetailsLabel).toBe('Détails de la carte');
      expect(result.inValidCardErrorText).toBe('Numéro de carte invalide');
      expect(result.emailLabel).toBe('Courriel');
      expect(result.payNowButton).toBe('Payer maintenant');
      expect(result.billingDetails).toBe('Détails de facturation');
    });

    it('handles partial locale data', () => {
      const data = {
        locale: 'de',
        cardNumberLabel: 'Kartennummer',
      };

      const result = getLocaleStrings(data);

      expect(result.locale).toBe('de');
      expect(result.cardNumberLabel).toBe('Kartennummer');
      expect(result.localeDirection).toBe(defaultLocale.localeDirection);
      expect(result.emailLabel).toBe(defaultLocale.emailLabel);
    });
  });

  describe('getLocaleStringsFromJson', () => {
    it('extracts locale strings from valid JSON object', () => {
      const jsonData = {
        locale: 'es',
        localeDirection: 'ltr',
        cardNumberLabel: 'Número de tarjeta',
        emailLabel: 'Correo electrónico',
      };

      const result = getLocaleStringsFromJson(jsonData);

      expect(result.locale).toBe('es');
      expect(result.cardNumberLabel).toBe('Número de tarjeta');
      expect(result.emailLabel).toBe('Correo electrónico');
    });

    it('returns defaultLocale for null input', () => {
      const result = getLocaleStringsFromJson(null);
      expect(result).toEqual(defaultLocale);
    });

    it('returns defaultLocale for undefined input', () => {
      const result = getLocaleStringsFromJson(undefined);
      expect(result).toEqual(defaultLocale);
    });

    it('returns defaultLocale for non-object input', () => {
      const result = getLocaleStringsFromJson('not an object');
      expect(result).toEqual(defaultLocale);
    });

    it('returns defaultLocale for number input', () => {
      const result = getLocaleStringsFromJson(123);
      expect(result).toEqual(defaultLocale);
    });

    it('handles nested object from JSON decode', () => {
      const jsonData = {
        locale: 'ja',
        localeDirection: 'ltr',
        cardNumberLabel: 'カード番号',
        payNowButton: '今すぐ支払う',
      };

      const result = getLocaleStringsFromJson(jsonData);

      expect(result.locale).toBe('ja');
      expect(result.cardNumberLabel).toBe('カード番号');
      expect(result.payNowButton).toBe('今すぐ支払う');
    });
  });
});
