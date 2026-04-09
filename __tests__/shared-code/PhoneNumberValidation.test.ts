import { formatPhoneNumber } from '../../shared-code/sdk-utils/validation/PhoneNumberValidation.bs.js';

describe('PhoneNumberValidation', () => {
  const mockCountries = [
    { phone_number_code: '+1', name: 'United States' },
    { phone_number_code: '+44', name: 'United Kingdom' },
    { phone_number_code: '+91', name: 'India' },
  ];

  describe('formatPhoneNumber', () => {
    it('extracts country code and number with + prefix', () => {
      const result = formatPhoneNumber('+1 555-1234', mockCountries);
      expect(result[0]).toBe('+1');
      expect(result[1]).toBe('5551234');
    });

    it('handles international format', () => {
      const result = formatPhoneNumber('+44 20 7946 0958', mockCountries);
      expect(result[0]).toBe('+44');
      expect(result[1]).toBe('2079460958');
    });

    it('handles number without country code', () => {
      const result = formatPhoneNumber('5551234', mockCountries);
      expect(result[0]).toBe('');
      expect(result[1]).toBe('5551234');
    });

    it('returns sensible default for empty string', () => {
      const result = formatPhoneNumber('', mockCountries);
      expect(result[0]).toBe('');
      expect(result[1]).toBe('');
    });

    it('handles just country code', () => {
      const result = formatPhoneNumber('+1', mockCountries);
      expect(result[0]).toBe('+1');
      expect(result[1]).toBe('');
    });

    it('handles very long phone numbers', () => {
      const longNumber = '123456789012345678901';
      const result = formatPhoneNumber(longNumber, mockCountries);
      expect(result[0]).toBe('');
      expect(result[1]).toBe(longNumber);
    });

    it('handles Indian phone number', () => {
      const result = formatPhoneNumber('+91 9876543210', mockCountries);
      expect(result[0]).toBe('+91');
      expect(result[1]).toBe('9876543210');
    });

    it('handles phone with extra spaces and dashes', () => {
      const result = formatPhoneNumber('+1 555 - 123 - 4567', mockCountries);
      expect(result[0]).toBe('+1');
      expect(result[1]).toBe('5551234567');
    });

    it('handles invalid country code gracefully', () => {
      const result = formatPhoneNumber('+999 1234567', mockCountries);
      expect(result[0]).toBe('');
      expect(result[1]).toBe('+999 1234567');
    });

    it('handles phone with parentheses', () => {
      const result = formatPhoneNumber('+1 (555) 123-4567', mockCountries);
      expect(result[0]).toBe('+1');
      expect(result[1]).toBe('5551234567');
    });
  });
});
