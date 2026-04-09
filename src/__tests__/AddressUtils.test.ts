import {
  parseBillingAddress,
  getGooglePayBillingAddress,
  getApplePayBillingAddress,
  getFlatAddressDict,
  getCountryData,
  getPhoneCodeData,
  getStateData,
} from '../utility/logics/AddressUtils.bs.js';

describe('AddressUtils', () => {
  describe('parseBillingAddress', () => {
    it('parses full billing address', () => {
      const billingDetails = {
        address: {
          first_name: 'John',
          last_name: 'Doe',
          city: 'New York',
          country: 'US',
          line1: '123 Main St',
          line2: 'Apt 4',
          line3: 'Floor 2',
          postalCode: '10001',
          state: 'NY',
        },
        email: 'john@example.com',
        number: '1234567890',
        country_code: '+1',
      };
      const result = parseBillingAddress(billingDetails);
      expect(result.address.first_name).toBe('John');
      expect(result.address.last_name).toBe('Doe');
      expect(result.address.city).toBe('New York');
      expect(result.email).toBe('john@example.com');
      expect(result.phone.number).toBe('1234567890');
    });

    it('handles partial address with missing fields', () => {
      const billingDetails = {
        address: {
          first_name: 'John',
        },
        email: 'john@example.com',
      };
      const result = parseBillingAddress(billingDetails);
      expect(result.address.first_name).toBe('John');
      expect(result.address.city).toBeUndefined();
    });

    it('handles empty input', () => {
      const result = parseBillingAddress({});
      expect(result.address).toBeUndefined();
      expect(result.email).toBeUndefined();
    });
  });

  describe('getGooglePayBillingAddress', () => {
    it('extracts Google Pay billing address', () => {
      const dict = {
        billingAddress: {
          name: 'John Doe',
          countryCode: 'us',
          locality: 'New York',
          address1: '123 Main St',
          address2: 'Apt 4',
          address3: 'Floor 2',
          postalCode: '10001',
          administrativeArea: 'NY',
          email: 'john@example.com',
          phoneNumber: '1234567890',
        },
      };
      const result = getGooglePayBillingAddress(dict, 'billingAddress');
      expect(result).not.toBeUndefined();
      expect(result!.address.first_name).toBe('John');
      expect(result!.address.last_name).toBe('Doe');
      expect(result!.address.country).toBe('US');
      expect(result!.email).toBe('john@example.com');
    });

    it('returns undefined for missing address', () => {
      const dict = {};
      const result = getGooglePayBillingAddress(dict, 'billingAddress');
      expect(result).toBeUndefined();
    });

    it('handles empty name', () => {
      const dict = {
        billingAddress: {
          name: '',
          countryCode: 'us',
        },
      };
      const result = getGooglePayBillingAddress(dict, 'billingAddress');
      expect(result).not.toBeUndefined();
      expect(result!.address.first_name).toBe('');
      expect(result!.address.last_name).toBe('');
    });
  });

  describe('getApplePayBillingAddress', () => {
    it('extracts Apple Pay billing address', () => {
      const dict = {
        billingAddress: {
          emailAddress: 'john@example.com',
          phoneNumber: '1234567890',
          name: {
            givenName: 'John',
            familyName: 'Doe',
          },
          postalAddress: {
            street: '123 Main St\nApt 4',
            city: 'New York',
            state: 'NY',
            postalCode: '10001',
            isoCountryCode: 'us',
          },
        },
      };
      const result = getApplePayBillingAddress(
        dict,
        'billingAddress',
        undefined,
      );
      expect(result).not.toBeUndefined();
      expect(result!.address.first_name).toBe('John');
      expect(result!.address.last_name).toBe('Doe');
      expect(result!.address.country).toBe('US');
      expect(result!.email).toBe('john@example.com');
    });

    it('returns undefined for missing address', () => {
      const dict = {};
      const result = getApplePayBillingAddress(
        dict,
        'billingAddress',
        undefined,
      );
      expect(result).toBeUndefined();
    });

    it('handles multi-line street address', () => {
      const dict = {
        billingAddress: {
          emailAddress: 'john@example.com',
          name: {
            givenName: 'John',
            familyName: 'Doe',
          },
          postalAddress: {
            street: '123 Main St\nApt 4\nFloor 2',
            city: 'New York',
            state: 'NY',
            postalCode: '10001',
            isoCountryCode: 'us',
          },
        },
      };
      const result = getApplePayBillingAddress(
        dict,
        'billingAddress',
        undefined,
      );
      expect(result).not.toBeUndefined();
      expect(result!.address.line1).toBe('123 Main St');
      expect(result!.address.line2).toBe('Apt 4');
      expect(result!.address.line3).toBe('Floor 2');
    });

    it('handles shipping contact parameter', () => {
      const dict = {
        billingAddress: {
          emailAddress: 'billing@example.com',
          phoneNumber: '1111111111',
          name: {
            givenName: 'John',
            familyName: 'Doe',
          },
          postalAddress: {
            street: '123 Billing St',
            city: 'Billing City',
            state: 'BS',
            postalCode: '11111',
            isoCountryCode: 'us',
          },
        },
        shippingContact: {
          emailAddress: 'shipping@example.com',
          phoneNumber: '2222222222',
        },
      };
      const result = getApplePayBillingAddress(
        dict,
        'billingAddress',
        'shippingContact',
      );
      expect(result).not.toBeUndefined();
      expect(result!.email).toBe('shipping@example.com');
      expect(result!.phone.number).toBe('2222222222');
    });

    it('handles single line street address', () => {
      const dict = {
        billingAddress: {
          emailAddress: 'john@example.com',
          name: {
            givenName: 'John',
            familyName: 'Doe',
          },
          postalAddress: {
            street: '123 Main St',
            city: 'New York',
            state: 'NY',
            postalCode: '10001',
            isoCountryCode: 'us',
          },
        },
      };
      const result = getApplePayBillingAddress(
        dict,
        'billingAddress',
        undefined,
      );
      expect(result).not.toBeUndefined();
      expect(result!.address.line1).toBe('123 Main St');
      expect(result!.address.line2).toBeUndefined();
      expect(result!.address.line3).toBeUndefined();
    });

    it('handles two line street address', () => {
      const dict = {
        billingAddress: {
          emailAddress: 'john@example.com',
          name: {
            givenName: 'John',
            familyName: 'Doe',
          },
          postalAddress: {
            street: '123 Main St\nApt 4',
            city: 'New York',
            state: 'NY',
            postalCode: '10001',
            isoCountryCode: 'us',
          },
        },
      };
      const result = getApplePayBillingAddress(
        dict,
        'billingAddress',
        undefined,
      );
      expect(result).not.toBeUndefined();
      expect(result!.address.line1).toBe('123 Main St');
      expect(result!.address.line2).toBe('Apt 4');
      expect(result!.address.line3).toBeUndefined();
    });
  });

  describe('getFlatAddressDict', () => {
    it('flattens nested address to dotted keys', () => {
      const billingAddress = {
        address: {
          first_name: 'John',
          last_name: 'Doe',
          line1: '123 Main St',
          line2: 'Apt 4',
          line3: 'Floor 2',
          city: 'New York',
          state: 'NY',
          country: 'US',
          zip: '10001',
        },
        phone: {
          country_code: '+1',
          number: '1234567890',
        },
        email: 'john@example.com',
      };
      const result = getFlatAddressDict(billingAddress, undefined);
      expect(result['payment_method_data.billing.address.first_name']).toBe(
        'John',
      );
      expect(result['payment_method_data.billing.address.last_name']).toBe(
        'Doe',
      );
      expect(result['payment_method_data.billing.email']).toBe(
        'john@example.com',
      );
      expect(result['payment_method_data.billing.phone.number']).toBe(
        '1234567890',
      );
    });

    it('handles missing address', () => {
      const billingAddress = {
        email: 'john@example.com',
      };
      const result = getFlatAddressDict(billingAddress, undefined);
      expect(result['payment_method_data.billing.email']).toBe(
        'john@example.com',
      );
    });

    it('handles empty address object', () => {
      const billingAddress = {
        address: undefined,
        email: 'john@example.com',
      };
      const result = getFlatAddressDict(billingAddress, undefined);
      expect(result['payment_method_data.billing.email']).toBe(
        'john@example.com',
      );
    });
  });

  describe('getCountryData', () => {
    it('filters and maps country data', () => {
      const countryArr = ['US', 'CA'];
      const contextCountryData = [
        {
          country_code: 'US',
          country_name: 'United States',
          phone_number_code: '+1',
        },
        {country_code: 'CA', country_name: 'Canada', phone_number_code: '+1'},
        {country_code: 'MX', country_name: 'Mexico', phone_number_code: '+52'},
      ];
      const result = getCountryData(countryArr, contextCountryData);
      expect(result.length).toBe(2);
      expect(result[0].value).toBe('US');
      expect(result[0].label).toBe('United States');
      expect(result[1].value).toBe('CA');
    });

    it('returns empty array for no matches', () => {
      const countryArr = ['XX'];
      const contextCountryData = [
        {
          country_code: 'US',
          country_name: 'United States',
          phone_number_code: '+1',
        },
      ];
      const result = getCountryData(countryArr, contextCountryData);
      expect(result).toEqual([]);
    });

    it('handles empty country array', () => {
      const contextCountryData = [
        {
          country_code: 'US',
          country_name: 'United States',
          phone_number_code: '+1',
        },
      ];
      const result = getCountryData([], contextCountryData);
      expect(result).toEqual([]);
    });
  });

  describe('getPhoneCodeData', () => {
    it('maps country data to phone code format', () => {
      const contextCountryData = [
        {
          country_code: 'US',
          country_name: 'United States',
          phone_number_code: '+1',
        },
        {
          country_code: 'GB',
          country_name: 'United Kingdom',
          phone_number_code: '+44',
        },
      ];
      const result = getPhoneCodeData(contextCountryData);
      expect(result.length).toBe(2);
      expect(result[0].label).toBe('United States (+1)');
      expect(result[0].value).toBe('+1');
    });

    it('handles empty array', () => {
      expect(getPhoneCodeData([])).toEqual([]);
    });
  });

  describe('getStateData', () => {
    it('maps state data to label/value format', () => {
      const states = {
        US: [
          {code: 'NY', label: 'New York', value: 'New York'},
          {code: 'CA', label: 'California', value: 'California'},
        ],
      };
      const result = getStateData(states, 'US');
      expect(result.length).toBe(2);
      expect(result[0].value).toBe('NY');
      expect(result[0].label).toContain('New York');
    });

    it('returns empty array for missing country', () => {
      const states = {
        US: [{code: 'NY', label: 'New York', value: 'New York'}],
      };
      const result = getStateData(states, 'CA');
      expect(result).toEqual([]);
    });

    it('handles empty states object', () => {
      const result = getStateData({}, 'US');
      expect(result).toEqual([]);
    });

    it('formats label with code when label is present', () => {
      const states = {
        US: [{code: 'NY', label: 'New York', value: 'NY'}],
      };
      const result = getStateData(states, 'US');
      expect(result[0].label).toBe('New York - NY');
    });

    it('uses only value when label is empty', () => {
      const states = {
        US: [{code: 'NY', label: '', value: 'New York'}],
      };
      const result = getStateData(states, 'US');
      expect(result[0].label).toBe('New York');
    });
  });
});
