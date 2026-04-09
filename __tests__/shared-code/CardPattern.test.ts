import { cardPatterns, defaultCardPattern } from '../../shared-code/sdk-utils/validation/CardPattern.bs.js';

describe('CardPattern', () => {
  describe('cardPatterns', () => {
    it('is an array with length > 0', () => {
      expect(Array.isArray(cardPatterns)).toBe(true);
      expect(cardPatterns.length).toBeGreaterThan(0);
    });

    it('contains entry for Visa', () => {
      const visa = cardPatterns.find((p: any) => p.issuer === 'Visa');
      expect(visa).toBeDefined();
      expect(visa.pattern instanceof RegExp).toBe(true);
    });

    it('contains entry for Mastercard', () => {
      const mastercard = cardPatterns.find((p: any) => p.issuer === 'Mastercard');
      expect(mastercard).toBeDefined();
    });

    it('contains entry for AmericanExpress', () => {
      const amex = cardPatterns.find((p: any) => p.issuer === 'AmericanExpress');
      expect(amex).toBeDefined();
    });

    it('contains entry for Discover', () => {
      const discover = cardPatterns.find((p: any) => p.issuer === 'Discover');
      expect(discover).toBeDefined();
    });

    it('contains entry for DinersClub', () => {
      const diners = cardPatterns.find((p: any) => p.issuer === 'DinersClub');
      expect(diners).toBeDefined();
    });

    it('contains entry for JCB', () => {
      const jcb = cardPatterns.find((p: any) => p.issuer === 'JCB');
      expect(jcb).toBeDefined();
    });

    it('each entry has required fields', () => {
      cardPatterns.forEach((pattern: any) => {
        expect(pattern).toHaveProperty('issuer');
        expect(pattern).toHaveProperty('pattern');
        expect(pattern).toHaveProperty('cvcLength');
        expect(pattern).toHaveProperty('length');
        expect(pattern).toHaveProperty('maxCVCLength');
        expect(pattern).toHaveProperty('pincodeRequired');
      });
    });

    it('Visa pattern matches numbers starting with 4', () => {
      const visa = cardPatterns.find((p: any) => p.issuer === 'Visa');
      expect(visa.pattern.test('4111111111111111')).toBe(true);
      expect(visa.pattern.test('5111111111111111')).toBe(false);
    });

    it('Amex pattern matches numbers starting with 34 or 37', () => {
      const amex = cardPatterns.find((p: any) => p.issuer === 'AmericanExpress');
      expect(amex.pattern.test('378282246310005')).toBe(true);
      expect(amex.pattern.test('34')).toBe(true);
      expect(amex.pattern.test('37')).toBe(true);
      expect(amex.pattern.test('35')).toBe(false);
    });

    it('Mastercard pattern matches numbers in range', () => {
      const mastercard = cardPatterns.find((p: any) => p.issuer === 'Mastercard');
      expect(mastercard.pattern.test('5555555555554444')).toBe(true);
      expect(mastercard.pattern.test('2221000000000000')).toBe(true);
    });
  });

  describe('defaultCardPattern', () => {
    it('is a valid object', () => {
      expect(defaultCardPattern).toBeDefined();
      expect(typeof defaultCardPattern).toBe('object');
    });

    it('has expected fields', () => {
      expect(defaultCardPattern).toHaveProperty('issuer');
      expect(defaultCardPattern).toHaveProperty('pattern');
      expect(defaultCardPattern).toHaveProperty('cvcLength');
      expect(defaultCardPattern).toHaveProperty('length');
      expect(defaultCardPattern).toHaveProperty('maxCVCLength');
      expect(defaultCardPattern).toHaveProperty('pincodeRequired');
    });

    it('has sensible defaults', () => {
      expect(defaultCardPattern.issuer).toBe('');
      expect(defaultCardPattern.maxCVCLength).toBe(4);
      expect(defaultCardPattern.pincodeRequired).toBe(false);
    });
  });
});
