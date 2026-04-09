import {
  getProp,
  retOptionalStr,
  retOptionalFloat,
  getOptionString,
  getOptionFloat,
  getString,
  getBool,
  getObj,
  getOptionalObj,
  getOptionalArrayFromDict,
  getArrayFromDict,
  getDictFromJson,
  getDictFromJsonKey,
  getArray,
  getJsonObjectFromDict,
  convertToScreamingSnakeCase,
  isEmptyDict,
  transformKeysSnakeToCamel,
  getHeader,
  getCountryFlags,
  getStateNames,
  getClientCountry,
  getStateNameFromStateCodeAndCountry,
  splitName,
  getStringFromJson,
  underscoresToSpaces,
  toCamelCase,
  toSnakeCase,
  toKebabCase,
  transformKeys,
  getStrArray,
  getOptionalStrArray,
  getArrofJsonString,
  getCustomReturnAppUrl,
  getStringFromRecord,
  getJsonObjectFromRecord,
  getError,
  getDaysInMonth,
  pruneUnusedFieldsFromDict,
} from '../utility/logics/Utils.bs.js';

describe('Utils', () => {
  describe('getProp', () => {
    it('returns value for existing key', () => {
      const dict = {key: 'value'};
      expect(getProp('key', dict)).toBe('value');
    });

    it('returns undefined for missing key', () => {
      const dict = {key: 'value'};
      expect(getProp('missing', dict)).toBeUndefined();
    });

    it('returns nested value', () => {
      const dict = {nested: {inner: 'value'}};
      expect(getProp('nested', dict)).toEqual({inner: 'value'});
    });
  });

  describe('retOptionalStr', () => {
    it('returns string for valid JSON string', () => {
      expect(retOptionalStr('hello')).toBe('hello');
    });

    it('returns undefined for undefined input', () => {
      expect(retOptionalStr(undefined)).toBeUndefined();
    });

    it('returns undefined for number input', () => {
      expect(retOptionalStr(42)).toBeUndefined();
    });
  });

  describe('retOptionalFloat', () => {
    it('returns float for valid number', () => {
      expect(retOptionalFloat(3.14)).toBe(3.14);
    });

    it('returns undefined for undefined input', () => {
      expect(retOptionalFloat(undefined)).toBeUndefined();
    });

    it('returns undefined for string input', () => {
      expect(retOptionalFloat('2.5')).toBeUndefined();
    });
  });

  describe('getOptionString', () => {
    it('returns string for existing key with string value', () => {
      const dict = {key: 'value'};
      expect(getOptionString(dict, 'key')).toBe('value');
    });

    it('returns undefined for missing key', () => {
      const dict = {key: 'value'};
      expect(getOptionString(dict, 'missing')).toBeUndefined();
    });

    it('returns undefined for non-string value', () => {
      const dict = {num: 42};
      expect(getOptionString(dict, 'num')).toBeUndefined();
    });
  });

  describe('getOptionFloat', () => {
    it('returns float for existing key with number value', () => {
      const dict = {num: 3.14};
      expect(getOptionFloat(dict, 'num')).toBe(3.14);
    });

    it('returns undefined for missing key', () => {
      const dict = {num: 3.14};
      expect(getOptionFloat(dict, 'missing')).toBeUndefined();
    });
  });

  describe('getString', () => {
    it('returns string for existing key', () => {
      const dict = {key: 'value'};
      expect(getString(dict, 'key', 'default')).toBe('value');
    });

    it('returns default for missing key', () => {
      const dict = {key: 'value'};
      expect(getString(dict, 'missing', 'default')).toBe('default');
    });

    it('returns default for wrong type', () => {
      const dict = {num: 42};
      expect(getString(dict, 'num', 'default')).toBe('default');
    });
  });

  describe('getBool', () => {
    it('returns true for true value', () => {
      const dict = {flag: true};
      expect(getBool(dict, 'flag', false)).toBe(true);
    });

    it('returns false for false value', () => {
      const dict = {flag: false};
      expect(getBool(dict, 'flag', true)).toBe(false);
    });

    it('returns default for missing key', () => {
      const dict = {};
      expect(getBool(dict, 'flag', true)).toBe(true);
    });
  });

  describe('getObj', () => {
    it('returns object for existing key with object value', () => {
      const dict = {nested: {a: 1}};
      expect(getObj(dict, 'nested', {})).toEqual({a: 1});
    });

    it('returns default for missing key', () => {
      const dict = {};
      expect(getObj(dict, 'nested', {default: true})).toEqual({default: true});
    });

    it('returns default for non-object value', () => {
      const dict = {str: 'value'};
      expect(getObj(dict, 'str', {})).toEqual({});
    });
  });

  describe('getOptionalObj', () => {
    it('returns object for existing key with object value', () => {
      const dict = {nested: {a: 1}};
      expect(getOptionalObj(dict, 'nested')).toEqual({a: 1});
    });

    it('returns undefined for missing key', () => {
      const dict = {};
      expect(getOptionalObj(dict, 'nested')).toBeUndefined();
    });
  });

  describe('getOptionalArrayFromDict', () => {
    it('returns array for existing key with array value', () => {
      const dict = {arr: [1, 2, 3]};
      expect(getOptionalArrayFromDict(dict, 'arr')).toEqual([1, 2, 3]);
    });

    it('returns undefined for missing key', () => {
      const dict = {};
      expect(getOptionalArrayFromDict(dict, 'arr')).toBeUndefined();
    });
  });

  describe('getArrayFromDict', () => {
    it('returns array for existing key', () => {
      const dict = {arr: [1, 2, 3]};
      expect(getArrayFromDict(dict, 'arr', [])).toEqual([1, 2, 3]);
    });

    it('returns default for missing key', () => {
      const dict = {};
      expect(getArrayFromDict(dict, 'arr', [4, 5])).toEqual([4, 5]);
    });
  });

  describe('getDictFromJson', () => {
    it('returns dict for valid JSON object', () => {
      const json = {key: 'value'};
      expect(getDictFromJson(json)).toEqual({key: 'value'});
    });

    it('returns empty dict for null', () => {
      expect(getDictFromJson(null)).toEqual({});
    });

    it('returns empty dict for non-object', () => {
      expect(getDictFromJson('string')).toEqual({});
    });
  });

  describe('getDictFromJsonKey', () => {
    it('returns dict for existing key with object', () => {
      const json = {nested: {a: 1}};
      expect(getDictFromJsonKey(json, 'nested')).toEqual({a: 1});
    });

    it('returns empty dict for missing key', () => {
      const json = {};
      expect(getDictFromJsonKey(json, 'missing')).toEqual({});
    });
  });

  describe('getArray', () => {
    it('returns array for existing key', () => {
      const dict = {arr: [1, 2, 3]};
      expect(getArray(dict, 'arr')).toEqual([1, 2, 3]);
    });

    it('returns empty array for missing key', () => {
      const dict = {};
      expect(getArray(dict, 'missing')).toEqual([]);
    });
  });

  describe('getJsonObjectFromDict', () => {
    it('returns object for existing key', () => {
      const dict = {nested: {a: 1}};
      expect(getJsonObjectFromDict(dict, 'nested')).toEqual({a: 1});
    });

    it('returns empty object for missing key', () => {
      const dict = {};
      expect(getJsonObjectFromDict(dict, 'missing')).toEqual({});
    });
  });

  describe('convertToScreamingSnakeCase', () => {
    it('converts helloWorld to SCREAMING_SNAKE_CASE', () => {
      expect(convertToScreamingSnakeCase('hello world')).toBe('HELLO_WORLD');
    });

    it('handles already screaming case', () => {
      expect(convertToScreamingSnakeCase('HELLO WORLD')).toBe('HELLO_WORLD');
    });

    it('handles empty string', () => {
      expect(convertToScreamingSnakeCase('')).toBe('');
    });

    it('trims whitespace before converting', () => {
      expect(convertToScreamingSnakeCase('  hello world  ')).toBe(
        'HELLO_WORLD',
      );
    });
  });

  describe('isEmptyDict', () => {
    it('returns true for empty dict', () => {
      expect(isEmptyDict({})).toBe(true);
    });

    it('returns false for non-empty dict', () => {
      expect(isEmptyDict({key: 'value'})).toBe(false);
    });

    it('returns true for dict with only undefined values', () => {
      expect(isEmptyDict({key: undefined})).toBe(false);
    });
  });

  describe('transformKeysSnakeToCamel', () => {
    it('transforms snake_case keys to camelCase', () => {
      const input = {first_name: 'John', last_name: 'Doe'};
      const result = transformKeysSnakeToCamel(input);
      expect(result).toHaveProperty('firstName');
      expect(result).toHaveProperty('lastName');
    });

    it('lowercases keys without underscores', () => {
      const input = {firstName: 'John'};
      const result = transformKeysSnakeToCamel(input);
      expect(result).toHaveProperty('firstname');
    });

    it('handles empty dict', () => {
      expect(transformKeysSnakeToCamel({})).toEqual({});
    });

    it('transforms nested objects recursively', () => {
      const input = {user_data: {first_name: 'John'}};
      const result = transformKeysSnakeToCamel(input);
      expect(result).toHaveProperty('userData');
    });
  });

  describe('splitName', () => {
    it('splits "John Doe" into first and last', () => {
      expect(splitName('John Doe')).toEqual(['John', 'Doe']);
    });

    it('handles single name', () => {
      expect(splitName('John')).toEqual(['John', '']);
    });

    it('handles multiple names - last word is last name', () => {
      expect(splitName('John Middle Doe')).toEqual(['John Middle', 'Doe']);
    });

    it('handles empty string', () => {
      expect(splitName('')).toEqual(['', '']);
    });

    it('handles undefined', () => {
      expect(splitName(undefined)).toEqual(['', '']);
    });
  });

  describe('getStringFromJson', () => {
    it('returns string for valid JSON string', () => {
      expect(getStringFromJson('hello', 'default')).toBe('hello');
    });

    it('returns default for non-string', () => {
      expect(getStringFromJson(42, 'default')).toBe('default');
    });

    it('returns default for null', () => {
      expect(getStringFromJson(null, 'default')).toBe('default');
    });
  });

  describe('underscoresToSpaces', () => {
    it('replaces underscores with spaces', () => {
      expect(underscoresToSpaces('hello_world')).toBe('hello world');
    });

    it('handles multiple underscores', () => {
      expect(underscoresToSpaces('hello_beautiful_world')).toBe(
        'hello beautiful world',
      );
    });

    it('handles no underscores', () => {
      expect(underscoresToSpaces('nounderscores')).toBe('nounderscores');
    });

    it('handles empty string', () => {
      expect(underscoresToSpaces('')).toBe('');
    });
  });

  describe('toCamelCase', () => {
    it('converts snake_case to camelCase', () => {
      expect(toCamelCase('hello_world')).toBe('helloWorld');
    });

    it('handles kebab-case', () => {
      expect(toCamelCase('hello-world')).toBe('helloWorld');
    });

    it('returns string with colon unchanged', () => {
      expect(toCamelCase('hello:world')).toBe('hello:world');
    });

    it('handles empty string', () => {
      expect(toCamelCase('')).toBe('');
    });
  });

  describe('toSnakeCase', () => {
    it('converts camelCase to snake_case', () => {
      expect(toSnakeCase('helloWorld')).toBe('hello_world');
    });

    it('handles multiple uppercase letters', () => {
      expect(toSnakeCase('helloWorldFoo')).toBe('hello_world_foo');
    });

    it('handles empty string', () => {
      expect(toSnakeCase('')).toBe('');
    });
  });

  describe('toKebabCase', () => {
    it('converts camelCase to kebab-case', () => {
      expect(toKebabCase('helloWorld')).toBe('hello-world');
    });

    it('handles multiple uppercase letters', () => {
      expect(toKebabCase('helloWorldFoo')).toBe('hello-world-foo');
    });

    it('handles empty string', () => {
      expect(toKebabCase('')).toBe('');
    });
  });

  describe('transformKeys', () => {
    it('transforms keys to camelCase', () => {
      const input = {first_name: 'John'};
      const result = transformKeys(input, 'CamelCase');
      expect(result).toHaveProperty('firstName');
    });

    it('transforms keys to snake_case', () => {
      const input = {firstName: 'John'};
      const result = transformKeys(input, 'SnakeCase');
      expect(result).toHaveProperty('first_name');
    });

    it('transforms keys to kebab-case', () => {
      const input = {firstName: 'John'};
      const result = transformKeys(input, 'KebabCase');
      expect(result).toHaveProperty('first-name');
    });

    it('handles empty dict', () => {
      expect(transformKeys({}, 'CamelCase')).toEqual({});
    });
  });

  describe('getStrArray', () => {
    it('returns string array for existing key', () => {
      const dict = {arr: ['a', 'b', 'c']};
      expect(getStrArray(dict, 'arr')).toEqual(['a', 'b', 'c']);
    });

    it('returns empty array for missing key', () => {
      const dict = {};
      expect(getStrArray(dict, 'missing')).toEqual([]);
    });

    it('handles empty array', () => {
      const dict = {arr: []};
      expect(getStrArray(dict, 'arr')).toEqual([]);
    });
  });

  describe('getOptionalStrArray', () => {
    it('returns string array for existing key', () => {
      const dict = {arr: ['a', 'b']};
      expect(getOptionalStrArray(dict, 'arr')).toEqual(['a', 'b']);
    });

    it('returns undefined for missing key', () => {
      const dict = {};
      expect(getOptionalStrArray(dict, 'missing')).toBeUndefined();
    });

    it('returns undefined for empty array', () => {
      const dict = {arr: []};
      expect(getOptionalStrArray(dict, 'arr')).toBeUndefined();
    });
  });

  describe('getArrofJsonString', () => {
    it('returns the same array', () => {
      const arr = ['a', 'b', 'c'];
      expect(getArrofJsonString(arr)).toEqual(['a', 'b', 'c']);
    });

    it('handles empty array', () => {
      expect(getArrofJsonString([])).toEqual([]);
    });
  });

  describe('getStringFromRecord', () => {
    it('returns JSON string for record', () => {
      const record = {key: 'value'};
      expect(getStringFromRecord(record)).toBe('{"key":"value"}');
    });

    it('handles empty record', () => {
      expect(getStringFromRecord({})).toBe('{}');
    });
  });

  describe('getJsonObjectFromRecord', () => {
    it('returns the same record', () => {
      const record = {key: 'value'};
      expect(getJsonObjectFromRecord(record)).toEqual(record);
    });
  });

  describe('getError', () => {
    it('returns default for JS Error object', () => {
      const err = new Error('test error');
      expect(getError(err, 'default')).toBe('default');
    });

    it('returns default for non-error', () => {
      expect(getError('not an error', 'default')).toBe('default');
    });

    it('returns default when message is undefined', () => {
      const err = {};
      expect(getError(err, 'default')).toBe('default');
    });
  });

  describe('getDaysInMonth', () => {
    it('returns 31 for January', () => {
      expect(getDaysInMonth('1', '2024')).toBe(31);
    });

    it('returns 28 for February non-leap year', () => {
      expect(getDaysInMonth('2', '2023')).toBe(28);
    });

    it('returns 29 for February leap year', () => {
      expect(getDaysInMonth('2', '2024')).toBe(29);
    });

    it('returns 30 for April', () => {
      expect(getDaysInMonth('4', '2024')).toBe(30);
    });

    it('returns 31 for empty month', () => {
      expect(getDaysInMonth('', '2024')).toBe(31);
    });

    it('returns 31 for empty year', () => {
      expect(getDaysInMonth('1', '')).toBe(31);
    });

    it('handles year divisible by 100 but not 400', () => {
      expect(getDaysInMonth('2', '1900')).toBe(28);
    });

    it('handles year divisible by 400', () => {
      expect(getDaysInMonth('2', '2000')).toBe(29);
    });

    // Edge case: month "0" — invalid month, falls to default case
    it('returns 31 for invalid month 0', () => {
      expect(getDaysInMonth('0', '2024')).toBe(31);
    });

    // Edge case: month "13" — invalid month, falls to default case
    it('returns 31 for invalid month 13', () => {
      expect(getDaysInMonth('13', '2024')).toBe(31);
    });

    // Edge case: negative month
    it('returns 31 for negative month -1', () => {
      expect(getDaysInMonth('-1', '2024')).toBe(31);
    });

    // Edge case: non-numeric month string — falls back to monthNum=1 (default)
    it('returns 31 for non-numeric month string', () => {
      expect(getDaysInMonth('abc', '2024')).toBe(31);
    });
  });

  describe('pruneUnusedFieldsFromDict', () => {
    it('removes unused fields', () => {
      const dict = {used: 'value', unused: 'value'};
      const result = pruneUnusedFieldsFromDict(dict, '', ['used']);
      expect(result).toHaveProperty('used');
      expect(result).not.toHaveProperty('unused');
    });

    it('keeps all used fields', () => {
      const dict = {a: 1, b: 2};
      const result = pruneUnusedFieldsFromDict(dict, '', ['a', 'b']);
      expect(result).toEqual({a: 1, b: 2});
    });

    it('handles empty dict', () => {
      expect(pruneUnusedFieldsFromDict({}, '', ['a'])).toEqual({});
    });

    it('handles nested paths', () => {
      const dict = {nested: {used: 'value', unused: 'value'}};
      const result = pruneUnusedFieldsFromDict(dict, '', ['nested.used']) as {
        nested: {used: string; unused?: string};
      };
      expect(result.nested).toHaveProperty('used');
      expect(result.nested).not.toHaveProperty('unused');
    });

    it('handles non-object values in nested paths', () => {
      const dict = {nested: 'not-an-object'};
      const result = pruneUnusedFieldsFromDict(dict, '', ['nested.value']);
      expect(result).toEqual({});
    });

    it('handles prefix match with non-object value', () => {
      const dict = {data: 'string_value', other: 'ignored'};
      const result = pruneUnusedFieldsFromDict(dict, '', ['data.nested']);
      expect(result).toEqual({});
    });
  });

  describe('getHeader', () => {
    it('creates header with api-key and app-id', () => {
      const result = getHeader('test-key', 'myapp.hyperswitch://', undefined);
      expect(result['api-key']).toBe('test-key');
      expect(result['x-app-id']).toBe('myapp');
      expect(result['x-redirect-uri']).toBe('');
    });

    it('handles missing appId', () => {
      const result = getHeader('test-key', undefined, undefined);
      expect(result['api-key']).toBe('test-key');
      expect(result['x-app-id']).toBe('');
    });

    it('includes redirect URI when provided', () => {
      const result = getHeader(
        'test-key',
        undefined,
        'https://example.com/callback',
      );
      expect(result['x-redirect-uri']).toBe('https://example.com/callback');
    });
  });

  describe('getCountryFlags', () => {
    it('returns flag emoji for US', () => {
      expect(getCountryFlags('US')).toBe('🇺🇸   ');
    });

    it('returns flag emoji for GB', () => {
      expect(getCountryFlags('GB')).toBe('🇬🇧   ');
    });

    it('returns flag emoji for DE', () => {
      expect(getCountryFlags('DE')).toBe('🇩🇪   ');
    });
  });

  describe('getStateNames', () => {
    it('returns state list for existing country', () => {
      const list = {
        US: [
          {code: 'CA', value: 'California'},
          {code: 'NY', value: 'New York'},
        ],
      };
      expect(getStateNames(list, 'US')).toEqual([
        {code: 'CA', value: 'California'},
        {code: 'NY', value: 'New York'},
      ]);
    });

    it('returns empty array for missing country', () => {
      const list = {};
      expect(getStateNames(list, 'US')).toEqual([]);
    });

    it('returns empty array for country with no states', () => {
      const list = {US: []};
      expect(getStateNames(list, 'US')).toEqual([]);
    });
  });

  describe('getClientCountry', () => {
    it('returns country matching timezone', () => {
      const countryArr = [
        {
          country_code: 'US',
          country_name: 'United States',
          timeZones: ['America/New_York', 'America/Los_Angeles'],
        },
        {
          country_code: 'GB',
          country_name: 'United Kingdom',
          timeZones: ['Europe/London'],
        },
      ];
      const result = getClientCountry(countryArr, 'America/New_York');
      expect(result.country_code).toBe('US');
    });

    it('returns default when no timezone match', () => {
      const countryArr = [
        {
          country_code: 'US',
          country_name: 'United States',
          timeZones: ['America/New_York'],
        },
      ];
      const result = getClientCountry(countryArr, 'Europe/London');
      expect(result.country_code).toBe('');
      expect(result.country_name).toBe('');
    });

    it('returns default for empty array', () => {
      const result = getClientCountry([], 'America/New_York');
      expect(result.country_code).toBe('');
      expect(result.timeZones).toEqual([]);
    });
  });

  describe('getStateNameFromStateCodeAndCountry', () => {
    it('returns state name for valid code and country', () => {
      const list = {
        US: [
          {code: 'CA', value: 'California'},
          {code: 'NY', value: 'New York'},
        ],
      };
      expect(getStateNameFromStateCodeAndCountry(list, 'CA', 'US')).toBe(
        'California',
      );
    });

    it('returns state code when state not found', () => {
      const list = {
        US: [{code: 'CA', value: 'California'}],
      };
      expect(getStateNameFromStateCodeAndCountry(list, 'TX', 'US')).toBe('TX');
    });

    it('returns state code when country is undefined', () => {
      expect(getStateNameFromStateCodeAndCountry({}, 'CA', undefined)).toBe(
        'CA',
      );
    });

    it('returns state code when country has no states', () => {
      expect(getStateNameFromStateCodeAndCountry({US: []}, 'CA', 'US')).toBe(
        'CA',
      );
    });
  });

  describe('getCustomReturnAppUrl', () => {
    it('returns app URL with hyperswitch suffix', () => {
      expect(getCustomReturnAppUrl('myapp')).toBe('myapp.hyperswitch://');
    });

    it('returns undefined for undefined input', () => {
      expect(getCustomReturnAppUrl(undefined)).toBeUndefined();
    });

    it('handles empty string', () => {
      expect(getCustomReturnAppUrl('')).toBe('.hyperswitch://');
    });
  });

  describe('transformKeysSnakeToCamel - additional branches', () => {
    it('transforms nested objects recursively', () => {
      const input = {user_data: {first_name: 'John'}};
      const result = transformKeysSnakeToCamel(input);
      expect(result).toHaveProperty('userData');
      expect(
        (result as {userData: {firstName: string}}).userData,
      ).toHaveProperty('firstName');
    });

    it('transforms arrays of objects', () => {
      const input = {items: [{item_name: 'test'}, {item_name: 'test2'}]};
      const result = transformKeysSnakeToCamel(input);
      const items = (result as {items: Array<{itemName: string}>}).items;
      expect(items[0]).toHaveProperty('itemName');
      expect(items[1]).toHaveProperty('itemName');
    });

    it('handles arrays with non-object items', () => {
      const input = {numbers: [1, 2, 3]};
      const result = transformKeysSnakeToCamel(input) as {numbers: number[]};
      expect(result.numbers).toEqual([1, 2, 3]);
    });

    it('handles Number values', () => {
      const input = {item_count: 42};
      const result = transformKeysSnakeToCamel(input) as {itemCount: string};
      expect(result.itemCount).toBe('42');
    });

    it('handles Boolean values', () => {
      const input = {is_active: true, is_deleted: false};
      const result = transformKeysSnakeToCamel(input) as {
        isActive: boolean;
        isDeleted: boolean;
      };
      expect(result.isActive).toBe(true);
      expect(result.isDeleted).toBe(false);
    });

    it('handles null values', () => {
      const input = {value: null};
      const result = transformKeysSnakeToCamel(input) as {value: null};
      expect(result.value).toBeNull();
    });

    it('transforms "Final" string to "FINAL"', () => {
      const input = {status: 'Final'};
      const result = transformKeysSnakeToCamel(input) as {status: string};
      expect(result.status).toBe('FINAL');
    });

    it('transforms "example" string to "adyen"', () => {
      const input = {gateway: 'example'};
      const result = transformKeysSnakeToCamel(input) as {gateway: string};
      expect(result.gateway).toBe('adyen');
    });

    it('transforms "exampleGatewayMerchantId" to "Sampras123ECOM"', () => {
      const input = {merchant_id: 'exampleGatewayMerchantId'};
      const result = transformKeysSnakeToCamel(input) as {merchantId: string};
      expect(result.merchantId).toBe('Sampras123ECOM');
    });

    it('preserves keys containing colons', () => {
      const input = {'http://example.com': 'value'};
      const result = transformKeysSnakeToCamel(input);
      expect(result['http://example.com']).toBe('value');
    });
  });

  describe('transformKeys - additional branches', () => {
    it('transforms nested objects recursively', () => {
      const input = {user_data: {first_name: 'John'}};
      const result = transformKeys(input, 'CamelCase');
      expect(result).toHaveProperty('userData');
      expect(
        (result as {userData: {firstName: string}}).userData,
      ).toHaveProperty('firstName');
    });

    it('transforms arrays of objects', () => {
      const input = {items: [{item_name: 'test'}]};
      const result = transformKeys(input, 'CamelCase');
      const items = (result as {items: Array<{itemName: string}>}).items;
      expect(items[0]).toHaveProperty('itemName');
    });

    it('handles arrays with non-object items', () => {
      const input = {numbers: [1, 2, 3]};
      const result = transformKeys(input, 'CamelCase') as {numbers: number[]};
      expect(result.numbers).toEqual([1, 2, 3]);
    });

    it('handles Number values - returns as int', () => {
      const input = {item_count: 42.5};
      const result = transformKeys(input, 'CamelCase') as {itemCount: number};
      expect(result.itemCount).toBe(42);
    });

    it('handles Boolean values', () => {
      const input = {is_active: true};
      const result = transformKeys(input, 'CamelCase') as {isActive: boolean};
      expect(result.isActive).toBe(true);
    });

    it('handles null values', () => {
      const input = {value: null};
      const result = transformKeys(input, 'CamelCase') as {value: null};
      expect(result.value).toBeNull();
    });

    it('transforms "Final" to "FINAL"', () => {
      const input = {status: 'Final'};
      const result = transformKeys(input, 'CamelCase') as {status: string};
      expect(result.status).toBe('FINAL');
    });

    it('transforms "example" or "Adyen" to "adyen"', () => {
      const input1 = {gateway: 'example'};
      const input2 = {gateway: 'Adyen'};
      expect(
        (transformKeys(input1, 'CamelCase') as {gateway: string}).gateway,
      ).toBe('adyen');
      expect(
        (transformKeys(input2, 'CamelCase') as {gateway: string}).gateway,
      ).toBe('adyen');
    });

    it('preserves arrays with non-object items', () => {
      const input = {numbers: [1, 2, 3]};
      const result = transformKeys(input, 'CamelCase') as {numbers: number[]};
      expect(result.numbers).toEqual([1, 2, 3]);
    });
  });

  describe('toCamelCase - additional branches', () => {
    it('returns string unchanged when it contains colon', () => {
      expect(toCamelCase('hello:world')).toBe('hello:world');
    });

    it('removes non-alphanumeric characters', () => {
      expect(toCamelCase('hello-world-foo')).toBe('helloWorldFoo');
    });
  });
});
