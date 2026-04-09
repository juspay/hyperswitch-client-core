import {
  localeTypeToString,
  localeStringToType,
  localeStringToLocaleName,
  defaultLocale,
} from '../../shared-code/sdk-utils/types/LocaleDataType.bs.js';

describe('LocaleDataType', () => {
  describe('localeTypeToString', () => {
    it('converts English locale to string', () => {
      expect(localeTypeToString('En')).toBe('en');
    });

    it('converts French locale to string', () => {
      expect(localeTypeToString('Fr')).toBe('fr');
    });

    it('converts German locale to string', () => {
      expect(localeTypeToString('De')).toBe('de');
    });

    it('converts Japanese locale to string', () => {
      expect(localeTypeToString('Ja')).toBe('ja');
    });

    it('converts Arabic locale to string', () => {
      expect(localeTypeToString('Ar')).toBe('ar');
    });

    it('converts Hebrew locale to string', () => {
      expect(localeTypeToString('He')).toBe('he');
    });

    it('converts Spanish locale to string', () => {
      expect(localeTypeToString('Es')).toBe('es');
    });

    it('converts Portuguese locale to string', () => {
      expect(localeTypeToString('Pt')).toBe('pt');
    });

    it('returns en for undefined', () => {
      expect(localeTypeToString(undefined)).toBe('en');
    });

    it('handles en-GB locale', () => {
      expect(localeTypeToString('En_GB')).toBe('en-GB');
    });

    it('converts Hebrew locale to string', () => {
      expect(localeTypeToString('He')).toBe('he');
    });

    it('converts French Belgium locale to string', () => {
      expect(localeTypeToString('Fr_BE')).toBe('fr-BE');
    });

    it('converts Catalan locale to string', () => {
      expect(localeTypeToString('Ca')).toBe('ca');
    });

    it('converts Italian locale to string', () => {
      expect(localeTypeToString('It')).toBe('it');
    });

    it('converts Polish locale to string', () => {
      expect(localeTypeToString('Pl')).toBe('pl');
    });

    it('converts Dutch locale to string', () => {
      expect(localeTypeToString('Nl')).toBe('nl');
    });

    it('converts NI_BE locale to string', () => {
      expect(localeTypeToString('NI_BE')).toBe('nI-BE');
    });

    it('converts Swedish locale to string', () => {
      expect(localeTypeToString('Sv')).toBe('sv');
    });

    it('converts Russian locale to string', () => {
      expect(localeTypeToString('Ru')).toBe('ru');
    });

    it('converts Lithuanian locale to string', () => {
      expect(localeTypeToString('Lt')).toBe('lt');
    });

    it('converts Czech locale to string', () => {
      expect(localeTypeToString('Cs')).toBe('cs');
    });

    it('converts Slovak locale to string', () => {
      expect(localeTypeToString('Sk')).toBe('sk');
    });

    it('converts Ls locale to string', () => {
      expect(localeTypeToString('Ls')).toBe('ls');
    });

    it('converts Welsh locale to string', () => {
      expect(localeTypeToString('Cy')).toBe('cy');
    });

    it('converts Greek locale to string', () => {
      expect(localeTypeToString('El')).toBe('el');
    });

    it('converts Estonian locale to string', () => {
      expect(localeTypeToString('Et')).toBe('et');
    });

    it('converts Finnish locale to string', () => {
      expect(localeTypeToString('Fi')).toBe('fi');
    });

    it('converts Norwegian Bokmal locale to string', () => {
      expect(localeTypeToString('Nb')).toBe('nb');
    });

    it('converts Bosnian locale to string', () => {
      expect(localeTypeToString('Bs')).toBe('bs');
    });

    it('converts Danish locale to string', () => {
      expect(localeTypeToString('Da')).toBe('da');
    });

    it('converts Malay locale to string', () => {
      expect(localeTypeToString('Ms')).toBe('ms');
    });

    it('converts Turkish Cyprus locale to string', () => {
      expect(localeTypeToString('Tr_CY')).toBe('tr-CY');
    });
  });

  describe('localeStringToType', () => {
    it('converts en string to English locale type', () => {
      expect(localeStringToType('en')).toBe('En');
    });

    it('converts fr string to French locale type', () => {
      expect(localeStringToType('fr')).toBe('Fr');
    });

    it('converts de string to German locale type', () => {
      expect(localeStringToType('de')).toBe('De');
    });

    it('converts ja string to Japanese locale type', () => {
      expect(localeStringToType('ja')).toBe('Ja');
    });

    it('returns En for unknown string', () => {
      expect(localeStringToType('unknown')).toBe('En');
    });

    it('returns En for empty string', () => {
      expect(localeStringToType('')).toBe('En');
    });

    it('handles en-GB string', () => {
      expect(localeStringToType('en-GB')).toBe('En_GB');
    });

    it('converts bs string to Bosnian locale type', () => {
      expect(localeStringToType('bs')).toBe('Bs');
    });

    it('converts ca string to Catalan locale type', () => {
      expect(localeStringToType('ca')).toBe('Ca');
    });

    it('converts cs string to Czech locale type', () => {
      expect(localeStringToType('cs')).toBe('Cs');
    });

    it('converts cy string to Welsh locale type', () => {
      expect(localeStringToType('cy')).toBe('Cy');
    });

    it('converts da string to Danish locale type', () => {
      expect(localeStringToType('da')).toBe('Da');
    });

    it('converts el string to Greek locale type', () => {
      expect(localeStringToType('el')).toBe('El');
    });

    it('converts et string to Estonian locale type', () => {
      expect(localeStringToType('et')).toBe('Et');
    });

    it('converts fi string to Finnish locale type', () => {
      expect(localeStringToType('fi')).toBe('Fi');
    });

    it('converts ls string to Ls locale type', () => {
      expect(localeStringToType('ls')).toBe('Ls');
    });

    it('converts lt string to Lithuanian locale type', () => {
      expect(localeStringToType('lt')).toBe('Lt');
    });

    it('converts ms string to Malay locale type', () => {
      expect(localeStringToType('ms')).toBe('Ms');
    });

    it('converts nI-BE string to NI_BE locale type', () => {
      expect(localeStringToType('nI-BE')).toBe('NI_BE');
    });

    it('converts nb string to Norwegian Bokmal locale type', () => {
      expect(localeStringToType('nb')).toBe('Nb');
    });

    it('converts sk string to Slovak locale type', () => {
      expect(localeStringToType('sk')).toBe('Sk');
    });

    it('converts sv string to Swedish locale type', () => {
      expect(localeStringToType('sv')).toBe('Sv');
    });

    it('converts tr-CY string to Turkish Cyprus locale type', () => {
      expect(localeStringToType('tr-CY')).toBe('Tr_CY');
    });

    it('converts ar string to Arabic locale type', () => {
      expect(localeStringToType('ar')).toBe('Ar');
    });

    it('converts he string to Hebrew locale type', () => {
      expect(localeStringToType('he')).toBe('He');
    });

    it('converts it string to Italian locale type', () => {
      expect(localeStringToType('it')).toBe('It');
    });

    it('converts pl string to Polish locale type', () => {
      expect(localeStringToType('pl')).toBe('Pl');
    });

    it('converts nl string to Dutch locale type', () => {
      expect(localeStringToType('nl')).toBe('Nl');
    });

    it('converts ru string to Russian locale type', () => {
      expect(localeStringToType('ru')).toBe('Ru');
    });

    it('converts pt string to Portuguese locale type', () => {
      expect(localeStringToType('pt')).toBe('Pt');
    });

    it('converts fr-BE string to French Belgium locale type', () => {
      expect(localeStringToType('fr-BE')).toBe('Fr_BE');
    });
  });

  describe('localeStringToLocaleName', () => {
    it('converts EN to English', () => {
      expect(localeStringToLocaleName('EN')).toBe('English');
    });

    it('converts DE to German', () => {
      expect(localeStringToLocaleName('DE')).toBe('German');
    });

    it('converts FR to French', () => {
      expect(localeStringToLocaleName('FR')).toBe('French');
    });

    it('converts JA to Japanese', () => {
      expect(localeStringToLocaleName('JA')).toBe('Japanese');
    });

    it('converts ES to Spanish', () => {
      expect(localeStringToLocaleName('ES')).toBe('Spanish');
    });

    it('returns input for unknown code', () => {
      expect(localeStringToLocaleName('UNKNOWN')).toBe('UNKNOWN');
    });

    it('handles PT_BR correctly', () => {
      expect(localeStringToLocaleName('PT_BR')).toBe('Portuguese (Brazil)');
    });

    it('handles ZH_CN correctly', () => {
      expect(localeStringToLocaleName('ZH_CN')).toBe('Chinese (Simplified)');
    });

    it('handles DA correctly', () => {
      expect(localeStringToLocaleName('DA')).toBe('Danish');
    });

    it('handles DA_DK correctly', () => {
      expect(localeStringToLocaleName('DA_DK')).toBe('Danish');
    });

    it('handles DK correctly', () => {
      expect(localeStringToLocaleName('DK')).toBe('Danish');
    });

    it('handles EL correctly', () => {
      expect(localeStringToLocaleName('EL')).toBe('Greek');
    });

    it('handles EL_GR correctly', () => {
      expect(localeStringToLocaleName('EL_GR')).toBe('Greek');
    });

    it('handles GR correctly', () => {
      expect(localeStringToLocaleName('GR')).toBe('Greek');
    });

    it('handles JA_JP correctly', () => {
      expect(localeStringToLocaleName('JA_JP')).toBe('Japanese');
    });

    it('handles JP correctly', () => {
      expect(localeStringToLocaleName('JP')).toBe('Japanese');
    });

    it('handles ES_LA correctly', () => {
      expect(localeStringToLocaleName('ES_LA')).toBe('Spanish (Latin America)');
    });

    it('handles LA correctly', () => {
      expect(localeStringToLocaleName('LA')).toBe('Spanish (Latin America)');
    });

    it('handles BR correctly', () => {
      expect(localeStringToLocaleName('BR')).toBe('Portuguese (Brazil)');
    });

    it('handles SE correctly', () => {
      expect(localeStringToLocaleName('SE')).toBe('Swedish');
    });

    it('handles SV correctly', () => {
      expect(localeStringToLocaleName('SV')).toBe('Swedish');
    });

    it('handles SV_SE correctly', () => {
      expect(localeStringToLocaleName('SV_SE')).toBe('Swedish');
    });

    it('handles CN correctly', () => {
      expect(localeStringToLocaleName('CN')).toBe('Chinese (Simplified)');
    });

    it('handles TW correctly', () => {
      expect(localeStringToLocaleName('TW')).toBe('Chinese (Traditional)');
    });

    it('handles ZH correctly', () => {
      expect(localeStringToLocaleName('ZH')).toBe('Chinese (Traditional)');
    });

    it('handles ZH_TW correctly', () => {
      expect(localeStringToLocaleName('ZH_TW')).toBe('Chinese (Traditional)');
    });

    it('handles FI correctly', () => {
      expect(localeStringToLocaleName('FI')).toBe('Finnish');
    });

    it('handles HR correctly', () => {
      expect(localeStringToLocaleName('HR')).toBe('Croatian');
    });

    it('handles NO correctly', () => {
      expect(localeStringToLocaleName('NO')).toBe('Norwegian');
    });

    it('handles RU correctly', () => {
      expect(localeStringToLocaleName('RU')).toBe('Russian');
    });
  });

  describe('defaultLocale', () => {
    it('is a valid object', () => {
      expect(defaultLocale).toBeDefined();
      expect(typeof defaultLocale).toBe('object');
    });

    it('has locale field', () => {
      expect(defaultLocale.locale).toBe('en');
    });

    it('has localeDirection field', () => {
      expect(defaultLocale.localeDirection).toBe('ltr');
    });

    it('has cardNumberLabel', () => {
      expect(defaultLocale.cardNumberLabel).toBe('Card Number');
    });

    it('has cvcTextLabel', () => {
      expect(defaultLocale.cvcTextLabel).toBe('CVC');
    });

    it('has expiryPlaceholder', () => {
      expect(defaultLocale.expiryPlaceholder).toBe('MM / YY');
    });

    it('has all required i18n fields', () => {
      expect(defaultLocale).toHaveProperty('cardNumberLabel');
      expect(defaultLocale).toHaveProperty('emailLabel');
      expect(defaultLocale).toHaveProperty('inValidCardErrorText');
      expect(defaultLocale).toHaveProperty('inValidCVCErrorText');
      expect(defaultLocale).toHaveProperty('inValidExpiryErrorText');
    });

    it('fields are non-empty strings', () => {
      expect(typeof defaultLocale.cardNumberLabel).toBe('string');
      expect(defaultLocale.cardNumberLabel.length).toBeGreaterThan(0);
      expect(typeof defaultLocale.emailLabel).toBe('string');
      expect(defaultLocale.emailLabel.length).toBeGreaterThan(0);
    });
  });
});
