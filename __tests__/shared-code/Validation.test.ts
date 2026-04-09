import {
  calculateLuhn,
  cardValid,
  maxCardLength,
  cvcNumberInRange,
  checkCardExpiry,
  getCurrentMonthAndYear,
  getExpiryDates,
  getExpiryValidity,
  isEmailValid,
  isValidZip,
  isValidIban,
  containsOnlyDigits,
  containsDigit,
  clearAlphas,
  getCardBrand,
  checkCardCVC,
  slice,
  containsMoreThanTwoDigits,
  cardType,
  getobjFromCardPattern,
  getAllMatchedCardSchemes,
  isCardSchemeEnabled,
  getFirstValidCardScheme,
  getEligibleCoBadgedCardSchemes,
  isCardNumberEqualsMax,
  cvcNumberEqualsMaxLength,
  checkMaxCardCvv,
  getStrFromIndex,
  formatCardNumber,
  formatCVCNumber,
  formatCardExpiryNumber,
  getKeyboardType,
  getSecureTextEntry,
  clearSpaces,
  toInt,
  validateField,
  format,
} from '../../shared-code/sdk-utils/validation/Validation.bs.js';

describe('Validation', () => {
  describe('calculateLuhn', () => {
    it('validates valid Visa card', () => {
      expect(calculateLuhn('4111111111111111')).toBe(true);
    });

    it('validates valid Amex card', () => {
      expect(calculateLuhn('378282246310005')).toBe(true);
    });

    it('validates valid Mastercard', () => {
      expect(calculateLuhn('5555555555554444')).toBe(true);
    });

    it('rejects invalid card number', () => {
      expect(calculateLuhn('4111111111111112')).toBe(false);
    });

    it('handles all zeros', () => {
      expect(calculateLuhn('0000000000000000')).toBe(true);
    });

    it('handles empty string', () => {
      expect(calculateLuhn('')).toBe(true);
    });

    it('handles non-numeric input', () => {
      expect(calculateLuhn('abcd')).toBe(true);
    });
  });

  describe('cardValid', () => {
    it('validates valid Visa card with correct brand', () => {
      expect(cardValid('4111111111111111', 'Visa')).toBe(true);
    });

    it('rejects invalid Luhn', () => {
      expect(cardValid('4111111111111112', 'Visa')).toBe(false);
    });

    it('rejects too short card number', () => {
      expect(cardValid('411111', 'Visa')).toBe(false);
    });

    it('rejects too long card number', () => {
      expect(cardValid('41111111111111111111', 'Visa')).toBe(false);
    });

    it('validates valid Amex', () => {
      expect(cardValid('378282246310005', 'AmericanExpress')).toBe(true);
    });
  });

  describe('maxCardLength', () => {
    it('returns max length for Visa', () => {
      expect(maxCardLength('Visa')).toBe(19);
    });

    it('returns max length for AmericanExpress', () => {
      expect(maxCardLength('AmericanExpress')).toBe(15);
    });

    it('returns max length for Mastercard', () => {
      expect(maxCardLength('Mastercard')).toBe(16);
    });
  });

  describe('cvcNumberInRange', () => {
    it('validates 3-digit CVC for Visa', () => {
      expect(cvcNumberInRange('123', 'Visa')).toBe(true);
    });

    it('validates 4-digit CVC for Amex', () => {
      expect(cvcNumberInRange('1234', 'AmericanExpress')).toBe(true);
    });

    it('rejects 2-digit CVC as too short', () => {
      expect(cvcNumberInRange('12', 'Visa')).toBe(false);
    });

    it('rejects 5-digit CVC as too long', () => {
      expect(cvcNumberInRange('12345', 'Visa')).toBe(false);
    });

    it('handles empty string', () => {
      expect(cvcNumberInRange('', 'Visa')).toBe(false);
    });
  });

  describe('checkCardExpiry', () => {
    it('validates future date', () => {
      expect(checkCardExpiry('12/30')).toBe(true);
    });

    it('rejects past date', () => {
      expect(checkCardExpiry('01/20')).toBe(false);
    });

    it('rejects invalid month', () => {
      expect(checkCardExpiry('13/25')).toBe(false);
    });

    it('handles empty string', () => {
      expect(checkCardExpiry('')).toBe(false);
    });
  });

  describe('getCurrentMonthAndYear', () => {
    it('returns 2-element array', () => {
      const result = getCurrentMonthAndYear('2025-06-15T10:30:00Z');
      expect(result.length).toBe(2);
    });

    it('returns month in range 1-12', () => {
      const result = getCurrentMonthAndYear('2025-06-15T10:30:00Z');
      expect(result[0]).toBeGreaterThanOrEqual(1);
      expect(result[0]).toBeLessThanOrEqual(12);
    });

    it('returns year as number', () => {
      const result = getCurrentMonthAndYear('2025-06-15T10:30:00Z');
      expect(result[1]).toBe(2025);
    });
  });

  describe('getExpiryDates', () => {
    it('parses MM/YY format', () => {
      const result = getExpiryDates('12/25');
      expect(result[0]).toBe('12');
      expect(result[1].length).toBe(4);
    });

    it('parses single digit month', () => {
      const result = getExpiryDates('01/30');
      expect(result[0]).toBe('01');
      expect(result[1].length).toBe(4);
    });
  });

  describe('getExpiryValidity', () => {
    it('validates future expiry', () => {
      expect(getExpiryValidity('12/30')).toBe(true);
    });

    it('rejects past expiry', () => {
      expect(getExpiryValidity('01/20')).toBe(false);
    });
  });

  describe('isEmailValid', () => {
    it('validates standard email', () => {
      expect(isEmailValid('user@example.com')).toBe(true);
    });

    it('validates email with plus tag', () => {
      expect(isEmailValid('user+tag@domain.co')).toBe(true);
    });

    it('rejects email missing @', () => {
      expect(isEmailValid('userexample.com')).toBe(false);
    });

    it('rejects email missing domain', () => {
      expect(isEmailValid('user@')).toBe(false);
    });

    it('returns undefined for empty string', () => {
      expect(isEmailValid('')).toBeUndefined();
    });
  });

  describe('isValidZip', () => {
    it('validates zip code format', () => {
      expect(isValidZip('12345', 'US')).toBeDefined();
    });

    it('rejects invalid zip', () => {
      expect(isValidZip('abc', 'US')).toBe(false);
    });

    it('returns false for empty string', () => {
      expect(isValidZip('', 'US')).toBe(false);
    });
  });

  describe('isValidIban', () => {
    it('validates non-empty IBAN', () => {
      expect(isValidIban('GB82WEST12345698765432')).toBe(true);
    });

    it('rejects empty IBAN', () => {
      expect(isValidIban('')).toBe(false);
    });

    it('rejects whitespace-only IBAN', () => {
      expect(isValidIban('   ')).toBe(false);
    });
  });

  describe('containsOnlyDigits', () => {
    it('returns true for digits only', () => {
      expect(containsOnlyDigits('12345')).toBe(true);
    });

    it('returns false for mixed content', () => {
      expect(containsOnlyDigits('123a5')).toBe(false);
    });

    it('returns true for empty string', () => {
      expect(containsOnlyDigits('')).toBe(true);
    });
  });

  describe('containsDigit', () => {
    it('returns true when string contains digit', () => {
      expect(containsDigit('abc1')).toBe(true);
    });

    it('returns false when string has no digits', () => {
      expect(containsDigit('abc')).toBe(false);
    });

    it('returns false for empty string', () => {
      expect(containsDigit('')).toBe(false);
    });
  });

  describe('clearAlphas', () => {
    it('removes non-digit characters (keeps digits and spaces)', () => {
      expect(clearAlphas('abc123!@#')).toBe('123');
    });

    it('handles special characters only', () => {
      expect(clearAlphas('!@#$')).toBe('');
    });

    it('preserves spaces', () => {
      expect(clearAlphas('abc 123')).toBe(' 123');
    });

    it('removes alphabetic characters', () => {
      expect(clearAlphas('abc')).toBe('');
    });
  });

  describe('getCardBrand', () => {
    it('identifies Visa card', () => {
      expect(getCardBrand('4111111111111111')).toBe('Visa');
    });

    it('identifies Mastercard', () => {
      expect(getCardBrand('5555555555554444')).toBe('Mastercard');
    });

    it('identifies AmericanExpress', () => {
      expect(getCardBrand('378282246310005')).toBe('AmericanExpress');
    });

    it('returns empty string for invalid input', () => {
      expect(getCardBrand('')).toBe('');
    });
  });

  describe('checkCardCVC', () => {
    it('validates CVC for Visa', () => {
      expect(checkCardCVC('123', 'Visa')).toBe(true);
    });

    it('validates CVC for Amex', () => {
      expect(checkCardCVC('1234', 'AmericanExpress')).toBe(true);
    });

    it('rejects empty CVC', () => {
      expect(checkCardCVC('', 'Visa')).toBe(false);
    });
  });

  describe('slice', () => {
    it('slices string with start and end', () => {
      expect(slice('hello world', 0, 5)).toBe('hello');
    });

    it('slices from middle', () => {
      expect(slice('hello world', 6, 11)).toBe('world');
    });

    it('handles negative start', () => {
      expect(slice('hello', -3, 5)).toBe('llo');
    });

    it('returns empty for out of bounds', () => {
      expect(slice('hi', 10, 20)).toBe('');
    });
  });

  describe('containsMoreThanTwoDigits', () => {
    it('returns true for three digits', () => {
      expect(containsMoreThanTwoDigits('abc123def')).toBe(true);
    });

    it('returns true for many digits', () => {
      expect(containsMoreThanTwoDigits('1a2b3c4d5e')).toBe(true);
    });

    it('returns false for exactly two digits', () => {
      expect(containsMoreThanTwoDigits('a1b2c')).toBe(false);
    });

    it('returns false for one digit', () => {
      expect(containsMoreThanTwoDigits('abc1def')).toBe(false);
    });

    it('returns false for no digits', () => {
      expect(containsMoreThanTwoDigits('abcdef')).toBe(false);
    });

    it('returns false for empty string', () => {
      expect(containsMoreThanTwoDigits('')).toBe(false);
    });
  });

  describe('cardType', () => {
    it('returns AMEX for amex', () => {
      expect(cardType('amex')).toBe('AMEX');
    });

    it('returns VISA for visa (case-insensitive)', () => {
      expect(cardType('visa')).toBe('VISA');
    });

    it('returns MASTERCARD for mastercard', () => {
      expect(cardType('mastercard')).toBe('MASTERCARD');
    });

    it('returns NOTFOUND for unknown card type', () => {
      expect(cardType('unknown')).toBe('NOTFOUND');
    });

    it('returns NOTFOUND for empty string', () => {
      expect(cardType('')).toBe('NOTFOUND');
    });

    it('returns DINERSCLUB for dinersclub', () => {
      expect(cardType('dinersclub')).toBe('DINERSCLUB');
    });

    it('returns JCB for jcb', () => {
      expect(cardType('jcb')).toBe('JCB');
    });
  });

  describe('getobjFromCardPattern', () => {
    it('returns Visa pattern for Visa', () => {
      const result = getobjFromCardPattern('Visa');
      expect(result.issuer).toBe('Visa');
      expect(result.maxCVCLength).toBe(3);
    });

    it('returns Mastercard pattern for Mastercard', () => {
      const result = getobjFromCardPattern('Mastercard');
      expect(result.issuer).toBe('Mastercard');
    });

    it('returns default pattern for unknown brand', () => {
      const result = getobjFromCardPattern('UnknownBrand');
      expect(result.issuer).toBe('');
    });

    it('returns AmericanExpress pattern with 4-digit CVC', () => {
      const result = getobjFromCardPattern('AmericanExpress');
      expect(result.maxCVCLength).toBe(4);
    });
  });

  describe('getAllMatchedCardSchemes', () => {
    it('returns Visa for Visa card number', () => {
      const result = getAllMatchedCardSchemes('4111111111111111');
      expect(result).toContain('Visa');
    });

    it('returns Mastercard for Mastercard number', () => {
      const result = getAllMatchedCardSchemes('5555555555554444');
      expect(result).toContain('Mastercard');
    });

    it('returns empty array for non-matching number', () => {
      const result = getAllMatchedCardSchemes('0000000000000000');
      expect(result).toEqual([]);
    });

    it('handles empty string', () => {
      const result = getAllMatchedCardSchemes('');
      expect(result).toEqual([]);
    });
  });

  describe('isCardSchemeEnabled', () => {
    it('returns true when scheme is enabled', () => {
      expect(isCardSchemeEnabled('Visa', ['Visa', 'Mastercard'])).toBe(true);
    });

    it('returns false when scheme is not enabled', () => {
      expect(isCardSchemeEnabled('Amex', ['Visa', 'Mastercard'])).toBe(false);
    });

    it('returns false for empty enabled list', () => {
      expect(isCardSchemeEnabled('Visa', [])).toBe(false);
    });

    it('handles case-sensitive match', () => {
      expect(isCardSchemeEnabled('visa', ['Visa'])).toBe(false);
    });
  });

  describe('getFirstValidCardScheme', () => {
    it('returns first matching enabled scheme', () => {
      const result = getFirstValidCardScheme('4111111111111111', [
        'Visa',
        'Mastercard',
      ]);
      expect(result).toBe('Visa');
    });

    it('returns empty string when no scheme matches', () => {
      const result = getFirstValidCardScheme('4111111111111111', ['Amex']);
      expect(result).toBe('');
    });

    it('returns empty string for empty enabled list', () => {
      const result = getFirstValidCardScheme('4111111111111111', []);
      expect(result).toBe('');
    });
  });

  describe('getEligibleCoBadgedCardSchemes', () => {
    it('filters matched schemes to enabled ones', () => {
      const result = getEligibleCoBadgedCardSchemes(
        ['Visa', 'Mastercard'],
        ['Visa'],
      );
      expect(result).toEqual(['Visa']);
    });

    it('returns empty when no matches', () => {
      const result = getEligibleCoBadgedCardSchemes(['Amex'], ['Visa']);
      expect(result).toEqual([]);
    });

    it('returns all when all are enabled', () => {
      const result = getEligibleCoBadgedCardSchemes(
        ['Visa', 'Mastercard'],
        ['Visa', 'Mastercard'],
      );
      expect(result).toEqual(['Visa', 'Mastercard']);
    });

    it('handles empty matched list', () => {
      const result = getEligibleCoBadgedCardSchemes([], ['Visa']);
      expect(result).toEqual([]);
    });
  });

  describe('isCardNumberEqualsMax', () => {
    it('returns true when length equals max for Visa (19)', () => {
      expect(isCardNumberEqualsMax('4111111111111111111', 'Visa')).toBe(true);
    });

    it('returns true when length is 16 for unknown brand', () => {
      expect(isCardNumberEqualsMax('4111111111111111', 'UnknownBrand')).toBe(
        true,
      );
    });

    it('returns false when length is less than max and not 16', () => {
      expect(isCardNumberEqualsMax('4111111111111', 'Visa')).toBe(false);
    });

    it('returns true for 16-digit Amex (fallback to 16)', () => {
      expect(isCardNumberEqualsMax('378282246310005', 'AmericanExpress')).toBe(
        true,
      );
    });
  });

  describe('cvcNumberEqualsMaxLength', () => {
    it('returns true when CVC length equals max for Visa (3)', () => {
      expect(cvcNumberEqualsMaxLength('123', 'Visa')).toBe(true);
    });

    it('returns true when CVC length equals max for Amex (4)', () => {
      expect(cvcNumberEqualsMaxLength('1234', 'AmericanExpress')).toBe(true);
    });

    it('returns false when CVC length is less than max', () => {
      expect(cvcNumberEqualsMaxLength('12', 'Visa')).toBe(false);
    });

    it('returns false when CVC length exceeds max', () => {
      expect(cvcNumberEqualsMaxLength('12345', 'Visa')).toBe(false);
    });
  });

  describe('checkMaxCardCvv', () => {
    it('returns true when CVC equals max length', () => {
      expect(checkMaxCardCvv('123', 'Visa')).toBe(true);
    });

    it('returns true when CVC equals max length for Amex', () => {
      expect(checkMaxCardCvv('1234', 'AmericanExpress')).toBe(true);
    });

    it('returns false when CVC does not equal max length', () => {
      expect(checkMaxCardCvv('12', 'Visa')).toBe(false);
    });

    it('returns false for empty CVC', () => {
      expect(checkMaxCardCvv('', 'Visa')).toBe(false);
    });
  });

  describe('getStrFromIndex', () => {
    it('returns string at valid index', () => {
      expect(getStrFromIndex(['a', 'b', 'c'], 1)).toBe('b');
    });

    it('returns empty string for out of bounds', () => {
      expect(getStrFromIndex(['a', 'b'], 10)).toBe('');
    });

    it('returns first element at index 0', () => {
      expect(getStrFromIndex(['first', 'second'], 0)).toBe('first');
    });

    it('returns empty string for empty array', () => {
      expect(getStrFromIndex([], 0)).toBe('');
    });
  });

  describe('formatCardNumber', () => {
    it('formats Visa card with spaces', () => {
      const result = formatCardNumber('4111111111111111', 'VISA');
      expect(result).toBe('4111 1111 1111 1111');
    });

    it('formats Amex card with different spacing', () => {
      const result = formatCardNumber('378282246310005', 'AMEX');
      expect(result).toBe('3782 822463 10005');
    });

    it('formats DinersClub card with 14 digits', () => {
      const result = formatCardNumber('38520000023237', 'DINERSCLUB');
      expect(result).toBe('3852 000002 3237');
    });

    it('formats DinersClub card with more than 14 digits', () => {
      const result = formatCardNumber('38520000023237123', 'DINERSCLUB');
      expect(result).toBe('3852 0000 0232 3712   3');
    });

    it('formats unknown card type with default spacing', () => {
      const result = formatCardNumber('1234567890123456789', 'UNKNOWN');
      expect(result).toBe('1234 5678 9012 3456789');
    });

    it('formats Mastercard with spaces', () => {
      const result = formatCardNumber('5555555555554444', 'MASTERCARD');
      expect(result).toBe('5555 5555 5555 4444');
    });
  });

  describe('formatCVCNumber', () => {
    it('formats CVC to max 3 digits for Visa', () => {
      expect(formatCVCNumber('12345', 'Visa')).toBe('123');
    });

    it('formats CVC to max 4 digits for Amex', () => {
      expect(formatCVCNumber('12345', 'AmericanExpress')).toBe('1234');
    });

    it('keeps short CVC unchanged', () => {
      expect(formatCVCNumber('12', 'Visa')).toBe('12');
    });

    it('handles empty CVC', () => {
      expect(formatCVCNumber('', 'Visa')).toBe('');
    });
  });

  describe('formatCardExpiryNumber', () => {
    it('formats single digit month 2-9 with leading zero', () => {
      expect(formatCardExpiryNumber('5')).toBe('05 / ');
    });

    it('formats two-digit month > 12 correctly', () => {
      expect(formatCardExpiryNumber('15')).toBe('01 / 5');
    });

    it('formats valid month 12 unchanged', () => {
      expect(formatCardExpiryNumber('12')).toBe('12');
    });

    it('formats 3+ digits with separator', () => {
      expect(formatCardExpiryNumber('1225')).toBe('12 / 25');
    });

    it('handles 1-digit month 0-1 unchanged', () => {
      expect(formatCardExpiryNumber('1')).toBe('1');
    });

    it('handles 5 digits', () => {
      expect(formatCardExpiryNumber('12345')).toBe('12 / 34');
    });
  });

  describe('getKeyboardType', () => {
    it('returns numeric for CardNumber', () => {
      expect(getKeyboardType('CardNumber')).toBe('numeric');
    });

    it('returns email-address for Email', () => {
      expect(getKeyboardType('Email')).toBe('email-address');
    });

    it('returns phone-pad for Phone', () => {
      expect(getKeyboardType('Phone')).toBe('phone-pad');
    });

    it('returns numeric for CardExpiry', () => {
      expect(getKeyboardType({TAG: 'CardExpiry', _0: ''})).toBe('numeric');
    });

    it('returns numeric for CardCVC', () => {
      expect(getKeyboardType({TAG: 'CardCVC', _0: 'Visa'})).toBe('numeric');
    });

    it('returns default for unknown type', () => {
      expect(getKeyboardType('Unknown')).toBe('default');
    });

    it('returns default for other object types', () => {
      expect(getKeyboardType({TAG: 'MinLength', _0: 5})).toBe('default');
    });
  });

  describe('getSecureTextEntry', () => {
    it('returns true for CardCVC', () => {
      expect(getSecureTextEntry({TAG: 'CardCVC', _0: 'Visa'})).toBe(true);
    });

    it('returns false for CardNumber', () => {
      expect(getSecureTextEntry('CardNumber')).toBe(false);
    });

    it('returns false for Email', () => {
      expect(getSecureTextEntry('Email')).toBe(false);
    });

    it('returns false for CardExpiry', () => {
      expect(getSecureTextEntry({TAG: 'CardExpiry', _0: ''})).toBe(false);
    });
  });

  describe('clearSpaces', () => {
    it('removes non-digit characters', () => {
      expect(clearSpaces('4111 1111 1111 1111')).toBe('4111111111111111');
    });

    it('removes letters and symbols', () => {
      expect(clearSpaces('abc123def')).toBe('123');
    });

    it('handles empty string', () => {
      expect(clearSpaces('')).toBe('');
    });

    it('handles digits only', () => {
      expect(clearSpaces('123456')).toBe('123456');
    });
  });

  describe('toInt', () => {
    it('converts valid number string', () => {
      expect(toInt('42')).toBe(42);
    });

    it('returns 0 for invalid string', () => {
      expect(toInt('abc')).toBe(0);
    });

    it('returns 0 for empty string', () => {
      expect(toInt('')).toBe(0);
    });

    it('handles negative numbers', () => {
      expect(toInt('-5')).toBe(-5);
    });
  });

  describe('cardType - additional cases', () => {
    it('returns BAJAJ for bajaj', () => {
      expect(cardType('bajaj')).toBe('BAJAJ');
    });

    it('returns CARTESBANCAIRES for cartesbancaires', () => {
      expect(cardType('cartesbancaires')).toBe('CARTESBANCAIRES');
    });

    it('returns DISCOVER for discover', () => {
      expect(cardType('discover')).toBe('DISCOVER');
    });

    it('returns INTERAC for interac', () => {
      expect(cardType('interac')).toBe('INTERAC');
    });

    it('returns MAESTRO for maestro', () => {
      expect(cardType('maestro')).toBe('MAESTRO');
    });

    it('returns RUPAY for rupay', () => {
      expect(cardType('rupay')).toBe('RUPAY');
    });

    it('returns SODEXO for sodexo', () => {
      expect(cardType('sodexo')).toBe('SODEXO');
    });

    it('returns UNIONPAY for unionpay', () => {
      expect(cardType('unionpay')).toBe('UNIONPAY');
    });
  });

  describe('validateField', () => {
    const localeObject = {
      mandatoryFieldText: 'This field is required',
      cardNumberEmptyText: 'Card number is empty',
      inValidCardErrorText: 'Invalid card number',
      emailEmptyText: 'Email is empty',
      emailInvalidText: 'Invalid email',
      cardHolderNameRequiredText: 'Name is required',
      invalidDigitsCardHolderNameError: 'Name cannot contain digits',
      lastNameRequiredText: 'Last name is required',
      cardExpiryDateEmptyText: 'Expiry date is empty',
      inValidExpiryErrorText: 'Invalid expiry date',
      cvcNumberEmptyText: 'CVC is empty',
      inValidCVCErrorText: 'Invalid CVC',
      unsupportedCardErrorText: 'Unsupported card',
    };

    describe('Required rule', () => {
      it('returns error for empty value', () => {
        const result = validateField('', ['Required'], [], localeObject);
        expect(result).toBe('This field is required');
      });

      it('returns error for whitespace-only value', () => {
        const result = validateField('   ', ['Required'], [], localeObject);
        expect(result).toBe('This field is required');
      });

      it('returns undefined for valid value', () => {
        const result = validateField('test', ['Required'], [], localeObject);
        expect(result).toBeUndefined();
      });
    });

    describe('CardNumber rule', () => {
      it('returns error for empty card number', () => {
        const result = validateField(
          '',
          ['CardNumber'],
          ['Visa'],
          localeObject,
        );
        expect(result).toBe('Card number is empty');
      });

      it('returns error for invalid card number', () => {
        const result = validateField(
          '4111111111111112',
          ['CardNumber'],
          ['Visa'],
          localeObject,
        );
        expect(result).toBe('Invalid card number');
      });

      it('returns undefined for valid Visa card', () => {
        const result = validateField(
          '4111111111111111',
          ['CardNumber'],
          ['Visa'],
          localeObject,
        );
        expect(result).toBeUndefined();
      });
    });

    describe('Email rule', () => {
      it('returns error for empty email', () => {
        const result = validateField('', ['Email'], [], localeObject);
        expect(result).toBe('Email is empty');
      });

      it('returns error for invalid email', () => {
        const result = validateField(
          'invalid-email',
          ['Email'],
          [],
          localeObject,
        );
        expect(result).toBe('Invalid email');
      });

      it('returns undefined for valid email', () => {
        const result = validateField(
          'test@example.com',
          ['Email'],
          [],
          localeObject,
        );
        expect(result).toBeUndefined();
      });
    });

    describe('FirstName rule', () => {
      it('returns error for empty name', () => {
        const result = validateField('', ['FirstName'], [], localeObject);
        expect(result).toBe('Name is required');
      });

      it('returns error for name with digits', () => {
        const result = validateField(
          'John123',
          ['FirstName'],
          [],
          localeObject,
        );
        expect(result).toBe('Name cannot contain digits');
      });

      it('returns undefined for valid name', () => {
        const result = validateField('John', ['FirstName'], [], localeObject);
        expect(result).toBeUndefined();
      });
    });

    describe('LastName rule', () => {
      it('returns error for empty last name', () => {
        const result = validateField('', ['LastName'], [], localeObject);
        expect(result).toBe('Last name is required');
      });

      it('returns error for last name with digits', () => {
        const result = validateField('Doe123', ['LastName'], [], localeObject);
        expect(result).toBe('Name cannot contain digits');
      });

      it('returns undefined for valid last name', () => {
        const result = validateField('Doe', ['LastName'], [], localeObject);
        expect(result).toBeUndefined();
      });
    });

    describe('Phone rule', () => {
      it('returns error for short phone number', () => {
        const result = validateField('12345', ['Phone'], [], localeObject);
        expect(result).toBe('Enter a valid phone number');
      });

      it('returns undefined for valid phone number', () => {
        const result = validateField('1234567890', ['Phone'], [], localeObject);
        expect(result).toBeUndefined();
      });
    });

    describe('IBAN rule', () => {
      it('returns error for empty IBAN', () => {
        const result = validateField('', ['IBAN'], [], localeObject);
        expect(result).toBe('Enter a valid IBAN');
      });

      it('returns undefined for valid IBAN', () => {
        const result = validateField(
          'GB82WEST12345698765432',
          ['IBAN'],
          [],
          localeObject,
        );
        expect(result).toBeUndefined();
      });
    });

    describe('MinLength rule', () => {
      it('returns error for value too short', () => {
        const result = validateField(
          'ab',
          [{TAG: 'MinLength', _0: 5}],
          [],
          localeObject,
        );
        expect(result).toBe('Minimum 5 characters required');
      });

      it('returns undefined for value long enough', () => {
        const result = validateField(
          'abcdef',
          [{TAG: 'MinLength', _0: 5}],
          [],
          localeObject,
        );
        expect(result).toBeUndefined();
      });
    });

    describe('MaxLength rule', () => {
      it('returns error for value too long', () => {
        const result = validateField(
          'abcdefgh',
          [{TAG: 'MaxLength', _0: 5}],
          [],
          localeObject,
        );
        expect(result).toBe('Maximum 5 characters allowed');
      });

      it('returns undefined for value short enough', () => {
        const result = validateField(
          'ab',
          [{TAG: 'MaxLength', _0: 5}],
          [],
          localeObject,
        );
        expect(result).toBeUndefined();
      });
    });

    describe('CardExpiry rule', () => {
      it('returns error for empty expiry', () => {
        const result = validateField(
          '',
          [{TAG: 'CardExpiry', _0: ''}],
          [],
          localeObject,
        );
        expect(result).toBe('Expiry date is empty');
      });

      it('returns error for invalid expiry', () => {
        const result = validateField(
          '',
          [{TAG: 'CardExpiry', _0: '01/20'}],
          [],
          localeObject,
        );
        expect(result).toBe('Invalid expiry date');
      });

      it('returns undefined for valid expiry', () => {
        const result = validateField(
          '',
          [{TAG: 'CardExpiry', _0: '12/30'}],
          [],
          localeObject,
        );
        expect(result).toBeUndefined();
      });
    });

    describe('CardCVC rule', () => {
      it('returns error for empty CVC', () => {
        const result = validateField(
          '',
          [{TAG: 'CardCVC', _0: 'Visa'}],
          [],
          localeObject,
        );
        expect(result).toBe('CVC is empty');
      });

      it('returns error for invalid CVC', () => {
        const result = validateField(
          '12',
          [{TAG: 'CardCVC', _0: 'Visa'}],
          [],
          localeObject,
        );
        expect(result).toBe('Invalid CVC');
      });

      it('returns undefined for valid CVC', () => {
        const result = validateField(
          '123',
          [{TAG: 'CardCVC', _0: 'Visa'}],
          [],
          localeObject,
        );
        expect(result).toBeUndefined();
      });
    });

    describe('CardNetwork rule', () => {
      it('returns error for unsupported network', () => {
        const result = validateField(
          'amex',
          [{TAG: 'CardNetwork', _0: ['visa', 'mastercard']}],
          [],
          localeObject,
        );
        expect(result).toBe('Unsupported card');
      });

      it('returns undefined for supported network', () => {
        const result = validateField(
          'visa',
          [{TAG: 'CardNetwork', _0: ['visa', 'mastercard']}],
          [],
          localeObject,
        );
        expect(result).toBeUndefined();
      });
    });

    describe('PostalCode rule', () => {
      it('returns error for invalid postal code', () => {
        const result = validateField(
          'abc',
          [{TAG: 'PostalCode', _0: 'US'}],
          [],
          localeObject,
        );
        expect(result).toBe('Enter a valid postal code');
      });
    });
  });

  describe('getCardBrand - RuPay range', () => {
    it('identifies RuPay card in range 508227', () => {
      expect(getCardBrand('5082271234567890')).toBe('RUPAY');
    });

    it('identifies RuPay card in range 606985-607384', () => {
      expect(getCardBrand('6070001234567890')).toBe('RUPAY');
    });

    it('identifies Mastercard in range 222100-272099', () => {
      expect(getCardBrand('2221001234567890')).toBe('MASTERCARD');
    });
  });

  describe('maxCardLength - else branch', () => {
    it('returns max length for DinersClub', () => {
      expect(maxCardLength('DinersClub')).toBe(19);
    });

    it('returns max length for Discover', () => {
      expect(maxCardLength('Discover')).toBe(16);
    });

    it('returns 19 for unknown brand (default)', () => {
      expect(maxCardLength('UnknownBrand')).toBe(19);
    });
  });

  describe('format', () => {
    it('formats card number for CardNumber rule', () => {
      const result = format('4111111111111111', 'CardNumber');
      expect(result).toBe('4111 1111 1111 1111');
    });

    it('returns value unchanged for non-CardNumber string rule', () => {
      const result = format('test', 'Email');
      expect(result).toBe('test');
    });

    it('formats expiry for CardExpiry rule with slash', () => {
      const result = format('', {TAG: 'CardExpiry', _0: '12/25'});
      expect(result).toBe('12 / 25');
    });

    it('formats expiry for CardExpiry rule without slash (length <= 5)', () => {
      const result = format('', {TAG: 'CardExpiry', _0: '1225'});
      expect(result).toBe('12 / 25');
    });

    it('returns substring for CardExpiry rule without slash (length > 5)', () => {
      const result = format('', {TAG: 'CardExpiry', _0: '122599'});
      expect(result).toBe('1225');
    });

    it('formats CVC for CardCVC rule', () => {
      const result = format('12345', {TAG: 'CardCVC', _0: 'Visa'});
      expect(result).toBe('1234');
    });

    it('returns value unchanged for default object rule', () => {
      const result = format('test', {TAG: 'MinLength', _0: 5});
      expect(result).toBe('test');
    });
  });
});
