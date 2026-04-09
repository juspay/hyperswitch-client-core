import { stringToFieldType } from '../../shared-code/sdk-utils/types/SuperpositionTypes.bs.js';

describe('SuperpositionTypes', () => {
  describe('stringToFieldType', () => {
    it('maps email_input to EmailInput', () => {
      expect(stringToFieldType('email_input')).toBe('EmailInput');
    });

    it('maps phone_input to PhoneInput', () => {
      expect(stringToFieldType('phone_input')).toBe('PhoneInput');
    });

    it('maps country_select to CountrySelect', () => {
      expect(stringToFieldType('country_select')).toBe('CountrySelect');
    });

    it('maps state_select to StateSelect', () => {
      expect(stringToFieldType('state_select')).toBe('StateSelect');
    });

    it('maps card_number_text_input to CardNumberTextInput', () => {
      expect(stringToFieldType('card_number_text_input')).toBe('CardNumberTextInput');
    });

    it('maps cvc_password_input to CvcPasswordInput', () => {
      expect(stringToFieldType('cvc_password_input')).toBe('CvcPasswordInput');
    });

    it('maps dropdown_select to DropdownSelect', () => {
      expect(stringToFieldType('dropdown_select')).toBe('DropdownSelect');
    });

    it('maps date_picker to DatePicker', () => {
      expect(stringToFieldType('date_picker')).toBe('DatePicker');
    });

    it('maps month_select to MonthSelect', () => {
      expect(stringToFieldType('month_select')).toBe('MonthSelect');
    });

    it('maps year_select to YearSelect', () => {
      expect(stringToFieldType('year_select')).toBe('YearSelect');
    });

    it('maps currency_select to CurrencySelect', () => {
      expect(stringToFieldType('currency_select')).toBe('CurrencySelect');
    });

    it('maps country_code_select to CountryCodeSelect', () => {
      expect(stringToFieldType('country_code_select')).toBe('CountryCodeSelect');
    });

    it('maps password_input to PasswordInput', () => {
      expect(stringToFieldType('password_input')).toBe('PasswordInput');
    });

    it('returns TextInput for unknown string', () => {
      expect(stringToFieldType('unknown_field_type')).toBe('TextInput');
    });

    it('returns TextInput for empty string', () => {
      expect(stringToFieldType('')).toBe('TextInput');
    });

    it('each known field type maps to distinct value', () => {
      const knownTypes = [
        'email_input',
        'phone_input',
        'country_select',
        'state_select',
        'card_number_text_input',
        'dropdown_select',
      ];
      const mappedValues = knownTypes.map(stringToFieldType);
      const uniqueValues = new Set(mappedValues);
      expect(uniqueValues.size).toBe(mappedValues.length);
    });
  });
});
