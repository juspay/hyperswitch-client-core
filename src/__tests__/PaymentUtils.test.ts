import {
  checkIfMandate,
  showUseExisitingSavedCardsBtn,
  generateSessionsTokenBody,
  generateWalletConfirmBody,
  getActionType,
  getCardNetworks,
  generateCardConfirmBody,
  generateSavedCardConfirmBody,
} from '../utility/logics/PaymentUtils.bs.js';

describe('PaymentUtils', () => {
  describe('checkIfMandate', () => {
    it('returns true for NEW_MANDATE', () => {
      expect(checkIfMandate('NEW_MANDATE')).toBe(true);
    });

    it('returns true for SETUP_MANDATE', () => {
      expect(checkIfMandate('SETUP_MANDATE')).toBe(true);
    });

    it('returns false for NORMAL', () => {
      expect(checkIfMandate('NORMAL')).toBe(false);
    });

    it('returns false for empty string', () => {
      expect(checkIfMandate('')).toBe(false);
    });
  });

  describe('showUseExisitingSavedCardsBtn', () => {
    it('returns true when all conditions are met', () => {
      const pmList = [{id: 'pm_1'}];
      expect(showUseExisitingSavedCardsBtn(false, pmList, 'NORMAL', true)).toBe(
        true,
      );
    });

    it('returns false for guest customer', () => {
      const pmList = [{id: 'pm_1'}];
      expect(showUseExisitingSavedCardsBtn(true, pmList, 'NORMAL', true)).toBe(
        false,
      );
    });

    it('returns false for empty pmList', () => {
      expect(showUseExisitingSavedCardsBtn(false, [], 'NORMAL', true)).toBe(
        false,
      );
    });

    it('returns false for SETUP_MANDATE mandate type', () => {
      const pmList = [{id: 'pm_1'}];
      expect(
        showUseExisitingSavedCardsBtn(false, pmList, 'SETUP_MANDATE', true),
      ).toBe(false);
    });

    it('returns false when displaySavedPaymentMethods is false', () => {
      const pmList = [{id: 'pm_1'}];
      expect(
        showUseExisitingSavedCardsBtn(false, pmList, 'NORMAL', false),
      ).toBe(false);
    });

    it('handles undefined pmList', () => {
      expect(
        showUseExisitingSavedCardsBtn(false, undefined, 'NORMAL', true),
      ).toBe(false);
    });
  });

  describe('generateSessionsTokenBody', () => {
    it('generates correct sessions token body', () => {
      const clientSecret = 'pay_123_secret_abc';
      const wallet = {apple_pay: {}};
      const result = JSON.parse(
        generateSessionsTokenBody(clientSecret, wallet),
      );
      expect(result.payment_id).toBe('pay_123');
      expect(result.client_secret).toBe('pay_123_secret_abc');
      expect(result.wallets).toEqual(wallet);
    });

    it('handles empty client secret', () => {
      const result = JSON.parse(generateSessionsTokenBody('', {}));
      expect(result.payment_id).toBe('');
      expect(result.client_secret).toBe('');
    });

    it('handles client secret without separator', () => {
      const result = JSON.parse(generateSessionsTokenBody('noSeparator', {}));
      expect(result.payment_id).toBe('noSeparator');
    });
  });

  describe('generateWalletConfirmBody', () => {
    it('generates correct wallet confirmation body', () => {
      const nativeProp = {
        clientSecret: 'pay_123_secret_abc',
        hyperParams: {
          userAgent: 'test-agent',
          device_model: 'iPhone',
          os_type: 'iOS',
          os_version: '17.0',
        },
        configuration: {
          appearance: {locale: 'en'},
        },
      };
      const result = generateWalletConfirmBody(
        nativeProp,
        'wallet_token_123',
        'apple_pay',
        'NORMAL',
      );
      expect(result.client_secret).toBe('pay_123_secret_abc');
      expect(result.payment_method).toBe('wallet');
      expect(result.payment_method_type).toBe('apple_pay');
      expect(result.payment_token).toBe('wallet_token_123');
      expect(result.payment_type).toBe('NORMAL');
    });

    it('handles google_pay wallet type', () => {
      const nativeProp = {
        clientSecret: 'pay_123_secret_abc',
        hyperParams: {
          userAgent: 'test-agent',
          device_model: 'Pixel',
          os_type: 'Android',
          os_version: '14',
        },
        configuration: {
          appearance: {locale: 'en'},
        },
      };
      const result = generateWalletConfirmBody(
        nativeProp,
        'gpay_token',
        'google_pay',
        'NEW_MANDATE',
      );
      expect(result.payment_method_type).toBe('google_pay');
      expect(result.payment_type).toBe('NEW_MANDATE');
    });
  });

  describe('getActionType', () => {
    it('returns type from next action object', () => {
      const nextAction = {
        redirectToUrl: 'https://example.com',
        type_: 'redirect',
      };
      expect(getActionType(nextAction)).toBe('redirect');
    });

    it('returns three_ds type', () => {
      const nextAction = {
        redirectToUrl: '',
        type_: 'three_ds',
      };
      expect(getActionType(nextAction)).toBe('three_ds');
    });

    it('returns empty string for undefined next action', () => {
      expect(getActionType(undefined)).toBe('');
    });

    it('handles empty type_', () => {
      const nextAction = {
        redirectToUrl: '',
        type_: '',
      };
      expect(getActionType(nextAction)).toBe('');
    });
  });

  describe('getCardNetworks', () => {
    it('extracts card networks from list', () => {
      const cardNetworks = [
        {card_network: 'visa'},
        {card_network: 'mastercard'},
        {card_network: 'amex'},
      ];
      expect(getCardNetworks(cardNetworks)).toEqual([
        'visa',
        'mastercard',
        'amex',
      ]);
    });

    it('returns empty array for undefined input', () => {
      expect(getCardNetworks(undefined)).toEqual([]);
    });

    it('returns empty array for empty input', () => {
      expect(getCardNetworks([])).toEqual([]);
    });

    it('handles single network', () => {
      const cardNetworks = [{card_network: 'visa'}];
      expect(getCardNetworks(cardNetworks)).toEqual(['visa']);
    });
  });

  describe('generateCardConfirmBody', () => {
    const mockNativeProp = {
      clientSecret: 'pay_123_secret_abc',
      hyperParams: {
        appId: 'test-app',
        userAgent: 'test-agent',
        device_model: 'iPhone',
        os_type: 'iOS',
        os_version: '17.0',
      },
      configuration: {
        appearance: {locale: 'en'},
      },
    };

    it('generates body with correct client_secret', () => {
      const result = generateCardConfirmBody(
        mockNativeProp,
        'card',
        'card',
        {card: {number: '4111111111111111'}},
        'NORMAL',
        'NORMAL',
        'https://test.com',
        false,
        undefined,
        false,
        false,
        'test@example.com',
        800,
        600,
        undefined,
      );
      expect(result.client_secret).toBe('pay_123_secret_abc');
    });

    it('generates body with correct email', () => {
      const result = generateCardConfirmBody(
        mockNativeProp,
        'card',
        'card',
        {card: {number: '4111111111111111'}},
        'NORMAL',
        'NORMAL',
        'https://test.com',
        false,
        undefined,
        false,
        false,
        'user@example.com',
        800,
        600,
        undefined,
      );
      expect(result.email).toBe('user@example.com');
    });

    it('generates body with correct payment_method', () => {
      const result = generateCardConfirmBody(
        mockNativeProp,
        'card',
        'card',
        {card: {number: '4111111111111111'}},
        'NORMAL',
        'NORMAL',
        'https://test.com',
        false,
        undefined,
        false,
        false,
        'test@example.com',
        800,
        600,
        undefined,
      );
      expect(result.payment_method).toBe('card');
      expect(result.payment_method_type).toBe('card');
    });

    it('generates body with payment_type', () => {
      const result = generateCardConfirmBody(
        mockNativeProp,
        'card',
        'card',
        {card: {number: '4111111111111111'}},
        'NEW_MANDATE',
        'NEW_MANDATE',
        'https://test.com',
        false,
        undefined,
        false,
        false,
        'test@example.com',
        800,
        600,
        undefined,
      );
      expect(result.payment_type).toBe('NEW_MANDATE');
    });

    it('includes browser_info with device details', () => {
      const result = generateCardConfirmBody(
        mockNativeProp,
        'card',
        'card',
        {card: {number: '4111111111111111'}},
        'NORMAL',
        'NORMAL',
        'https://test.com',
        false,
        undefined,
        false,
        false,
        'test@example.com',
        800,
        600,
        undefined,
      );
      expect(result.browser_info).toBeDefined();
      expect(result.browser_info.user_agent).toBe('test-agent');
      expect(result.browser_info.device_model).toBe('iPhone');
      expect(result.browser_info.os_type).toBe('iOS');
      expect(result.browser_info.os_version).toBe('17.0');
    });

    it('includes screen dimensions when provided', () => {
      const result = generateCardConfirmBody(
        mockNativeProp,
        'card',
        'card',
        {card: {number: '4111111111111111'}},
        'NORMAL',
        'NORMAL',
        'https://test.com',
        false,
        undefined,
        false,
        false,
        'test@example.com',
        800,
        600,
        undefined,
      );
      expect(result.browser_info.screen_height).toBeDefined();
      expect(result.browser_info.screen_width).toBeDefined();
    });
  });

  describe('generateSavedCardConfirmBody', () => {
    const mockNativeProp = {
      clientSecret: 'pay_123_secret_abc',
      hyperParams: {
        appId: 'test-app',
        userAgent: 'test-agent',
        device_model: 'iPhone',
        os_type: 'iOS',
        os_version: '17.0',
      },
      configuration: {
        appearance: {locale: 'en'},
      },
    };

    it('generates body with correct client_secret', () => {
      const result = generateSavedCardConfirmBody(
        mockNativeProp,
        'pm_token_123',
        undefined,
        'NORMAL',
        'https://test.com',
        800,
        600,
        undefined,
      );
      expect(result.client_secret).toBe('pay_123_secret_abc');
    });

    it('generates body with payment_token', () => {
      const result = generateSavedCardConfirmBody(
        mockNativeProp,
        'pm_token_456',
        undefined,
        'NORMAL',
        'https://test.com',
        800,
        600,
        undefined,
      );
      expect(result.payment_token).toBe('pm_token_456');
    });

    it('generates body with payment_method as card', () => {
      const result = generateSavedCardConfirmBody(
        mockNativeProp,
        'pm_token_123',
        undefined,
        'NORMAL',
        'https://test.com',
        800,
        600,
        undefined,
      );
      expect(result.payment_method).toBe('card');
    });

    it('generates body with payment_type', () => {
      const result = generateSavedCardConfirmBody(
        mockNativeProp,
        'pm_token_123',
        undefined,
        'NEW_MANDATE',
        'https://test.com',
        800,
        600,
        undefined,
      );
      expect(result.payment_type).toBe('NEW_MANDATE');
    });

    it('includes browser_info with device details', () => {
      const result = generateSavedCardConfirmBody(
        mockNativeProp,
        'pm_token_123',
        undefined,
        'NORMAL',
        'https://test.com',
        800,
        600,
        undefined,
      );
      expect(result.browser_info).toBeDefined();
      expect(result.browser_info.user_agent).toBe('test-agent');
      expect(result.browser_info.device_model).toBe('iPhone');
    });

    it('includes card_cvc when savedCardCvv is provided', () => {
      const result = generateSavedCardConfirmBody(
        mockNativeProp,
        'pm_token_123',
        '123',
        'NORMAL',
        'https://test.com',
        800,
        600,
        undefined,
      );
      expect(result.card_cvc).toBe('123');
    });

    it('has undefined card_cvc when savedCardCvv is undefined', () => {
      const result = generateSavedCardConfirmBody(
        mockNativeProp,
        'pm_token_123',
        undefined,
        'NORMAL',
        'https://test.com',
        800,
        600,
        undefined,
      );
      expect(result.card_cvc).toBeUndefined();
    });

    it('includes payment_method_data when billing is provided', () => {
      const billing = {country: 'US', postal_code: '12345'};
      const result = generateSavedCardConfirmBody(
        mockNativeProp,
        'pm_token_123',
        undefined,
        'NORMAL',
        'https://test.com',
        800,
        600,
        billing,
      );
      expect(result.payment_method_data).toBeDefined();
    });
  });
});
