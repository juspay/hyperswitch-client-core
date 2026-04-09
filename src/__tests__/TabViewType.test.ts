import {
  parseSize,
  getSizeFromTabSize,
  localeDirectionToString,
} from '../types/TabViewType.bs.js';

describe('TabViewType', () => {
  describe('parseSize', () => {
    describe('happy path - string values', () => {
      it('returns "auto" for "auto" string value', () => {
        const size = { width: 'auto' };
        const result = parseSize(size, 'width');
        expect(result).toBe('auto');
      });

      it('returns pct object for percentage string value', () => {
        const size = { width: '50%' };
        const result = parseSize(size, 'width');
        expect(result).toEqual({ NAME: 'pct', VAL: 50 });
      });

      it('returns pct object for decimal percentage string', () => {
        const size = { width: '33.5%' };
        const result = parseSize(size, 'width');
        expect(result).toEqual({ NAME: 'pct', VAL: 33.5 });
      });
    });

    describe('happy path - number values', () => {
      it('returns dp object for finite number value', () => {
        const size = { width: 100 };
        const result = parseSize(size, 'width');
        expect(result).toEqual({ NAME: 'dp', VAL: 100 });
      });

      it('returns dp object for decimal number value', () => {
        const size = { width: 50.5 };
        const result = parseSize(size, 'width');
        expect(result).toEqual({ NAME: 'dp', VAL: 50.5 });
      });

      it('returns dp object for zero', () => {
        const size = { width: 0 };
        const result = parseSize(size, 'width');
        expect(result).toEqual({ NAME: 'dp', VAL: 0 });
      });
    });

    describe('edge cases - string values', () => {
      it('returns "none" for string without percentage sign', () => {
        const size = { width: '100px' };
        const result = parseSize(size, 'width');
        expect(result).toBe('none');
      });

      it('returns "none" for non-percentage non-auto string', () => {
        const size = { width: 'invalid' };
        const result = parseSize(size, 'width');
        expect(result).toBe('none');
      });

      it('returns dp with VAL 0 for NaN percentage', () => {
        const size = { width: 'NaN%' };
        const result = parseSize(size, 'width');
        expect(result).toEqual({ NAME: 'dp', VAL: 0 });
      });

      it('returns dp with VAL 0 for Infinity percentage', () => {
        const size = { width: 'Infinity%' };
        const result = parseSize(size, 'width');
        expect(result).toEqual({ NAME: 'dp', VAL: 0 });
      });
    });

    describe('edge cases - number values', () => {
      it('returns "none" for Infinity', () => {
        const size = { width: Infinity };
        const result = parseSize(size, 'width');
        expect(result).toBe('none');
      });

      it('returns "none" for -Infinity', () => {
        const size = { width: -Infinity };
        const result = parseSize(size, 'width');
        expect(result).toBe('none');
      });

      it('returns "none" for NaN', () => {
        const size = { width: NaN };
        const result = parseSize(size, 'width');
        expect(result).toBe('none');
      });
    });

    describe('edge cases - missing or invalid values', () => {
      it('returns "none" for missing key', () => {
        const size = {};
        const result = parseSize(size, 'width');
        expect(result).toBe('none');
      });

      it('returns "none" for null value', () => {
        const size = { width: null };
        const result = parseSize(size, 'width');
        expect(result).toBe('none');
      });

      it('returns "none" for undefined value', () => {
        const size = { width: undefined };
        const result = parseSize(size, 'width');
        expect(result).toBe('none');
      });

      it('returns "none" for boolean value', () => {
        const size = { width: true };
        const result = parseSize(size, 'width');
        expect(result).toBe('none');
      });

      it('returns "none" for object value', () => {
        const size = { width: { value: 100 } };
        const result = parseSize(size, 'width');
        expect(result).toBe('none');
      });

      it('returns "none" for array value', () => {
        const size = { width: [100] };
        const result = parseSize(size, 'width');
        expect(result).toBe('none');
      });
    });
  });

  describe('getSizeFromTabSize', () => {
    describe('happy path', () => {
      it('returns percentage string for pct TabSize', () => {
        const tabSize = { NAME: 'pct', VAL: 50 };
        const result = getSizeFromTabSize(tabSize);
        expect(result).toBe('50%');
      });

      it('returns number for dp TabSize', () => {
        const tabSize = { NAME: 'dp', VAL: 100 };
        const result = getSizeFromTabSize(tabSize);
        expect(result).toBe(100);
      });

      it('returns "auto" string for auto TabSize', () => {
        const tabSize = 'auto';
        const result = getSizeFromTabSize(tabSize);
        expect(result).toBe('auto');
      });

      it('returns undefined for none TabSize', () => {
        const tabSize = 'none';
        const result = getSizeFromTabSize(tabSize);
        expect(result).toBeUndefined();
      });
    });

    describe('edge cases', () => {
      it('returns zero for dp with VAL 0', () => {
        const tabSize = { NAME: 'dp', VAL: 0 };
        const result = getSizeFromTabSize(tabSize);
        expect(result).toBe(0);
      });

      it('returns percentage string for pct with VAL 0', () => {
        const tabSize = { NAME: 'pct', VAL: 0 };
        const result = getSizeFromTabSize(tabSize);
        expect(result).toBe('0%');
      });

      it('handles decimal dp values', () => {
        const tabSize = { NAME: 'dp', VAL: 50.5 };
        const result = getSizeFromTabSize(tabSize);
        expect(result).toBe(50.5);
      });

      it('handles decimal pct values', () => {
        const tabSize = { NAME: 'pct', VAL: 33.33 };
        const result = getSizeFromTabSize(tabSize);
        expect(result).toBe('33.33%');
      });
    });
  });

  describe('localeDirectionToString', () => {
    describe('happy path', () => {
      it('returns "rtl" for "rtl" direction', () => {
        const result = localeDirectionToString('rtl');
        expect(result).toBe('rtl');
      });

      it('returns "ltr" for "ltr" direction', () => {
        const result = localeDirectionToString('ltr');
        expect(result).toBe('ltr');
      });
    });

    describe('edge cases', () => {
      it('returns "ltr" for any non-rtl string', () => {
        const result = localeDirectionToString('invalid');
        expect(result).toBe('ltr');
      });

      it('returns "ltr" for empty string', () => {
        const result = localeDirectionToString('');
        expect(result).toBe('ltr');
      });

      it('returns "ltr" for uppercase RTL', () => {
        const result = localeDirectionToString('RTL');
        expect(result).toBe('ltr');
      });

      it('returns "ltr" for mixed case', () => {
        const result = localeDirectionToString('Rtl');
        expect(result).toBe('ltr');
      });
    });
  });
});
