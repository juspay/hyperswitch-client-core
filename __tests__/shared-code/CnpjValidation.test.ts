import {
  cnpjLength,
  isNumeric,
  isUppercaseAlphanumeric,
  isCNPJValidFormat,
  charToValue,
  calculateCheckDigit,
  isValidCNPJ,
} from '../../shared-code/sdk-utils/validation/CnpjValidation.bs.js';

describe('CnpjValidation', () => {
  describe('cnpjLength', () => {
    it('equals 14', () => {
      expect(cnpjLength).toBe(14);
    });
  });

  describe('isNumeric', () => {
    it('returns true for digit character', () => {
      expect(isNumeric('5')).toBe(true);
    });

    it('returns true for digit string', () => {
      expect(isNumeric('12345')).toBe(true);
    });

    it('returns false for alphabetic character', () => {
      expect(isNumeric('a')).toBe(false);
    });

    it('returns false for mixed string', () => {
      expect(isNumeric('12a45')).toBe(false);
    });

    it('returns true for empty string', () => {
      expect(isNumeric('')).toBe(true);
    });
  });

  describe('isUppercaseAlphanumeric', () => {
    it('returns true for uppercase letter', () => {
      expect(isUppercaseAlphanumeric('A')).toBe(true);
    });

    it('returns true for digit', () => {
      expect(isUppercaseAlphanumeric('5')).toBe(true);
    });

    it('returns false for lowercase letter', () => {
      expect(isUppercaseAlphanumeric('a')).toBe(false);
    });

    it('returns false for special character', () => {
      expect(isUppercaseAlphanumeric('!')).toBe(false);
    });

    it('returns true for empty string', () => {
      expect(isUppercaseAlphanumeric('')).toBe(true);
    });

    it('returns true for uppercase alphanumeric string', () => {
      expect(isUppercaseAlphanumeric('ABC123')).toBe(true);
    });
  });

  describe('isCNPJValidFormat', () => {
    it('validates 14-character CNPJ', () => {
      expect(isCNPJValidFormat('11222333000181')).toBe(true);
    });

    it('handles short strings', () => {
      expect(isCNPJValidFormat('123')).toBe(true);
    });

    it('rejects lowercase characters', () => {
      expect(isCNPJValidFormat('112223330001ab')).toBe(false);
    });

    it('rejects special characters', () => {
      expect(isCNPJValidFormat('112223330001!@')).toBe(false);
    });

    it('rejects when base has special characters', () => {
      expect(isCNPJValidFormat('!@#$%^&*()12')).toBe(false);
    });
  });

  describe('charToValue', () => {
    it('returns correct value for digit 0', () => {
      expect(charToValue('0')).toBe(0);
    });

    it('returns correct value for digit 9', () => {
      expect(charToValue('9')).toBe(9);
    });

    it('returns correct value for uppercase A', () => {
      expect(charToValue('A')).toBe(17);
    });

    it('returns correct value for uppercase Z', () => {
      expect(charToValue('Z')).toBe(42);
    });

    it('returns 0 for invalid character', () => {
      expect(charToValue('!')).toBe(0);
    });

    it('returns 0 for lowercase character', () => {
      expect(charToValue('a')).toBe(0);
    });
  });

  describe('calculateCheckDigit', () => {
    it('calculates correct check digit', () => {
      const values = [1, 1, 2, 2, 2, 3, 3, 3, 0, 0, 0, 1];
      const weights = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
      expect(calculateCheckDigit(values, weights)).toBe(8);
    });

    it('returns 0 when remainder is less than 2', () => {
      const values = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
      const weights = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
      expect(calculateCheckDigit(values, weights)).toBe(0);
    });
  });

  describe('isValidCNPJ', () => {
    it('validates known valid CNPJ', () => {
      expect(isValidCNPJ('11222333000181')).toBe(true);
    });

    it('rejects all same characters', () => {
      expect(isValidCNPJ('11111111111111')).toBe(false);
    });

    it('rejects wrong check digits', () => {
      expect(isValidCNPJ('11222333000182')).toBe(false);
    });

    it('rejects wrong first check digit', () => {
      expect(isValidCNPJ('11222333000171')).toBe(false);
    });

    it('rejects wrong length', () => {
      expect(isValidCNPJ('123')).toBe(false);
    });

    it('rejects empty string', () => {
      expect(isValidCNPJ('')).toBe(false);
    });
  });
});
