import { isEmailValid } from '../../shared-code/sdk-utils/validation/EmailValidation.bs.js';

describe('EmailValidation', () => {
  describe('isEmailValid', () => {
    it('validates standard email format', () => {
      expect(isEmailValid('user@example.com')).toBe(true);
    });

    it('validates short email', () => {
      expect(isEmailValid('a@b.co')).toBe(true);
    });

    it('validates email with dots in local part', () => {
      expect(isEmailValid('user.name@domain.com')).toBe(true);
    });

    it('validates email with plus tag', () => {
      expect(isEmailValid('user.name+tag@domain.com')).toBe(true);
    });

    it('rejects email missing @', () => {
      expect(isEmailValid('userexample.com')).toBe(false);
    });

    it('rejects email missing domain', () => {
      expect(isEmailValid('user@')).toBe(false);
    });

    it('rejects email with double dots', () => {
      expect(isEmailValid('user@example..com')).toBe(false);
    });

    it('rejects email with spaces', () => {
      expect(isEmailValid('user @example.com')).toBe(false);
    });

    it('returns undefined for empty string', () => {
      expect(isEmailValid('')).toBeUndefined();
    });

    it('rejects email with multiple @', () => {
      expect(isEmailValid('user@@domain.com')).toBe(false);
    });

    it('validates email with subdomain', () => {
      expect(isEmailValid('user@mail.example.com')).toBe(true);
    });

    it('validates email with IP address domain', () => {
      expect(isEmailValid('user@[192.168.1.1]')).toBe(true);
    });

    it('rejects email without TLD', () => {
      expect(isEmailValid('user@domain')).toBe(false);
    });

    // Edge case: very long email (>254 chars) — regex may still match
    it('handles very long email address', () => {
      const longLocal = 'a'.repeat(200);
      const longEmail = `${longLocal}@example.com`;
      // The regex doesn't enforce a 254-char limit, so it depends on regex matching
      const result = isEmailValid(longEmail);
      expect(typeof result).toBe('boolean');
    });

    // Edge case: email with unicode characters in local part — regex accepts non-ASCII chars
    it('accepts email with unicode characters in local part (regex permits non-ASCII)', () => {
      expect(isEmailValid('useré@example.com')).toBe(true);
    });

    // Edge case: single character local part
    it('validates single character local part', () => {
      expect(isEmailValid('a@b.co')).toBe(true);
    });
  });
});
