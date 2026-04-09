import {
  getOptionString,
  getString,
  getInt,
  getFloat,
  getBool,
  getDictFromJson,
  getArray,
  getStrArray,
  snakeToPascalCase,
  mergeDict,
  getFloatFromString,
  convertDictToArrayOfKeyStringTuples,
  getArrayElement,
  getDisplayName,
  getFloatFromJson,
  getJsonBoolValue,
  getJsonStringFromDict,
  getJsonArrayFromDict,
  getJsonFromDict,
  getJsonObjFromDict,
  getDecodedStringFromJson,
  getDecodedBoolFromJson,
  getDictFromObj,
  getJsonObjectFromDict,
  getOptionBool,
  getDictFromDict,
  getOptionsDict,
  getStringFromOptionalJson,
  getOptionalArrayFromDict,
} from '../../shared-code/sdk-utils/utils/CommonUtils.bs.js';

describe('CommonUtils', () => {
  describe('getOptionString', () => {
    it('returns string when key exists', () => {
      const dict = {name: 'John'};
      expect(getOptionString(dict, 'name')).toBe('John');
    });

    it('returns undefined when key does not exist', () => {
      const dict = {name: 'John'};
      expect(getOptionString(dict, 'age')).toBeUndefined();
    });

    it('returns undefined for non-string value', () => {
      const dict = {age: 25};
      expect(getOptionString(dict, 'age')).toBeUndefined();
    });
  });

  describe('getString', () => {
    it('returns string when key exists', () => {
      const dict = {name: 'John'};
      expect(getString(dict, 'name', 'default')).toBe('John');
    });

    it('returns default when key does not exist', () => {
      const dict = {name: 'John'};
      expect(getString(dict, 'age', 'default')).toBe('default');
    });

    it('returns default when value is not a string', () => {
      const dict = {age: 25};
      expect(getString(dict, 'age', 'default')).toBe('default');
    });
  });

  describe('getInt', () => {
    it('returns int when key exists with number value', () => {
      const dict = {count: 42};
      expect(getInt(dict, 'count', 0)).toBe(42);
    });

    it('returns default when key does not exist', () => {
      const dict = {name: 'John'};
      expect(getInt(dict, 'count', 0)).toBe(0);
    });

    it('handles float values', () => {
      const dict = {value: 3.14};
      expect(getInt(dict, 'value', 0)).toBe(3);
    });
  });

  describe('getFloat', () => {
    it('returns float when key exists', () => {
      const dict = {value: 3.14};
      expect(getFloat(dict, 'value', 0)).toBeCloseTo(3.14);
    });

    it('returns default when key does not exist', () => {
      const dict = {};
      expect(getFloat(dict, 'value', 0)).toBe(0);
    });
  });

  describe('getBool', () => {
    it('returns true when key exists with true value', () => {
      const dict = {enabled: true};
      expect(getBool(dict, 'enabled', false)).toBe(true);
    });

    it('returns false when key exists with false value', () => {
      const dict = {enabled: false};
      expect(getBool(dict, 'enabled', true)).toBe(false);
    });

    it('returns default when key does not exist', () => {
      const dict = {};
      expect(getBool(dict, 'enabled', false)).toBe(false);
    });
  });

  describe('getDictFromJson', () => {
    it('returns dict for valid JSON object', () => {
      const json = {name: 'John', age: 25};
      const result = getDictFromJson(json);
      expect(result).toEqual(json);
    });

    it('returns empty object for null', () => {
      expect(getDictFromJson(null)).toEqual({});
    });

    it('returns empty object for non-object', () => {
      expect(getDictFromJson('string')).toEqual({});
    });
  });

  describe('getArray', () => {
    it('returns array when key exists', () => {
      const dict = {items: [1, 2, 3]};
      expect(getArray(dict, 'items')).toEqual([1, 2, 3]);
    });

    it('returns empty array when key does not exist', () => {
      const dict = {};
      expect(getArray(dict, 'items')).toEqual([]);
    });
  });

  describe('getStrArray', () => {
    it('returns string array when key exists', () => {
      const dict = {names: ['a', 'b', 'c']};
      expect(getStrArray(dict, 'names')).toEqual(['a', 'b', 'c']);
    });

    it('returns empty array when key does not exist', () => {
      const dict = {};
      expect(getStrArray(dict, 'names')).toEqual([]);
    });

    it('returns empty array for empty dict', () => {
      expect(getStrArray({}, 'names')).toEqual([]);
    });
  });

  describe('snakeToPascalCase', () => {
    it('converts snake_case to PascalCase', () => {
      expect(snakeToPascalCase('hello_world')).toBe('HelloWorld');
    });

    it('handles already PascalCase input', () => {
      expect(snakeToPascalCase('already_pascal')).toBe('AlreadyPascal');
    });

    it('handles single word', () => {
      expect(snakeToPascalCase('hello')).toBe('Hello');
    });

    it('handles empty string', () => {
      expect(snakeToPascalCase('')).toBe('');
    });

    it('handles multiple underscores', () => {
      expect(snakeToPascalCase('a_b_c_d')).toBe('ABCD');
    });
  });

  describe('mergeDict', () => {
    it('merges non-overlapping dicts', () => {
      const dict1 = {a: 1};
      const dict2 = {b: 2};
      const result = mergeDict(dict1, dict2);
      expect(result).toEqual({a: 1, b: 2});
    });

    it('second dict overwrites on conflict', () => {
      const dict1 = {a: 1, b: 1};
      const dict2 = {b: 2};
      const result = mergeDict(dict1, dict2);
      expect(result).toEqual({a: 1, b: 2});
    });

    it('empty + non-empty returns non-empty', () => {
      const dict1 = {};
      const dict2 = {a: 1};
      const result = mergeDict(dict1, dict2);
      expect(result).toEqual({a: 1});
    });

    it('both empty returns empty', () => {
      const result = mergeDict({}, {});
      expect(result).toEqual({});
    });
  });

  describe('getFloatFromString', () => {
    it('parses valid float string', () => {
      expect(getFloatFromString('3.14', 0)).toBeCloseTo(3.14);
    });

    it('returns default for invalid string', () => {
      expect(getFloatFromString('abc', 0)).toBe(0);
    });

    it('handles empty string', () => {
      expect(getFloatFromString('', 0)).toBe(0);
    });

    it('parses zero', () => {
      expect(getFloatFromString('0', -1)).toBe(0);
    });
  });

  describe('convertDictToArrayOfKeyStringTuples', () => {
    it('converts dict to array of tuples', () => {
      const dict = {a: '1', b: '2'};
      const result = convertDictToArrayOfKeyStringTuples(dict);
      expect(result.length).toBe(2);
      expect(result).toContainEqual(['a', '1']);
      expect(result).toContainEqual(['b', '2']);
    });

    it('returns empty array for empty dict', () => {
      expect(convertDictToArrayOfKeyStringTuples({})).toEqual([]);
    });
  });

  describe('getArrayElement', () => {
    it('returns element at valid index', () => {
      expect(getArrayElement(['a', 'b', 'c'], 0, 'default')).toBe('a');
    });

    it('returns default for out of bounds index', () => {
      expect(getArrayElement(['a', 'b'], 10, 'default')).toBe('default');
    });

    it('returns default for empty array', () => {
      expect(getArrayElement([], 0, 'default')).toBe('default');
    });
  });

  describe('getDisplayName', () => {
    it('transforms afterpay_clearpay to Afterpay', () => {
      expect(getDisplayName('afterpay_clearpay')).toBe('Afterpay');
    });

    it('transforms credit to Card', () => {
      expect(getDisplayName('credit')).toBe('Card');
    });

    it('transforms ach to Ach Debit', () => {
      expect(getDisplayName('ach')).toBe('Ach Debit');
    });

    it('handles simple names', () => {
      expect(getDisplayName('visa')).toBe('Visa');
    });

    it('handles empty string', () => {
      expect(getDisplayName('')).toBe('');
    });

    it('transforms bnb_smart_chain to BNB Smart Chain', () => {
      expect(getDisplayName('bnb_smart_chain')).toBe('BNB Smart Chain');
    });

    it('transforms classic to Cash / Voucher', () => {
      expect(getDisplayName('classic')).toBe('Cash / Voucher');
    });

    it('transforms crypto_currency to Crypto', () => {
      expect(getDisplayName('crypto_currency')).toBe('Crypto');
    });

    it('transforms evoucher to E-Voucher', () => {
      expect(getDisplayName('evoucher')).toBe('E-Voucher');
    });

    it('transforms bacs to Bacs Debit', () => {
      expect(getDisplayName('bacs')).toBe('Bacs Debit');
    });

    it('transforms becs to Becs Debit', () => {
      expect(getDisplayName('becs')).toBe('Becs Debit');
    });

    it('transforms sepa to Sepa Debit', () => {
      expect(getDisplayName('sepa')).toBe('Sepa Debit');
    });

    it('handles unknown names by capitalizing words', () => {
      expect(getDisplayName('some_unknown_type')).toBe('Some Unknown Type');
    });

    // Edge case: unknown type with numbers
    it('handles unknown type with numeric parts', () => {
      expect(getDisplayName('pay_123_method')).toBe('Pay 123 Method');
    });

    // Edge case: single underscore
    it('handles single underscore input', () => {
      const result = getDisplayName('_');
      // Split by _ gives ['', ''], capitalize empty strings → ''
      expect(result).toBe(' ');
    });
  });

  describe('getFloatFromJson', () => {
    it('extracts number from JSON number', () => {
      expect(getFloatFromJson(3.14, 0)).toBeCloseTo(3.14);
    });

    it('extracts number from JSON string', () => {
      expect(getFloatFromJson('2.5', 0)).toBeCloseTo(2.5);
    });

    it('returns default for non-number non-string JSON', () => {
      expect(getFloatFromJson(true, 99)).toBe(99);
    });

    it('returns default for null', () => {
      expect(getFloatFromJson(null, -1)).toBe(-1);
    });

    it('handles integer values', () => {
      expect(getFloatFromJson(42, 0)).toBe(42);
    });
  });

  describe('getJsonBoolValue', () => {
    it('returns boolean value when key exists', () => {
      const dict = {enabled: true};
      expect(getJsonBoolValue(dict, 'enabled', false)).toBe(true);
    });

    it('returns default when key does not exist', () => {
      const dict = {};
      expect(getJsonBoolValue(dict, 'missing', true)).toBe(true);
    });

    it('returns false value when present', () => {
      const dict = {flag: false};
      expect(getJsonBoolValue(dict, 'flag', true)).toBe(false);
    });
  });

  describe('getJsonStringFromDict', () => {
    it('returns string value when key exists', () => {
      const dict = {name: 'test'};
      expect(getJsonStringFromDict(dict, 'name', 'default')).toBe('test');
    });

    it('returns default when key does not exist', () => {
      const dict = {};
      expect(getJsonStringFromDict(dict, 'name', 'default')).toBe('default');
    });
  });

  describe('getJsonArrayFromDict', () => {
    it('returns array value when key exists', () => {
      const dict = {items: [1, 2, 3]};
      expect(getJsonArrayFromDict(dict, 'items', [])).toEqual([1, 2, 3]);
    });

    it('returns default when key does not exist', () => {
      const dict = {};
      expect(getJsonArrayFromDict(dict, 'items', ['default'])).toEqual([
        'default',
      ]);
    });
  });

  describe('getJsonFromDict', () => {
    it('returns JSON value when key exists', () => {
      const dict = {data: {nested: true}};
      expect(getJsonFromDict(dict, 'data', null)).toEqual({nested: true});
    });

    it('returns default when key does not exist', () => {
      const dict = {};
      expect(getJsonFromDict(dict, 'data', {default: true})).toEqual({
        default: true,
      });
    });
  });

  describe('getJsonObjFromDict', () => {
    it('returns object value when key exists', () => {
      const dict = {config: {theme: 'dark'}};
      expect(getJsonObjFromDict(dict, 'config', {})).toEqual({theme: 'dark'});
    });

    it('returns default when key does not exist', () => {
      const dict = {};
      expect(getJsonObjFromDict(dict, 'config', {default: true})).toEqual({
        default: true,
      });
    });
  });

  describe('getDecodedStringFromJson', () => {
    it('returns default for null JSON', () => {
      const result = getDecodedStringFromJson(
        null,
        (obj: any) => obj.name,
        'default',
      );
      expect(result).toBe('default');
    });

    it('returns default for undefined JSON', () => {
      const result = getDecodedStringFromJson(
        undefined,
        (obj: any) => obj.name,
        'default',
      );
      expect(result).toBe('default');
    });

    it('returns default for non-object JSON', () => {
      const result = getDecodedStringFromJson(
        'string',
        (obj: any) => obj.name,
        'default',
      );
      expect(result).toBe('default');
    });
  });

  describe('getDecodedBoolFromJson', () => {
    it('returns default for null JSON', () => {
      const result = getDecodedBoolFromJson(
        null,
        (obj: any) => obj.enabled,
        false,
      );
      expect(result).toBe(false);
    });

    it('returns default for undefined JSON', () => {
      const result = getDecodedBoolFromJson(
        undefined,
        (obj: any) => obj.enabled,
        true,
      );
      expect(result).toBe(true);
    });

    it('returns default for non-object JSON', () => {
      const result = getDecodedBoolFromJson(
        'string',
        (obj: any) => obj.enabled,
        false,
      );
      expect(result).toBe(false);
    });
  });

  describe('getDictFromObj', () => {
    it('extracts dict from JSON object', () => {
      const dict = {nested: {key: 'value'}};
      expect(getDictFromObj(dict, 'nested')).toEqual({key: 'value'});
    });

    it('returns empty object for missing key', () => {
      const dict = {};
      expect(getDictFromObj(dict, 'missing')).toEqual({});
    });
  });

  describe('getJsonObjectFromDict', () => {
    it('returns object when key exists', () => {
      const dict = {data: {id: 1}};
      expect(getJsonObjectFromDict(dict, 'data')).toEqual({id: 1});
    });

    it('returns empty object for missing key', () => {
      const dict = {};
      expect(getJsonObjectFromDict(dict, 'missing')).toEqual({});
    });
  });

  describe('getOptionBool', () => {
    it('returns boolean when key exists', () => {
      const dict = {enabled: true};
      expect(getOptionBool(dict, 'enabled')).toBe(true);
    });

    it('returns undefined for missing key', () => {
      const dict = {};
      expect(getOptionBool(dict, 'missing')).toBeUndefined();
    });

    it('returns false value correctly', () => {
      const dict = {flag: false};
      expect(getOptionBool(dict, 'flag')).toBe(false);
    });
  });

  describe('getDictFromDict', () => {
    it('extracts nested dict', () => {
      const dict = {outer: {inner: 'value'}};
      expect(getDictFromDict(dict, 'outer')).toEqual({inner: 'value'});
    });

    it('returns empty object for missing key', () => {
      const dict = {};
      expect(getDictFromDict(dict, 'missing')).toEqual({});
    });
  });

  describe('getOptionsDict', () => {
    it('returns dict from some option', () => {
      const options = {key: 'value'};
      expect(getOptionsDict(options)).toEqual({key: 'value'});
    });

    it('returns empty object for null', () => {
      expect(getOptionsDict(null)).toEqual({});
    });

    it('returns empty object for undefined', () => {
      expect(getOptionsDict(undefined)).toEqual({});
    });
  });

  describe('getStringFromOptionalJson', () => {
    it('returns string from JSON', () => {
      expect(getStringFromOptionalJson('hello', 'default')).toBe('hello');
    });

    it('returns default for null', () => {
      expect(getStringFromOptionalJson(null, 'default')).toBe('default');
    });

    it('returns default for undefined', () => {
      expect(getStringFromOptionalJson(undefined, 'default')).toBe('default');
    });
  });

  describe('getOptionalArrayFromDict', () => {
    it('returns array when key exists', () => {
      const dict = {items: [1, 2, 3]};
      expect(getOptionalArrayFromDict(dict, 'items')).toEqual([1, 2, 3]);
    });

    it('returns undefined for missing key', () => {
      const dict = {};
      expect(getOptionalArrayFromDict(dict, 'missing')).toBeUndefined();
    });
  });

  describe('mergeDict - nested objects', () => {
    it('recursively merges nested objects', () => {
      const dict1 = {config: {theme: 'dark', lang: 'en'}};
      const dict2 = {config: {theme: 'light'}};
      const result = mergeDict(dict1, dict2);
      expect(result.config.theme).toBe('light');
      expect(result.config.lang).toBe('en');
    });

    it('handles nested object in dict2 only', () => {
      const dict1 = {other: 'value'};
      const dict2 = {config: {nested: true}};
      const result = mergeDict(dict1, dict2);
      expect(result.config).toEqual({nested: true});
    });

    it('preserves dict2 non-object value over dict1 object', () => {
      const dict1 = {key: {nested: true}};
      const dict2 = {key: 'string'};
      const result = mergeDict(dict1, dict2);
      expect(result.key).toBe('string');
    });
  });
});
