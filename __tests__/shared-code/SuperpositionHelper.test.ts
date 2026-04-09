import {
  sortFieldsByPriorityOrder,
  removeDuplicateConnectors,
  removeShippingAndDuplicateFields,
  extractFieldValuesFromPML,
  filterFieldsBasedOnMissingData,
  getOrCreateNestedDictionary,
  setValueAtNestedPath,
  removeEmptyObjects,
  convertFlatDictToNestedObject,
  convertConfigurationToRequiredFields,
} from '../../shared-code/sdk-utils/utils/SuperpositionHelper.bs.js';

describe('SuperpositionHelper', () => {
  describe('sortFieldsByPriorityOrder', () => {
    it('sorts fields by priority ascending', () => {
      const fields = [
        {name: 'c', priority: 3},
        {name: 'a', priority: 1},
        {name: 'b', priority: 2},
      ];
      const result = sortFieldsByPriorityOrder([...fields]);
      expect(result[0].name).toBe('a');
      expect(result[1].name).toBe('b');
      expect(result[2].name).toBe('c');
    });

    it('returns empty array for empty input', () => {
      expect(sortFieldsByPriorityOrder([])).toEqual([]);
    });

    it('maintains stable order for same priority', () => {
      const fields = [
        {name: 'first', priority: 1},
        {name: 'second', priority: 1},
      ];
      const result = sortFieldsByPriorityOrder([...fields]);
      expect(result[0].name).toBe('first');
      expect(result[1].name).toBe('second');
    });
  });

  describe('removeDuplicateConnectors', () => {
    it('removes duplicates from array', () => {
      const connectors = ['visa', 'mastercard', 'visa', 'amex'];
      const result = removeDuplicateConnectors(connectors);
      expect(result).toEqual(['visa', 'mastercard', 'amex']);
    });

    it('returns unchanged array with no duplicates', () => {
      const connectors = ['visa', 'mastercard', 'amex'];
      const result = removeDuplicateConnectors(connectors);
      expect(result).toEqual(['visa', 'mastercard', 'amex']);
    });

    it('returns empty array for empty input', () => {
      expect(removeDuplicateConnectors([])).toEqual([]);
    });
  });

  describe('setValueAtNestedPath', () => {
    it('sets value at simple single-level path', () => {
      const dict: any = {};
      setValueAtNestedPath(dict, ['name'], 'John');
      expect(dict.name).toBe('John');
    });

    it('creates intermediate dicts for deep nested path', () => {
      const dict: any = {};
      setValueAtNestedPath(dict, ['user', 'address', 'city'], 'NYC');
      expect(dict.user.address.city).toBe('NYC');
    });

    it('overwrites existing value', () => {
      const dict: any = {name: 'Old'};
      setValueAtNestedPath(dict, ['name'], 'New');
      expect(dict.name).toBe('New');
    });

    it('handles empty keys array', () => {
      const dict: any = {a: 1};
      const result = setValueAtNestedPath(dict, [], 'value');
      expect(result).toEqual({a: 1});
    });

    it('handles empty string keys', () => {
      const dict: any = {};
      setValueAtNestedPath(dict, ['', 'name'], 'John');
      expect(dict.name).toBe('John');
    });
  });

  describe('removeEmptyObjects', () => {
    it('removes empty nested objects', () => {
      const dict = {
        a: 1,
        b: {},
        c: {d: {}},
      };
      const result = removeEmptyObjects(dict);
      expect(result).toEqual({a: 1});
    });

    it('leaves non-empty objects unchanged', () => {
      const dict = {
        a: 1,
        b: {c: 2},
      };
      const result = removeEmptyObjects(dict);
      expect(result).toEqual({a: 1, b: {c: 2}});
    });

    it('removes deeply nested empty objects', () => {
      const dict = {
        a: {
          b: {
            c: {},
          },
        },
        d: 1,
      };
      const result = removeEmptyObjects(dict);
      expect(result).toEqual({d: 1});
    });

    it('handles empty root dict', () => {
      expect(removeEmptyObjects({})).toEqual({});
    });
  });

  describe('convertFlatDictToNestedObject', () => {
    it('converts flat dict with dot paths to nested structure', () => {
      const flat = {
        'a.b.c': 'value',
      };
      const result = convertFlatDictToNestedObject(flat);
      expect(result).toEqual({
        a: {
          b: {
            c: 'value',
          },
        },
      });
    });

    it('handles single level keys', () => {
      const flat = {
        name: 'John',
        age: '25',
      };
      const result = convertFlatDictToNestedObject(flat);
      expect(result).toEqual({name: 'John', age: '25'});
    });

    it('returns empty object for empty dict', () => {
      expect(convertFlatDictToNestedObject({})).toEqual({});
    });

    it('handles multiple nested paths', () => {
      const flat = {
        'user.name': 'John',
        'user.address.city': 'NYC',
      };
      const result = convertFlatDictToNestedObject(flat);
      expect(result).toEqual({
        user: {
          name: 'John',
          address: {
            city: 'NYC',
          },
        },
      });
    });
  });

  describe('removeShippingAndDuplicateFields', () => {
    it('removes fields with shipping prefix', () => {
      const fields = [
        {name: 'billing.address', outputPath: 'billing.address'},
        {name: 'shipping.address', outputPath: 'shipping.address'},
      ];
      const result = removeShippingAndDuplicateFields(fields);
      expect(result).toEqual([
        {name: 'billing.address', outputPath: 'billing.address'},
      ]);
    });

    it('removes duplicate fields by outputPath', () => {
      const fields = [
        {name: 'field1', outputPath: 'same.path'},
        {name: 'field2', outputPath: 'same.path'},
      ];
      const result = removeShippingAndDuplicateFields(fields);
      expect(result).toEqual([{name: 'field1', outputPath: 'same.path'}]);
    });

    it('returns empty array for empty input', () => {
      expect(removeShippingAndDuplicateFields([])).toEqual([]);
    });

    it('keeps unique non-shipping fields', () => {
      const fields = [
        {name: 'field1', outputPath: 'path1'},
        {name: 'field2', outputPath: 'path2'},
      ];
      const result = removeShippingAndDuplicateFields(fields);
      expect(result).toHaveLength(2);
    });
  });

  describe('extractFieldValuesFromPML', () => {
    it('extracts field values from valid PML data', () => {
      const requiredFields = {
        field1: {required_field: 'email', value: 'test@example.com'},
      };
      const result = extractFieldValuesFromPML(requiredFields);
      expect(result).toEqual({email: 'test@example.com'});
    });

    it('returns empty object for empty input', () => {
      expect(extractFieldValuesFromPML({})).toEqual({});
    });

    it('skips entries without required_field', () => {
      const requiredFields = {
        field1: {value: 'test@example.com'},
      };
      const result = extractFieldValuesFromPML(requiredFields);
      expect(result).toEqual({});
    });

    it('skips entries without value', () => {
      const requiredFields = {
        field1: {required_field: 'email'},
      };
      const result = extractFieldValuesFromPML(requiredFields);
      expect(result).toEqual({});
    });

    it('handles multiple valid fields', () => {
      const requiredFields = {
        field1: {required_field: 'email', value: 'test@example.com'},
        field2: {required_field: 'name', value: 'John'},
      };
      const result = extractFieldValuesFromPML(requiredFields);
      expect(result).toEqual({email: 'test@example.com', name: 'John'});
    });
  });

  describe('filterFieldsBasedOnMissingData', () => {
    it('filters fields missing from PML data', () => {
      const superpositionFields = [
        {name: 'email', outputPath: 'billing.email'},
      ];
      const pmlData = {};
      const result = filterFieldsBasedOnMissingData(
        superpositionFields,
        pmlData,
      );
      expect(result).toHaveLength(1);
      expect(result[0].name).toBe('email');
    });

    it('excludes fields present in PML data', () => {
      const superpositionFields = [
        {name: 'email', outputPath: 'billing.email'},
      ];
      const pmlData = {'billing.email': 'test@example.com'};
      const result = filterFieldsBasedOnMissingData(
        superpositionFields,
        pmlData,
      );
      expect(result).toHaveLength(0);
    });

    it('returns empty array for empty input', () => {
      expect(filterFieldsBasedOnMissingData([], {})).toEqual([]);
    });

    it('handles name fields grouping', () => {
      const superpositionFields = [
        {name: 'first_name', outputPath: 'billing.address.first_name'},
        {name: 'last_name', outputPath: 'billing.address.last_name'},
      ];
      const pmlData = {'billing.address.first_name': 'John'};
      const result = filterFieldsBasedOnMissingData(
        superpositionFields,
        pmlData,
      );
      expect(result).toHaveLength(2);
    });
  });

  describe('getOrCreateNestedDictionary', () => {
    it('returns existing nested dictionary', () => {
      const dict = {user: {name: 'John'}};
      const result = getOrCreateNestedDictionary(dict, 'user');
      expect(result).toEqual({name: 'John'});
    });

    it('creates empty dictionary for missing key', () => {
      const dict = {};
      const result = getOrCreateNestedDictionary(dict, 'user');
      expect(result).toEqual({});
    });

    it('returns empty object for undefined key', () => {
      const dict = {};
      const result = getOrCreateNestedDictionary(dict, 'nonexistent');
      expect(result).toEqual({});
    });
  });

  describe('convertConfigurationToRequiredFields', () => {
    it('converts configuration with required fields', () => {
      const config = {
        'email._required': true,
        'email._display_name': 'Email Address',
        'email._field_type': 'email_input',
        'email._priority': 1,
        'email._output_path': 'billing.email',
      };
      const result = convertConfigurationToRequiredFields(config);
      expect(result).toHaveLength(1);
      expect(result[0].name).toBe('email');
      expect(result[0].required).toBe(true);
      expect(result[0].displayName).toBe('Email Address');
      expect(result[0].priority).toBe(1);
    });

    it('excludes non-required fields', () => {
      const config = {
        'optional._required': false,
        'optional._display_name': 'Optional Field',
      };
      const result = convertConfigurationToRequiredFields(config);
      expect(result).toHaveLength(0);
    });

    it('returns empty array for empty configuration', () => {
      expect(convertConfigurationToRequiredFields({})).toEqual([]);
    });

    it('uses base name as default display name', () => {
      const config = {
        'email._required': true,
      };
      const result = convertConfigurationToRequiredFields(config);
      expect(result[0].displayName).toBe('email');
    });

    it('handles fields with options', () => {
      const config = {
        'country._required': true,
        'country._options': ['US', 'UK', 'CA'],
      };
      const result = convertConfigurationToRequiredFields(config);
      expect(result[0].options).toEqual(['US', 'UK', 'CA']);
    });

    it('defaults priority to 1000 when not specified', () => {
      const config = {
        'email._required': true,
      };
      const result = convertConfigurationToRequiredFields(config);
      expect(result[0].priority).toBe(1000);
    });
  });
});
