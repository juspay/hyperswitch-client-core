import {
  defaultSPayPaymentMethodData,
  get3DSData,
  getPaymentMethodData,
  itemToObjMapper,
  getSamsungPaySessionObject,
  getAddressFromDict,
  getAddress,
  getAddressObj,
} from '../types/SamsungPayType.bs.js';

describe('SamsungPayType', () => {
  describe('defaultSPayPaymentMethodData', () => {
    it('has correct default structure', () => {
      expect(defaultSPayPaymentMethodData).toEqual({
        payment_credential: {
          '3_d_s': {
            type: '',
            version: '',
            data: '',
          },
          card_brand: '',
          card_last4digits: '',
          method: '',
          recurring_payment: false,
        },
      });
    });

    it('payment_credential has all required fields', () => {
      const credential = defaultSPayPaymentMethodData.payment_credential;
      expect(credential).toHaveProperty('3_d_s');
      expect(credential).toHaveProperty('card_brand');
      expect(credential).toHaveProperty('card_last4digits');
      expect(credential).toHaveProperty('method');
      expect(credential).toHaveProperty('recurring_payment');
    });

    it('3_d_s has all required fields with empty string defaults', () => {
      const threeDS = defaultSPayPaymentMethodData.payment_credential['3_d_s'];
      expect(threeDS.type).toBe('');
      expect(threeDS.version).toBe('');
      expect(threeDS.data).toBe('');
    });
  });

  describe('get3DSData', () => {
    it('returns default object when key does not exist in dict', () => {
      const dict = { otherKey: 'value' };
      const result = get3DSData(dict, '3DS');
      expect(result).toEqual({
        type: '',
        version: '',
        data: '',
      });
    });

    it('returns default object when 3DS value is not an object', () => {
      const dict = { '3DS': 'string_value' };
      const result = get3DSData(dict, '3DS');
      expect(result).toEqual({
        type: '',
        version: '',
        data: '',
      });
    });

    it('extracts 3DS data with all fields', () => {
      const dict = {
        '3DS': { type: '01', version: '2.0', data: 'encrypted_data' },
      };
      const result = get3DSData(dict, '3DS');
      expect(result).toEqual({
        type: '01',
        version: '2.0',
        data: 'encrypted_data',
      });
    });

    it('handles partial 3DS data with defaults for missing fields', () => {
      const dict = {
        '3DS': { type: '01' },
      };
      const result = get3DSData(dict, '3DS');
      expect(result).toEqual({
        type: '01',
        version: '',
        data: '',
      });
    });

    it('handles empty 3DS object', () => {
      const dict = { '3DS': {} };
      const result = get3DSData(dict, '3DS');
      expect(result).toEqual({
        type: '',
        version: '',
        data: '',
      });
    });

    it('can use custom key name', () => {
      const dict = {
        customKey: { type: 'custom_type', version: '1.0', data: 'custom_data' },
      };
      const result = get3DSData(dict, 'customKey');
      expect(result).toEqual({
        type: 'custom_type',
        version: '1.0',
        data: 'custom_data',
      });
    });
  });

  describe('getPaymentMethodData', () => {
    it('returns payment method data with all fields', () => {
      const dict = {
        payment_card_brand: 'VISA',
        payment_last4_fpan: '4242',
        method: 'CARD',
        recurring_payment: true,
        '3DS': { type: '01', version: '2.0', data: 'data' },
      };
      const result = getPaymentMethodData(dict);
      expect(result).toEqual({
        payment_credential: {
          '3_d_s': {
            type: '01',
            version: '2.0',
            data: 'data',
          },
          card_brand: 'VISA',
          card_last4digits: '4242',
          method: 'CARD',
          recurring_payment: true,
        },
      });
    });

    it('returns default values for missing fields', () => {
      const dict = {};
      const result = getPaymentMethodData(dict);
      expect(result).toEqual({
        payment_credential: {
          '3_d_s': {
            type: '',
            version: '',
            data: '',
          },
          card_brand: '',
          card_last4digits: '',
          method: '',
          recurring_payment: false,
        },
      });
    });

    it('handles partial payment method data', () => {
      const dict = {
        payment_card_brand: 'MASTERCARD',
        method: 'TOKEN',
      };
      const result = getPaymentMethodData(dict);
      expect(result.payment_credential.card_brand).toBe('MASTERCARD');
      expect(result.payment_credential.method).toBe('TOKEN');
      expect(result.payment_credential.card_last4digits).toBe('');
      expect(result.payment_credential.recurring_payment).toBe(false);
    });

    it('handles false recurring_payment explicitly', () => {
      const dict = {
        recurring_payment: false,
      };
      const result = getPaymentMethodData(dict);
      expect(result.payment_credential.recurring_payment).toBe(false);
    });
  });

  describe('itemToObjMapper', () => {
    it('returns same result as getPaymentMethodData', () => {
      const dict = {
        payment_card_brand: 'AMEX',
        payment_last4_fpan: '1234',
        method: 'CARD',
        recurring_payment: false,
      };
      const result = itemToObjMapper(dict);
      expect(result).toEqual(getPaymentMethodData(dict));
    });

    it('handles empty dict', () => {
      const result = itemToObjMapper({});
      expect(result).toEqual({
        payment_credential: {
          '3_d_s': {
            type: '',
            version: '',
            data: '',
          },
          card_brand: '',
          card_last4digits: '',
          method: '',
          recurring_payment: false,
        },
      });
    });

    it('preserves all payment method fields through mapping', () => {
      const dict = {
        payment_card_brand: 'DISCOVER',
        payment_last4_fpan: '9999',
        method: 'WALLET',
        recurring_payment: true,
        '3DS': { type: '02', version: '2.1', data: 'abc123' },
      };
      const result = itemToObjMapper(dict);
      expect(result.payment_credential.card_brand).toBe('DISCOVER');
      expect(result.payment_credential.card_last4digits).toBe('9999');
      expect(result.payment_credential.method).toBe('WALLET');
      expect(result.payment_credential.recurring_payment).toBe(true);
    });
  });

  describe('getSamsungPaySessionObject', () => {
    it('returns default token when sessionData is undefined', () => {
      const result = getSamsungPaySessionObject(undefined);
      expect(result).toEqual({
        wallet_name: 'NONE',
        session_token: '',
        session_id: '',
        merchant_info: null,
        allowed_payment_methods: [],
        transaction_info: null,
        shipping_address_required: false,
        billing_address_required: false,
        email_required: false,
        shipping_address_parameters: null,
        delayed_session_token: false,
        connector: '',
        sdk_next_action: null,
        secrets: null,
        session_token_data: null,
        payment_request_data: null,
        connector_reference_id: null,
        connector_sdk_public_key: null,
        connector_merchant_id: null,
        merchant: null,
        order_number: '',
        service_id: '',
        amount: null,
        protocol: '',
        allowed_brands: [],
      });
    });

    it('returns Samsung Pay token when found in array', () => {
      const sessionData = [
        { wallet_name: 'GOOGLE_PAY', session_token: 'google_token' },
        { wallet_name: 'SAMSUNG_PAY', session_token: 'samsung_token' },
        { wallet_name: 'APPLE_PAY', session_token: 'apple_token' },
      ];
      const result = getSamsungPaySessionObject(sessionData);
      expect(result.wallet_name).toBe('SAMSUNG_PAY');
      expect(result.session_token).toBe('samsung_token');
    });

    it('returns default token when Samsung Pay not found', () => {
      const sessionData = [
        { wallet_name: 'GOOGLE_PAY', session_token: 'google_token' },
        { wallet_name: 'APPLE_PAY', session_token: 'apple_token' },
      ];
      const result = getSamsungPaySessionObject(sessionData);
      expect(result.wallet_name).toBe('NONE');
    });

    it('returns first matching Samsung Pay token', () => {
      const sessionData = [
        { wallet_name: 'SAMSUNG_PAY', session_token: 'first_samsung' },
        { wallet_name: 'SAMSUNG_PAY', session_token: 'second_samsung' },
      ];
      const result = getSamsungPaySessionObject(sessionData);
      expect(result.session_token).toBe('first_samsung');
    });

    it('handles empty array', () => {
      const result = getSamsungPaySessionObject([]);
      expect(result.wallet_name).toBe('NONE');
    });
  });

  describe('getAddressFromDict', () => {
    it('returns undefined when dict is undefined', () => {
      const result = getAddressFromDict(undefined);
      expect(result).toBeUndefined();
    });

    it('extracts all address fields from dict', () => {
      const dict = {
        first_name: 'John',
        last_name: 'Doe',
        city: 'New York',
        country: 'US',
        line1: '123 Main St',
        line2: 'Apt 4',
        zip: '10001',
        state: 'NY',
        email: 'john@example.com',
        phoneNumber: '+1234567890',
      };
      const result = getAddressFromDict(dict);
      expect(result).toEqual({
        address: {
          first_name: 'John',
          last_name: 'Doe',
          city: 'New York',
          country: 'US',
          line1: '123 Main St',
          line2: 'Apt 4',
          zip: '10001',
          state: 'NY',
        },
        email: 'john@example.com',
        phone: {
          number: '+1234567890',
        },
      });
    });

    it('handles partial address data', () => {
      const dict = {
        first_name: 'Jane',
        city: 'Los Angeles',
      };
      const result = getAddressFromDict(dict);
      expect(result?.address.first_name).toBe('Jane');
      expect(result?.address.city).toBe('Los Angeles');
      expect(result?.address.last_name).toBeUndefined();
      expect(result?.email).toBeUndefined();
    });

    it('handles empty dict', () => {
      const result = getAddressFromDict({});
      expect(result).toEqual({
        address: {
          first_name: undefined,
          last_name: undefined,
          city: undefined,
          country: undefined,
          line1: undefined,
          line2: undefined,
          zip: undefined,
          state: undefined,
        },
        email: undefined,
        phone: {
          number: undefined,
        },
      });
    });
  });

  describe('getAddress', () => {
    it('returns undefined when address is undefined', () => {
      const result = getAddress(undefined);
      expect(result).toBeUndefined();
    });

    it('parses JSON address string and extracts address data', () => {
      const address = JSON.stringify({
        first_name: 'Alice',
        last_name: 'Smith',
        city: 'Boston',
        country: 'US',
        line1: '456 Oak Ave',
        line2: '',
        zip: '02101',
        state: 'MA',
        email: 'alice@test.com',
        phoneNumber: '+1987654321',
      });
      const result = getAddress(address);
      expect(result?.address.first_name).toBe('Alice');
      expect(result?.address.last_name).toBe('Smith');
      expect(result?.address.city).toBe('Boston');
      expect(result?.email).toBe('alice@test.com');
      expect(result?.phone.number).toBe('+1987654321');
    });

    it('handles empty JSON object string', () => {
      const address = JSON.stringify({});
      const result = getAddress(address);
      expect(result).toBeDefined();
      expect(result?.address).toBeDefined();
    });

    it('handles JSON string with missing fields', () => {
      const address = JSON.stringify({
        first_name: 'Bob',
        country: 'CA',
      });
      const result = getAddress(address);
      expect(result?.address.first_name).toBe('Bob');
      expect(result?.address.country).toBe('CA');
      expect(result?.address.city).toBeUndefined();
    });
  });

  describe('getAddressObj', () => {
    it('returns undefined when addressDetails is undefined', () => {
      const result = getAddressObj(undefined, 'BILLING_ADDRESS');
      expect(result).toBeUndefined();
    });

    it('returns billing address for BILLING_ADDRESS type', () => {
      const addressDetails = {
        billingDetails: JSON.stringify({
          first_name: 'Billing',
          last_name: 'User',
          city: 'Billing City',
          country: 'US',
        }),
        shippingDetails: JSON.stringify({
          first_name: 'Shipping',
          last_name: 'User',
          city: 'Shipping City',
          country: 'US',
        }),
      };
      const result = getAddressObj(addressDetails, 'BILLING_ADDRESS');
      expect(result?.address.first_name).toBe('Billing');
      expect(result?.address.city).toBe('Billing City');
    });

    it('returns shipping address for SHIPPING_ADDRESS type', () => {
      const addressDetails = {
        billingDetails: JSON.stringify({
          first_name: 'Billing',
          city: 'Billing City',
        }),
        shippingDetails: JSON.stringify({
          first_name: 'Shipping',
          city: 'Shipping City',
        }),
      };
      const result = getAddressObj(addressDetails, 'SHIPPING_ADDRESS');
      expect(result?.address.first_name).toBe('Shipping');
      expect(result?.address.city).toBe('Shipping City');
    });

    it('returns undefined when addressDetails has undefined billingDetails', () => {
      const addressDetails = {
        billingDetails: undefined,
        shippingDetails: JSON.stringify({ first_name: 'Shipping' }),
      };
      const result = getAddressObj(addressDetails, 'BILLING_ADDRESS');
      expect(result).toBeUndefined();
    });

    it('returns undefined when addressDetails has undefined shippingDetails', () => {
      const addressDetails = {
        billingDetails: JSON.stringify({ first_name: 'Billing' }),
        shippingDetails: undefined,
      };
      const result = getAddressObj(addressDetails, 'SHIPPING_ADDRESS');
      expect(result).toBeUndefined();
    });

    it('handles missing address type fields gracefully', () => {
      const addressDetails = {};
      const result = getAddressObj(addressDetails, 'BILLING_ADDRESS');
      expect(result).toBeUndefined();
    });
  });
});
