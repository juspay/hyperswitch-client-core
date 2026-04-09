import {
  isError,
  getErrorCode,
  getErrorMessage,
  errorWarning,
} from '../utility/reusableCodeFromWeb/ErrorUtils.bs.js';

describe('ErrorUtils', () => {
  describe('isError', () => {
    it('returns true for object with error field', () => {
      const res = { error: { code: 'ERR_001', message: 'Something went wrong' } };
      expect(isError(res)).toBe(true);
    });

    it('returns false for object without error field', () => {
      const res = { data: 'success' };
      expect(isError(res)).toBe(false);
    });

    it('returns false for null', () => {
      expect(isError(null)).toBe(false);
    });

    it('returns false for undefined', () => {
      expect(isError(undefined)).toBe(false);
    });

    it('returns false for primitive values', () => {
      expect(isError('error')).toBe(false);
      expect(isError(123)).toBe(false);
      expect(isError(true)).toBe(false);
    });

    it('returns false for empty object', () => {
      expect(isError({})).toBe(false);
    });
  });

  describe('getErrorCode', () => {
    it('extracts error code from error object', () => {
      const res = { error: { code: 'ERR_001' } };
      expect(getErrorCode(res)).toBe('"ERR_001"');
    });

    it('returns null string for missing code', () => {
      const res = { error: {} };
      expect(getErrorCode(res)).toBe('null');
    });

    it('returns null string for missing error', () => {
      const res = {};
      expect(getErrorCode(res)).toBe('null');
    });

    it('returns null string for null input', () => {
      expect(getErrorCode(null)).toBe('null');
    });
  });

  describe('getErrorMessage', () => {
    it('extracts error message from error object', () => {
      const res = { error: { message: 'Something went wrong' } };
      expect(getErrorMessage(res)).toBe('"Something went wrong"');
    });

    it('returns null string for missing message', () => {
      const res = { error: {} };
      expect(getErrorMessage(res)).toBe('null');
    });

    it('returns null string for missing error', () => {
      const res = {};
      expect(getErrorMessage(res)).toBe('null');
    });

    it('returns null string for null input', () => {
      expect(getErrorMessage(null)).toBe('null');
    });
  });

  describe('errorWarning', () => {
    it('is defined and is an object', () => {
      expect(errorWarning).toBeDefined();
      expect(typeof errorWarning).toBe('object');
    });

    it('has invalidPk error', () => {
      expect(errorWarning.invalidPk).toBeDefined();
      expect(errorWarning.invalidPk.TAG).toBe('INVALID_PK');
    });

    it('has invalidEphemeralKey error', () => {
      expect(errorWarning.invalidEphemeralKey).toBeDefined();
      expect(errorWarning.invalidEphemeralKey.TAG).toBe('INVALID_EK');
    });

    it('has deprecatedLoadStripe warning', () => {
      expect(errorWarning.deprecatedLoadStripe).toBeDefined();
      expect(errorWarning.deprecatedLoadStripe.TAG).toBe('DEPRECATED_LOADSTRIPE');
    });

    it('has reguirParameter error', () => {
      expect(errorWarning.reguirParameter).toBeDefined();
      expect(errorWarning.reguirParameter.TAG).toBe('REQUIRED_PARAMETER');
    });

    it('has typeBoolError warning', () => {
      expect(errorWarning.typeBoolError).toBeDefined();
      expect(errorWarning.typeBoolError.TAG).toBe('TYPE_BOOL_ERROR');
    });

    it('has unknownKey warning', () => {
      expect(errorWarning.unknownKey).toBeDefined();
      expect(errorWarning.unknownKey.TAG).toBe('UNKNOWN_KEY');
    });

    it('has typeStringError warning', () => {
      expect(errorWarning.typeStringError).toBeDefined();
      expect(errorWarning.typeStringError.TAG).toBe('TYPE_STRING_ERROR');
    });

    it('has unknownValue warning', () => {
      expect(errorWarning.unknownValue).toBeDefined();
      expect(errorWarning.unknownValue.TAG).toBe('UNKNOWN_VALUE');
    });

    it('has invalidFormat error', () => {
      expect(errorWarning.invalidFormat).toBeDefined();
      expect(errorWarning.invalidFormat.TAG).toBe('INVALID_FORMAT');
    });

    it('has usedCL error', () => {
      expect(errorWarning.usedCL).toBeDefined();
      expect(errorWarning.usedCL.TAG).toBe('USED_CL');
    });

    it('has invalidCL error', () => {
      expect(errorWarning.invalidCL).toBeDefined();
      expect(errorWarning.invalidCL.TAG).toBe('INVALID_CL');
    });

    it('has noData error', () => {
      expect(errorWarning.noData).toBeDefined();
      expect(errorWarning.noData.TAG).toBe('NO_DATA');
    });

    it('has noPMLData error', () => {
      expect(errorWarning.noPMLData).toBeDefined();
      expect(errorWarning.noPMLData.TAG).toBe('NO_PML_DATA');
    });

    it('all error warnings have TAG and _0 properties', () => {
      Object.values(errorWarning).forEach((warning) => {
        expect(warning).toHaveProperty('TAG');
        expect(warning).toHaveProperty('_0');
      });
    });

    describe('dynamic error messages', () => {
      it('reguirParameter generates dynamic message', () => {
        const fn = errorWarning.reguirParameter._0[1]._0;
        expect(fn('test param')).toBe('INTEGRATION ERROR: test param');
      });

      it('typeBoolError generates dynamic message', () => {
        const fn = errorWarning.typeBoolError._0[1]._0;
        expect(fn('someField')).toBe("Type Error: 'someField' Expected boolean");
      });

      it('unknownKey generates dynamic message', () => {
        const fn = errorWarning.unknownKey._0[1]._0;
        expect(fn('unknownKey')).toContain('unknownKey');
      });

      it('typeStringError generates dynamic message', () => {
        const fn = errorWarning.typeStringError._0[1]._0;
        expect(fn('someField')).toBe("Type Error: 'someField' Expected string");
      });

      it('unknownValue generates dynamic message', () => {
        const fn = errorWarning.unknownValue._0[1]._0;
        expect(fn('unknownVal')).toContain('unknownVal');
      });

      it('invalidFormat generates dynamic message', () => {
        const fn = errorWarning.invalidFormat._0[1]._0;
        expect(fn('custom error')).toBe('custom error');
      });
    });
  });
});
