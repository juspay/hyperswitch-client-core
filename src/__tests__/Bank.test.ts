import { bankNameConverter } from '../utility/reusableCodeFromWeb/Bank.bs.js';

describe('Bank', () => {
  describe('bankNameConverter', () => {
    it('converts bank identifier to display name format', () => {
      const banks = ['hdfc_bank'];
      const result = bankNameConverter(banks);
      expect(result[0].displayName).toBe('Hdfc Bank');
      expect(result[0].hyperSwitch).toBe('hdfc_bank');
    });

    it('handles multiple bank identifiers', () => {
      const banks = ['hdfc_bank', 'icici_bank', 'sbi_bank'];
      const result = bankNameConverter(banks);
      expect(result.length).toBe(3);
      expect(result.some((b: { displayName: string }) => b.displayName === 'Hdfc Bank')).toBe(true);
      expect(result.some((b: { displayName: string }) => b.displayName === 'Icici Bank')).toBe(true);
      expect(result.some((b: { displayName: string }) => b.displayName === 'Sbi Bank')).toBe(true);
    });

    it('handles single word bank name', () => {
      const banks = ['citibank'];
      const result = bankNameConverter(banks);
      expect(result[0].displayName).toBe('Citibank');
      expect(result[0].hyperSwitch).toBe('citibank');
    });

    it('handles empty array', () => {
      const result = bankNameConverter([]);
      expect(result).toEqual([]);
    });

    it('handles multiple underscores', () => {
      const banks = ['some_long_bank_name'];
      const result = bankNameConverter(banks);
      expect(result[0].displayName).toBe('Some Long Bank Name');
    });

    it('returns results with displayName and hyperSwitch fields', () => {
      const banks = ['z_bank', 'a_bank', 'm_bank'];
      const result = bankNameConverter(banks);
      expect(result.length).toBe(3);
      expect(result[0]).toHaveProperty('displayName');
      expect(result[0]).toHaveProperty('hyperSwitch');
      expect(result[0].hyperSwitch).toBe('z_bank');
    });

    it('preserves original identifier in hyperSwitch field', () => {
      const banks = ['test_bank_123'];
      const result = bankNameConverter(banks);
      expect(result[0].hyperSwitch).toBe('test_bank_123');
    });

    it('capitalizes first letter of each word', () => {
      const banks = ['abc_bank'];
      const result = bankNameConverter(banks);
      expect(result[0].displayName).toBe('Abc Bank');
    });
  });
});
