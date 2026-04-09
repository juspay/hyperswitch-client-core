const { useBackHandler } = require('../hooks/BackHandlerHook/BackHandlerHookImpl.web.bs.js');

describe('BackHandlerHookImpl.web', () => {
  describe('useBackHandler', () => {
    it('exists as a function', () => {
      expect(useBackHandler).toBeDefined();
      expect(typeof useBackHandler).toBe('function');
    });

    it('returns undefined when called', () => {
      const result = useBackHandler();
      expect(result).toBeUndefined();
    });

    it('can be called with arguments without throwing', () => {
      expect(() => useBackHandler('FillingDetails', 'PaymentSheet')).not.toThrow();
    });

    it('handles being called with no arguments', () => {
      expect(() => useBackHandler()).not.toThrow();
    });

    it('handles being called with null arguments', () => {
      expect(() => useBackHandler(null, null)).not.toThrow();
    });

    it('handles being called with undefined arguments', () => {
      expect(() => useBackHandler(undefined, undefined)).not.toThrow();
    });
  });
});
