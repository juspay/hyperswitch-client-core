import { checkEnv, isValidPK } from '../utility/constants/GlobalVars.bs.js';

describe('GlobalVars', () => {
  describe('checkEnv', () => {
    it('returns PROD for pk_prd_ prefix', () => {
      expect(checkEnv('pk_prd_live_123')).toBe('PROD');
    });

    it('returns SANDBOX for pk_snd_ prefix', () => {
      expect(checkEnv('pk_snd_test_123')).toBe('SANDBOX');
    });

    it('returns SANDBOX for empty string', () => {
      expect(checkEnv('')).toBe('SANDBOX');
    });

    it('returns SANDBOX for non-pk_prd prefix', () => {
      expect(checkEnv('pk_test_123')).toBe('SANDBOX');
      expect(checkEnv('sk_test_123')).toBe('SANDBOX');
    });
  });

  describe('isValidPK', () => {
    describe('SANDBOX environment', () => {
      it('returns true for valid sandbox key', () => {
        expect(isValidPK('SANDBOX', 'pk_snd_test_123')).toBe(true);
      });

      it('returns false for production key in sandbox', () => {
        expect(isValidPK('SANDBOX', 'pk_prd_live_123')).toBe(false);
      });

      it('returns false for empty key', () => {
        expect(isValidPK('SANDBOX', '')).toBe(false);
      });

      it('returns false for invalid prefix', () => {
        expect(isValidPK('SANDBOX', 'sk_test_123')).toBe(false);
        expect(isValidPK('SANDBOX', 'invalid_key')).toBe(false);
      });
    });

    describe('INTEG environment', () => {
      it('returns true for valid sandbox key in integ', () => {
        expect(isValidPK('INTEG', 'pk_snd_test_123')).toBe(true);
      });

      it('returns false for production key in integ', () => {
        expect(isValidPK('INTEG', 'pk_prd_live_123')).toBe(false);
      });

      it('returns false for empty key', () => {
        expect(isValidPK('INTEG', '')).toBe(false);
      });
    });

    describe('PROD environment', () => {
      it('returns true for valid production key', () => {
        expect(isValidPK('PROD', 'pk_prd_live_123')).toBe(true);
      });

      it('returns false for sandbox key in production', () => {
        expect(isValidPK('PROD', 'pk_snd_test_123')).toBe(false);
      });

      it('returns false for empty key', () => {
        expect(isValidPK('PROD', '')).toBe(false);
      });

      it('returns false for invalid prefix in production', () => {
        expect(isValidPK('PROD', 'sk_live_123')).toBe(false);
        expect(isValidPK('PROD', 'pk_live_123')).toBe(false);
      });
    });

    describe('edge cases', () => {
      it('returns false for key with only prefix', () => {
        expect(isValidPK('SANDBOX', 'pk_snd_')).toBe(true);
        expect(isValidPK('PROD', 'pk_prd_')).toBe(true);
      });

      it('handles long keys', () => {
        const longKey = 'pk_snd_' + 'a'.repeat(100);
        expect(isValidPK('SANDBOX', longKey)).toBe(true);
      });
    });
  });
});
