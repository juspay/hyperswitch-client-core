import {
  cpfLength,
  invalidCPFs,
  isValidCPFFormat,
  calculateCheckDigit,
  isValidCPF,
} from '../../shared-code/sdk-utils/validation/CpfValidation.bs.js';

describe('CpfValidation', () => {
  describe('cpfLength', () => {
    it('equals 11', () => {
      expect(cpfLength).toBe(11);
    });
  });

  describe('invalidCPFs', () => {
    it('is an array', () => {
      expect(Array.isArray(invalidCPFs)).toBe(true);
    });

    it('contains all same-digit patterns', () => {
      expect(invalidCPFs).toContain('00000000000');
      expect(invalidCPFs).toContain('11111111111');
      expect(invalidCPFs).toContain('22222222222');
      expect(invalidCPFs).toContain('99999999999');
    });

    it('has 10 invalid patterns', () => {
      expect(invalidCPFs.length).toBe(10);
    });
  });

  describe('isValidCPFFormat', () => {
    it('validates valid 11-digit CPF', () => {
      expect(isValidCPFFormat('52998224725')).toBe(true);
    });

    it('rejects CPF with punctuation (needs stripping first)', () => {
      expect(isValidCPFFormat('529.982.247-25')).toBe(false);
    });

    it('rejects too short CPF', () => {
      expect(isValidCPFFormat('1234')).toBe(false);
    });

    it('rejects too long CPF', () => {
      expect(isValidCPFFormat('123456789012')).toBe(false);
    });

    it('rejects non-numeric CPF', () => {
      expect(isValidCPFFormat('abcdefghijk')).toBe(false);
    });

    it('rejects all-same-digit CPF', () => {
      expect(isValidCPFFormat('11111111111')).toBe(false);
    });

    it('rejects empty string', () => {
      expect(isValidCPFFormat('')).toBe(false);
    });
  });

  describe('calculateCheckDigit', () => {
    it('calculates correct first check digit for known CPF', () => {
      const digits = [5, 2, 9, 9, 8, 2, 2, 4, 7];
      expect(calculateCheckDigit(digits)).toBe(2);
    });

    it('calculates correct second check digit for known CPF', () => {
      const digits = [5, 2, 9, 9, 8, 2, 2, 4, 7, 2];
      expect(calculateCheckDigit(digits)).toBe(5);
    });

    it('returns 0 when remainder is less than 2', () => {
      const digits = [0, 0, 0, 0, 0, 0, 0, 0, 0];
      expect(calculateCheckDigit(digits)).toBe(0);
    });
  });

  describe('isValidCPF', () => {
    it('validates known valid CPF', () => {
      expect(isValidCPF('52998224725')).toBe(true);
    });

    it('rejects all same digits', () => {
      expect(isValidCPF('11111111111')).toBe(false);
    });

    it('rejects wrong check digit', () => {
      expect(isValidCPF('52998224726')).toBe(false);
    });

    it('rejects wrong first check digit', () => {
      expect(isValidCPF('52998224715')).toBe(false);
    });

    it('rejects wrong length', () => {
      expect(isValidCPF('123')).toBe(false);
    });

    it('rejects empty string', () => {
      expect(isValidCPF('')).toBe(false);
    });

    it('rejects non-numeric input', () => {
      expect(isValidCPF('abc123def45')).toBe(false);
    });
  });
});
