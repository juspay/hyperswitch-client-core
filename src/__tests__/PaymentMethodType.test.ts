const {
  getPaymentMethod,
  getWalletType,
  getExperienceType,
  getPaymentExperienceType,
} = require('../types/AllApiDataTypes/PaymentMethodType.bs.js');

describe('PaymentMethodType', () => {
  describe('getPaymentMethod', () => {
    describe('happy path', () => {
      it('returns "CARD" for "card"', () => {
        expect(getPaymentMethod('card')).toBe('CARD');
      });

      it('returns "WALLET" for "wallet"', () => {
        expect(getPaymentMethod('wallet')).toBe('WALLET');
      });

      it('returns "BANK_DEBIT" for "bank_debit"', () => {
        expect(getPaymentMethod('bank_debit')).toBe('BANK_DEBIT');
      });

      it('returns "BANK_REDIRECT" for "bank_redirect"', () => {
        expect(getPaymentMethod('bank_redirect')).toBe('BANK_REDIRECT');
      });

      it('returns "BANK_TRANSFER" for "bank_transfer"', () => {
        expect(getPaymentMethod('bank_transfer')).toBe('BANK_TRANSFER');
      });

      it('returns "CARD_REDIRECT" for "card_redirect"', () => {
        expect(getPaymentMethod('card_redirect')).toBe('CARD_REDIRECT');
      });

      it('returns "CRYPTO" for "crypto"', () => {
        expect(getPaymentMethod('crypto')).toBe('CRYPTO');
      });

      it('returns "GIFT_CARD" for "gift_card"', () => {
        expect(getPaymentMethod('gift_card')).toBe('GIFT_CARD');
      });

      it('returns "OPEN_BANKING" for "open_banking"', () => {
        expect(getPaymentMethod('open_banking')).toBe('OPEN_BANKING');
      });

      it('returns "PAY_LATER" for "pay_later"', () => {
        expect(getPaymentMethod('pay_later')).toBe('PAY_LATER');
      });

      it('returns "REWARD" for "reward"', () => {
        expect(getPaymentMethod('reward')).toBe('REWARD');
      });
    });

    describe('edge cases', () => {
      it('returns "OTHERS" for unknown string', () => {
        expect(getPaymentMethod('unknown_method')).toBe('OTHERS');
      });

      it('returns "OTHERS" for empty string', () => {
        expect(getPaymentMethod('')).toBe('OTHERS');
      });

      it('returns "OTHERS" for string with spaces', () => {
        expect(getPaymentMethod('card ')).toBe('OTHERS');
      });

      it('returns "OTHERS" for uppercase input', () => {
        expect(getPaymentMethod('CARD')).toBe('OTHERS');
      });

      it('returns "OTHERS" for partially matching string', () => {
        expect(getPaymentMethod('card_payment')).toBe('OTHERS');
      });
    });

    describe('boundary/error', () => {
      it('handles numeric string', () => {
        expect(getPaymentMethod('123')).toBe('OTHERS');
      });

      it('handles special characters', () => {
        expect(getPaymentMethod('card!')).toBe('OTHERS');
      });

      it('handles null-like string', () => {
        expect(getPaymentMethod('null')).toBe('OTHERS');
      });
    });
  });

  describe('getWalletType', () => {
    describe('happy path', () => {
      it('returns "APPLE_PAY" for "apple_pay"', () => {
        expect(getWalletType('apple_pay')).toBe('APPLE_PAY');
      });

      it('returns "GOOGLE_PAY" for "google_pay"', () => {
        expect(getWalletType('google_pay')).toBe('GOOGLE_PAY');
      });

      it('returns "PAYPAL" for "paypal"', () => {
        expect(getWalletType('paypal')).toBe('PAYPAL');
      });

      it('returns "SAMSUNG_PAY" for "samsung_pay"', () => {
        expect(getWalletType('samsung_pay')).toBe('SAMSUNG_PAY');
      });
    });

    describe('edge cases', () => {
      it('returns "NONE" for unknown wallet type', () => {
        expect(getWalletType('venmo')).toBe('NONE');
      });

      it('returns "NONE" for empty string', () => {
        expect(getWalletType('')).toBe('NONE');
      });

      it('returns "NONE" for uppercase input', () => {
        expect(getWalletType('APPLE_PAY')).toBe('NONE');
      });

      it('returns "NONE" for partial match', () => {
        expect(getWalletType('apple')).toBe('NONE');
      });

      it('returns "NONE" for string with extra characters', () => {
        expect(getWalletType('apple_pay_v2')).toBe('NONE');
      });
    });

    describe('boundary/error', () => {
      it('handles numeric string', () => {
        expect(getWalletType('123')).toBe('NONE');
      });

      it('handles special characters', () => {
        expect(getWalletType('apple-pay')).toBe('NONE');
      });

      it('handles card type mistakenly passed', () => {
        expect(getWalletType('card')).toBe('NONE');
      });
    });
  });

  describe('getExperienceType', () => {
    describe('happy path', () => {
      it('returns "INVOKE_SDK_CLIENT" for "invoke_sdk_client"', () => {
        expect(getExperienceType('invoke_sdk_client')).toBe('INVOKE_SDK_CLIENT');
      });

      it('returns "REDIRECT_TO_URL" for "redirect_to_url"', () => {
        expect(getExperienceType('redirect_to_url')).toBe('REDIRECT_TO_URL');
      });
    });

    describe('edge cases', () => {
      it('returns "NONE" for unknown experience type', () => {
        expect(getExperienceType('unknown')).toBe('NONE');
      });

      it('returns "NONE" for empty string', () => {
        expect(getExperienceType('')).toBe('NONE');
      });

      it('returns "NONE" for uppercase input', () => {
        expect(getExperienceType('INVOKE_SDK_CLIENT')).toBe('NONE');
      });

      it('returns "NONE" for partial match', () => {
        expect(getExperienceType('invoke')).toBe('NONE');
      });

      it('returns "NONE" for string with spaces', () => {
        expect(getExperienceType('invoke_sdk_client ')).toBe('NONE');
      });
    });

    describe('boundary/error', () => {
      it('handles numeric string', () => {
        expect(getExperienceType('123')).toBe('NONE');
      });

      it('handles hyphenated version', () => {
        expect(getExperienceType('invoke-sdk-client')).toBe('NONE');
      });

      it('handles camelCase', () => {
        expect(getExperienceType('invokeSdkClient')).toBe('NONE');
      });
    });
  });

  describe('getPaymentExperienceType', () => {
    describe('happy path', () => {
      it('returns "INVOKE_SDK_CLIENT" for "INVOKE_SDK_CLIENT"', () => {
        expect(getPaymentExperienceType('INVOKE_SDK_CLIENT')).toBe('INVOKE_SDK_CLIENT');
      });

      it('returns "REDIRECT_TO_URL" for "REDIRECT_TO_URL"', () => {
        expect(getPaymentExperienceType('REDIRECT_TO_URL')).toBe('REDIRECT_TO_URL');
      });

      it('returns empty string for "NONE"', () => {
        expect(getPaymentExperienceType('NONE')).toBe('');
      });
    });

    describe('edge cases', () => {
      it('returns undefined for unknown type', () => {
        expect(getPaymentExperienceType('UNKNOWN')).toBeUndefined();
      });

      it('returns undefined for empty string', () => {
        expect(getPaymentExperienceType('')).toBeUndefined();
      });

      it('returns undefined for lowercase input', () => {
        expect(getPaymentExperienceType('invoke_sdk_client')).toBeUndefined();
      });

      it('returns undefined for partial match', () => {
        expect(getPaymentExperienceType('INVOKE')).toBeUndefined();
      });
    });

    describe('boundary/error', () => {
      it('returns undefined for numeric string', () => {
        expect(getPaymentExperienceType('123')).toBeUndefined();
      });

      it('returns undefined for null-like string', () => {
        expect(getPaymentExperienceType('null')).toBeUndefined();
      });

      it('handles whitespace-padded input', () => {
        expect(getPaymentExperienceType(' INVOKE_SDK_CLIENT')).toBeUndefined();
      });
    });
  });
});
