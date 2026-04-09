import {
  toInt,
  clearSpaces,
  slice,
  cardType,
  formatCardNumber,
  splitExpiryDates,
  formatCardExpiryNumber,
  formatCVCNumber,
  getStrFromIndex,
  getobjFromCardPattern,
  getAllMatchedCardSchemes,
  isCardSchemeEnabled,
} from '../../shared-code/sdk-utils/validation/CardValidations.bs.js';

describe('CardValidations', () => {
  describe('clearSpaces', () => {
    it('removes spaces from card number', () => {
      expect(clearSpaces('4111 1111 1111 1111')).toBe('4111111111111111');
    });

    it('removes dashes from card number', () => {
      expect(clearSpaces('4111-1111-1111-1111')).toBe('4111111111111111');
    });

    it('returns unchanged string when already clean', () => {
      expect(clearSpaces('4111111111111111')).toBe('4111111111111111');
    });

    it('returns empty string for empty input', () => {
      expect(clearSpaces('')).toBe('');
    });

    it('removes all non-digit characters', () => {
      expect(clearSpaces('4111abcd1111efgh1111ijkl')).toBe('411111111111');
    });
  });

  describe('toInt', () => {
    it('converts valid number string to integer', () => {
      expect(toInt('42')).toBe(42);
    });

    it('returns 0 for non-number string', () => {
      expect(toInt('abc')).toBe(0);
    });

    it('returns 0 for empty string', () => {
      expect(toInt('')).toBe(0);
    });

    it('handles negative numbers', () => {
      expect(toInt('-5')).toBe(-5);
    });
  });

  describe('cardType', () => {
    it('returns VISA for visa (case insensitive)', () => {
      expect(cardType('visa')).toBe('VISA');
    });

    it('returns MASTERCARD for mastercard', () => {
      expect(cardType('mastercard')).toBe('MASTERCARD');
    });

    it('returns AMEX for amex', () => {
      expect(cardType('amex')).toBe('AMEX');
    });

    it('returns NOTFOUND for unknown brand', () => {
      expect(cardType('unknown_brand')).toBe('NOTFOUND');
    });

    it('returns NOTFOUND for empty string', () => {
      expect(cardType('')).toBe('NOTFOUND');
    });

    it('handles DINERSCLUB', () => {
      expect(cardType('dinersclub')).toBe('DINERSCLUB');
    });

    it('handles DISCOVER', () => {
      expect(cardType('discover')).toBe('DISCOVER');
    });

    it('handles JCB', () => {
      expect(cardType('jcb')).toBe('JCB');
    });

    it('handles CARTESBANCAIRES', () => {
      expect(cardType('cartesbancaires')).toBe('CARTESBANCAIRES');
    });

    it('handles MAESTRO', () => {
      expect(cardType('maestro')).toBe('MAESTRO');
    });

    it('handles RUPAY', () => {
      expect(cardType('rupay')).toBe('RUPAY');
    });

    it('handles SODEXO', () => {
      expect(cardType('sodexo')).toBe('SODEXO');
    });

    it('handles BAJAJ', () => {
      expect(cardType('bajaj')).toBe('BAJAJ');
    });
  });

  describe('formatCardNumber', () => {
    it('formats 16-digit Visa card with spaces', () => {
      expect(formatCardNumber('4111111111111111', 'VISA')).toBe(
        '4111 1111 1111 1111',
      );
    });

    it('formats 15-digit Amex card with 4-6-5 pattern', () => {
      expect(formatCardNumber('378282246310005', 'AMEX')).toBe(
        '3782 822463 10005',
      );
    });

    it('returns partial input unchanged when too short', () => {
      expect(formatCardNumber('4111', 'VISA')).toBe('4111');
    });

    it('returns empty string for empty input', () => {
      expect(formatCardNumber('', 'VISA')).toBe('');
    });

    it('formats Mastercard correctly', () => {
      expect(formatCardNumber('5555555555554444', 'MASTERCARD')).toBe(
        '5555 5555 5555 4444',
      );
    });

    it('formats DinersClub correctly', () => {
      expect(formatCardNumber('38520000023237', 'DINERSCLUB')).toBe(
        '3852 000002 3237',
      );
    });

    it('formats unknown card type with default pattern', () => {
      expect(formatCardNumber('1234567890123456789', 'UNKNOWN')).toBe(
        '1234 5678 9012 3456789',
      );
    });

    it('formats DISCOVER card correctly', () => {
      expect(formatCardNumber('6011111111111117', 'DISCOVER')).toBe(
        '6011 1111 1111 1117',
      );
    });

    it('formats RUPAY card correctly', () => {
      expect(formatCardNumber('6070123456789012', 'RUPAY')).toBe(
        '6070 1234 5678 9012',
      );
    });

    it('formats SODEXO card correctly', () => {
      expect(formatCardNumber('1234567890123456', 'SODEXO')).toBe(
        '1234 5678 9012 3456',
      );
    });

    it('formats DinersClub with length > 14', () => {
      expect(formatCardNumber('38520000023237888', 'DINERSCLUB')).toBe(
        '3852 0000 0232 3788   8',
      );
    });
  });

  describe('splitExpiryDates', () => {
    it('splits valid expiry date MM/YY', () => {
      const result = splitExpiryDates('12/25');
      expect(result[0]).toBe('12');
      expect(result[1]).toBe('25');
    });

    it('handles single digit month', () => {
      const result = splitExpiryDates('1/25');
      expect(result[0]).toBe('1');
      expect(result[1]).toBe('25');
    });

    it('returns empty strings for empty input', () => {
      const result = splitExpiryDates('');
      expect(result[0]).toBe('');
      expect(result[1]).toBe('');
    });

    it('handles date without separator', () => {
      const result = splitExpiryDates('1225');
      expect(result[0]).toBe('1225');
      expect(result[1]).toBe('');
    });
  });

  describe('formatCardExpiryNumber', () => {
    it('formats single digit 2-9 with leading zero', () => {
      expect(formatCardExpiryNumber('2')).toBe('02 / ');
    });

    it('formats partial input correctly', () => {
      expect(formatCardExpiryNumber('1')).toBe('1');
    });

    it('returns empty string for empty input', () => {
      expect(formatCardExpiryNumber('')).toBe('');
    });

    it('formats 3+ digits with separator', () => {
      expect(formatCardExpiryNumber('122')).toBe('12 / 2');
    });

    it('formats 4 digits correctly', () => {
      expect(formatCardExpiryNumber('1225')).toBe('12 / 25');
    });

    it('handles month > 12 by reformatting', () => {
      const result = formatCardExpiryNumber('15');
      expect(result).toBe('01 / 5');
    });

    // Edge case: "0" — single digit below the 2-9 auto-prefix range
    it('does not auto-prefix single digit 0', () => {
      expect(formatCardExpiryNumber('0')).toBe('0');
    });

    // Edge case: "10" — two-digit value <= 12, should pass through
    it('keeps valid two-digit month 10 as-is', () => {
      expect(formatCardExpiryNumber('10')).toBe('10');
    });

    // Edge case: "00" — invalid month, two digits both zero
    it('handles 00 as two-digit input (not > 12, passes through)', () => {
      expect(formatCardExpiryNumber('00')).toBe('00');
    });

    // Edge case: single digit 9 — upper boundary of auto-prefix range
    it('auto-prefixes single digit 9', () => {
      expect(formatCardExpiryNumber('9')).toBe('09 / ');
    });

    // Edge case: "1" — single digit at lower boundary, should NOT auto-prefix
    it('does not auto-prefix single digit 1 (below 2-9 range)', () => {
      expect(formatCardExpiryNumber('1')).toBe('1');
    });
  });

  describe('formatCVCNumber', () => {
    it('formats 3-digit CVC for Visa', () => {
      expect(formatCVCNumber('123', 'Visa')).toBe('123');
    });

    it('formats 4-digit CVC for Amex', () => {
      expect(formatCVCNumber('1234', 'AmericanExpress')).toBe('1234');
    });

    it('truncates CVC longer than max length', () => {
      expect(formatCVCNumber('12345', 'Visa')).toBe('123');
    });

    it('returns empty string for empty input', () => {
      expect(formatCVCNumber('', 'Visa')).toBe('');
    });

    it('handles non-digit characters', () => {
      expect(formatCVCNumber('12a3', 'Visa')).toBe('123');
    });
  });

  describe('slice', () => {
    it('slices within bounds', () => {
      expect(slice('hello', 0, 3)).toBe('hel');
    });

    it('handles out of bounds gracefully', () => {
      expect(slice('hello', 0, 100)).toBe('hello');
    });

    it('returns empty string for empty input', () => {
      expect(slice('', 0, 3)).toBe('');
    });
  });

  describe('getobjFromCardPattern', () => {
    it('returns pattern object for Visa', () => {
      const obj = getobjFromCardPattern('Visa');
      expect(obj.issuer).toBe('Visa');
      expect(obj.maxCVCLength).toBe(3);
    });

    it('returns pattern object for AmericanExpress', () => {
      const obj = getobjFromCardPattern('AmericanExpress');
      expect(obj.issuer).toBe('AmericanExpress');
      expect(obj.maxCVCLength).toBe(4);
    });

    it('returns default pattern for unknown card', () => {
      const obj = getobjFromCardPattern('UnknownCard');
      expect(obj.issuer).toBe('');
      expect(obj.maxCVCLength).toBe(4);
    });
  });

  describe('getAllMatchedCardSchemes', () => {
    it('returns Visa for Visa prefix', () => {
      const schemes = getAllMatchedCardSchemes('4111');
      expect(schemes).toContain('Visa');
    });

    it('returns AmericanExpress for Amex prefix', () => {
      const schemes = getAllMatchedCardSchemes('3782');
      expect(schemes).toContain('AmericanExpress');
    });

    it('returns empty array for unknown prefix', () => {
      const schemes = getAllMatchedCardSchemes('9999');
      expect(schemes).toEqual([]);
    });

    it('returns Mastercard for Mastercard prefix', () => {
      const schemes = getAllMatchedCardSchemes('5555');
      expect(schemes).toContain('Mastercard');
    });
  });

  describe('isCardSchemeEnabled', () => {
    it('returns true when scheme is in enabled list', () => {
      expect(isCardSchemeEnabled('Visa', ['Visa', 'Mastercard'])).toBe(true);
    });

    it('returns false when scheme is not in enabled list', () => {
      expect(isCardSchemeEnabled('Amex', ['Visa', 'Mastercard'])).toBe(false);
    });

    it('returns false for empty enabled list', () => {
      expect(isCardSchemeEnabled('Visa', [])).toBe(false);
    });
  });

  describe('getStrFromIndex', () => {
    it('returns string at valid index', () => {
      expect(getStrFromIndex(['a', 'b', 'c'], 0)).toBe('a');
    });

    it('returns empty string for out of bounds index', () => {
      expect(getStrFromIndex(['a', 'b', 'c'], 10)).toBe('');
    });

    it('returns empty string for empty array', () => {
      expect(getStrFromIndex([], 0)).toBe('');
    });
  });
});
