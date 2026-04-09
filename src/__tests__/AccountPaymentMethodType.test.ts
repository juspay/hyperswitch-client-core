import {
  defaultAccountPaymentMethods,
  parseCardNetworks,
  parseBankNames,
  parsePaymentExperience,
  parsePaymentMethodType,
  normalizeCardType,
  createKey,
  mergePaymentMethods,
  processPaymentMethods,
  sortPaymentListArray,
  jsonToAccountPaymentMethodType,
  getEligibleConnectorFromCardNetwork,
  getEligibleConnectorFromPaymentExperience,
} from '../types/AllApiDataTypes/AccountPaymentMethodType.bs.js';

describe('AccountPaymentMethodType', () => {
  describe('defaultAccountPaymentMethods', () => {
    it('has expected default structure', () => {
      expect(defaultAccountPaymentMethods).toEqual({
        payment_methods: [],
        merchant_name: '',
        collect_billing_details_from_wallets: false,
        collect_shipping_details_from_wallets: false,
        currency: '',
        payment_type: 'NORMAL',
        payment_type_str: undefined,
        mandate_payment: undefined,
        is_tax_calculation_enabled: false,
        redirect_url: '',
        request_external_three_ds_authentication: false,
        show_surcharge_breakup_screen: false,
      });
    });

    it('has empty payment_methods array', () => {
      expect(Array.isArray(defaultAccountPaymentMethods.payment_methods)).toBe(true);
      expect(defaultAccountPaymentMethods.payment_methods).toHaveLength(0);
    });

    it('has string properties that are empty by default', () => {
      expect(defaultAccountPaymentMethods.merchant_name).toBe('');
      expect(defaultAccountPaymentMethods.currency).toBe('');
      expect(defaultAccountPaymentMethods.redirect_url).toBe('');
    });
  });

  describe('parseCardNetworks', () => {
    it('parses card networks from valid dict', () => {
      const dict = {
        card_networks: [
          { card_network: 'visa', eligible_connectors: ['stripe', 'adyen'] },
          { card_network: 'mastercard', eligible_connectors: ['paypal'] },
        ],
      };
      const result = parseCardNetworks(dict);
      expect(result).toHaveLength(2);
      expect(result[0]).toEqual({
        card_network: 'visa',
        eligible_connectors: ['stripe', 'adyen'],
      });
      expect(result[1]).toEqual({
        card_network: 'mastercard',
        eligible_connectors: ['paypal'],
      });
    });

    it('returns empty array when card_networks is missing', () => {
      const dict = {};
      const result = parseCardNetworks(dict);
      expect(result).toEqual([]);
    });

    it('returns empty array when card_networks is empty', () => {
      const dict = { card_networks: [] };
      const result = parseCardNetworks(dict);
      expect(result).toEqual([]);
    });

    it('handles card_network with empty string default', () => {
      const dict = {
        card_networks: [{ eligible_connectors: ['stripe'] }],
      };
      const result = parseCardNetworks(dict);
      expect(result[0].card_network).toBe('');
    });
  });

  describe('parseBankNames', () => {
    it('parses bank names from valid dict', () => {
      const dict = {
        bank_names: [
          { bank_name: ['Chase', 'Bank of America'], eligible_connectors: ['stripe'] },
        ],
      };
      const result = parseBankNames(dict);
      expect(result).toHaveLength(1);
      expect(result[0].bank_name).toEqual(['"Chase"', '"Bank of America"']);
      expect(result[0].eligible_connectors).toEqual(['stripe']);
    });

    it('returns empty array when bank_names is missing', () => {
      const dict = {};
      const result = parseBankNames(dict);
      expect(result).toEqual([]);
    });

    it('returns empty array when bank_names is empty', () => {
      const dict = { bank_names: [] };
      const result = parseBankNames(dict);
      expect(result).toEqual([]);
    });
  });

  describe('parsePaymentExperience', () => {
    it('parses payment experience from valid dict', () => {
      const dict = {
        payment_experience: [
          { payment_experience_type: 'invoke_sdk_client', eligible_connectors: ['stripe'] },
          { payment_experience_type: 'redirect_to_url', eligible_connectors: ['adyen'] },
        ],
      };
      const result = parsePaymentExperience(dict);
      expect(result).toHaveLength(2);
      expect(result[0]).toEqual({
        payment_experience_type: 'invoke_sdk_client',
        payment_experience_type_decode: 'INVOKE_SDK_CLIENT',
        eligible_connectors: ['stripe'],
      });
      expect(result[1]).toEqual({
        payment_experience_type: 'redirect_to_url',
        payment_experience_type_decode: 'REDIRECT_TO_URL',
        eligible_connectors: ['adyen'],
      });
    });

    it('returns empty array when payment_experience is missing', () => {
      const dict = {};
      const result = parsePaymentExperience(dict);
      expect(result).toEqual([]);
    });

    it('handles unknown payment experience type', () => {
      const dict = {
        payment_experience: [
          { payment_experience_type: 'unknown_type', eligible_connectors: [] },
        ],
      };
      const result = parsePaymentExperience(dict);
      expect(result[0].payment_experience_type_decode).toBe('NONE');
    });
  });

  describe('parsePaymentMethodType', () => {
    it('parses payment method type from valid dicts', () => {
      const paymentMethodDict = { payment_method: 'card' };
      const paymentMethodTypeDict = {
        payment_method_type: 'credit',
        card_networks: [{ card_network: 'visa', eligible_connectors: ['stripe'] }],
        bank_names: [],
        payment_experience: [],
        required_fields: { card_number: true },
      };
      const result = parsePaymentMethodType(paymentMethodDict, paymentMethodTypeDict);
      expect(result.payment_method).toBe('CARD');
      expect(result.payment_method_str).toBe('card');
      expect(result.payment_method_type).toBe('credit');
      expect(result.payment_method_type_wallet).toBe('NONE');
      expect(result.card_networks).toHaveLength(1);
      expect(result.required_fields).toEqual({ card_number: true });
    });

    it('parses wallet payment method type', () => {
      const paymentMethodDict = { payment_method: 'wallet' };
      const paymentMethodTypeDict = {
        payment_method_type: 'apple_pay',
        card_networks: [],
        bank_names: [],
        payment_experience: [],
        required_fields: {},
      };
      const result = parsePaymentMethodType(paymentMethodDict, paymentMethodTypeDict);
      expect(result.payment_method_type_wallet).toBe('APPLE_PAY');
    });

    it('handles missing optional fields with defaults', () => {
      const paymentMethodDict = {};
      const paymentMethodTypeDict = {};
      const result = parsePaymentMethodType(paymentMethodDict, paymentMethodTypeDict);
      expect(result.payment_method_str).toBe('');
      expect(result.payment_method_type).toBe('');
      expect(result.card_networks).toEqual([]);
      expect(result.bank_names).toEqual([]);
      expect(result.payment_experience).toEqual([]);
      expect(result.required_fields).toEqual({});
    });
  });

  describe('normalizeCardType', () => {
    it('normalizes credit card type to credit', () => {
      expect(normalizeCardType('card', 'credit')).toBe('credit');
    });

    it('normalizes debit card type to credit', () => {
      expect(normalizeCardType('card', 'debit')).toBe('credit');
    });

    it('returns original type for non-card payment methods', () => {
      expect(normalizeCardType('wallet', 'apple_pay')).toBe('apple_pay');
      expect(normalizeCardType('bank_transfer', 'sepa')).toBe('sepa');
    });

    it('returns original type for card with non-credit/debit type', () => {
      expect(normalizeCardType('card', 'prepaid')).toBe('prepaid');
    });

    it('handles empty strings', () => {
      expect(normalizeCardType('', 'credit')).toBe('credit');
      expect(normalizeCardType('card', '')).toBe('');
    });
  });

  describe('createKey', () => {
    it('creates key with normalized card type', () => {
      expect(createKey('card', 'credit')).toBe('card:credit');
      expect(createKey('card', 'debit')).toBe('card:credit');
    });

    it('creates key with original type for non-card methods', () => {
      expect(createKey('wallet', 'apple_pay')).toBe('wallet:apple_pay');
    });

    it('handles empty strings', () => {
      expect(createKey('', '')).toBe(':');
    });
  });

  describe('mergePaymentMethods', () => {
    it('merges card_networks arrays', () => {
      const existing = {
        payment_method: 'CARD',
        payment_method_str: 'card',
        payment_method_type: 'credit',
        payment_method_type_wallet: 'NONE',
        card_networks: [{ card_network: 'visa', eligible_connectors: ['stripe'] }],
        bank_names: [],
        payment_experience: [],
        required_fields: { cvv: true },
      };
      const newPm = {
        payment_method: 'CARD',
        payment_method_str: 'card',
        payment_method_type: 'credit',
        payment_method_type_wallet: 'NONE',
        card_networks: [{ card_network: 'mastercard', eligible_connectors: ['adyen'] }],
        bank_names: [{ bank_name: ['Chase'], eligible_connectors: [] }],
        payment_experience: [],
        required_fields: { card_number: true },
      };
      const result = mergePaymentMethods(existing, newPm);
      expect(result.card_networks).toHaveLength(2);
      expect(result.card_networks[0].card_network).toBe('visa');
      expect(result.card_networks[1].card_network).toBe('mastercard');
    });

    it('merges bank_names arrays', () => {
      const existing = {
        payment_method: 'CARD',
        payment_method_str: 'card',
        payment_method_type: 'credit',
        payment_method_type_wallet: 'NONE',
        card_networks: [],
        bank_names: [{ bank_name: ['Bank1'], eligible_connectors: [] }],
        payment_experience: [],
        required_fields: {},
      };
      const newPm = {
        payment_method: 'CARD',
        payment_method_str: 'card',
        payment_method_type: 'credit',
        payment_method_type_wallet: 'NONE',
        card_networks: [],
        bank_names: [{ bank_name: ['Bank2'], eligible_connectors: [] }],
        payment_experience: [],
        required_fields: {},
      };
      const result = mergePaymentMethods(existing, newPm);
      expect(result.bank_names).toHaveLength(2);
    });

    it('merges required_fields objects', () => {
      const existing = {
        payment_method: 'CARD',
        payment_method_str: 'card',
        payment_method_type: 'credit',
        payment_method_type_wallet: 'NONE',
        card_networks: [],
        bank_names: [],
        payment_experience: [],
        required_fields: { cvv: true, expiry: true },
      };
      const newPm = {
        payment_method: 'CARD',
        payment_method_str: 'card',
        payment_method_type: 'credit',
        payment_method_type_wallet: 'NONE',
        card_networks: [],
        bank_names: [],
        payment_experience: [],
        required_fields: { card_number: true },
      };
      const result = mergePaymentMethods(existing, newPm);
      expect(result.required_fields).toHaveProperty('cvv');
      expect(result.required_fields).toHaveProperty('expiry');
      expect(result.required_fields).toHaveProperty('card_number');
    });

    it('preserves existing metadata fields', () => {
      const existing = {
        payment_method: 'CARD',
        payment_method_str: 'card',
        payment_method_type: 'credit',
        payment_method_type_wallet: 'APPLE_PAY',
        card_networks: [],
        bank_names: [],
        payment_experience: [],
        required_fields: {},
      };
      const newPm = {
        payment_method: 'WALLET',
        payment_method_str: 'wallet',
        payment_method_type: 'google_pay',
        payment_method_type_wallet: 'GOOGLE_PAY',
        card_networks: [],
        bank_names: [],
        payment_experience: [],
        required_fields: {},
      };
      const result = mergePaymentMethods(existing, newPm);
      expect(result.payment_method).toBe('CARD');
      expect(result.payment_method_str).toBe('card');
      expect(result.payment_method_type).toBe('credit');
      expect(result.payment_method_type_wallet).toBe('APPLE_PAY');
    });
  });

  describe('processPaymentMethods', () => {
    it('processes empty array', () => {
      const result = processPaymentMethods([]);
      expect(result).toEqual([]);
    });

    it('processes single payment method with single type', () => {
      const jsonArray = [
        {
          payment_method: 'card',
          payment_method_types: [{ payment_method_type: 'credit' }],
        },
      ];
      const result = processPaymentMethods(jsonArray);
      expect(result).toHaveLength(1);
      expect(result[0].payment_method_str).toBe('card');
      expect(result[0].payment_method_type).toBe('credit');
    });

    it('merges payment methods with same key', () => {
      const jsonArray = [
        {
          payment_method: 'card',
          payment_method_types: [
            { payment_method_type: 'credit', card_networks: [{ card_network: 'visa', eligible_connectors: ['stripe'] }] },
            { payment_method_type: 'credit', card_networks: [{ card_network: 'mastercard', eligible_connectors: ['adyen'] }] },
          ],
        },
      ];
      const result = processPaymentMethods(jsonArray);
      expect(result).toHaveLength(1);
      expect(result[0].card_networks).toHaveLength(2);
    });

    it('creates separate entries for different payment method types', () => {
      const jsonArray = [
        {
          payment_method: 'card',
          payment_method_types: [
            { payment_method_type: 'credit' },
            { payment_method_type: 'debit' },
          ],
        },
      ];
      const result = processPaymentMethods(jsonArray);
      expect(result).toHaveLength(1);
      expect(result[0].payment_method_type).toBe('credit');
    });

    it('normalizes debit to credit for card payment method', () => {
      const jsonArray = [
        {
          payment_method: 'card',
          payment_method_types: [{ payment_method_type: 'debit' }],
        },
      ];
      const result = processPaymentMethods(jsonArray);
      expect(result[0].payment_method_type).toBe('credit');
    });
  });

  describe('sortPaymentListArray', () => {
    it('sorts array in place and returns it', () => {
      const plist = [
        { payment_method_type: 'credit' },
        { payment_method_type: 'apple_pay' },
        { payment_method_type: 'paypal' },
      ];
      const result = sortPaymentListArray(plist);
      expect(result).toBe(plist);
      expect(result[0].payment_method_type).toBe('apple_pay');
    });

    it('handles empty array', () => {
      const plist: any[] = [];
      const result = sortPaymentListArray(plist);
      expect(result).toEqual([]);
    });

    it('handles single element array', () => {
      const plist = [{ payment_method_type: 'credit' }];
      const result = sortPaymentListArray(plist);
      expect(result).toHaveLength(1);
    });

    it('handles unknown payment method types', () => {
      const plist = [
        { payment_method_type: 'unknown' },
        { payment_method_type: 'credit' },
      ];
      const result = sortPaymentListArray(plist);
      expect(result).toHaveLength(2);
    });
  });

  describe('jsonToAccountPaymentMethodType', () => {
    it('parses basic response', () => {
      const res = {
        merchant_name: 'Test Merchant',
        currency: 'USD',
        payment_methods: [],
      };
      const result = jsonToAccountPaymentMethodType(res);
      expect(result.merchant_name).toBe('Test Merchant');
      expect(result.currency).toBe('USD');
      expect(result.payment_type).toBe('NORMAL');
    });

    it('parses payment_type new_mandate', () => {
      const res = { payment_type: 'new_mandate' };
      const result = jsonToAccountPaymentMethodType(res);
      expect(result.payment_type).toBe('NEW_MANDATE');
    });

    it('parses payment_type setup_mandate', () => {
      const res = { payment_type: 'setup_mandate' };
      const result = jsonToAccountPaymentMethodType(res);
      expect(result.payment_type).toBe('SETUP_MANDATE');
    });

    it('defaults payment_type to NORMAL for unknown values', () => {
      const res = { payment_type: 'unknown_type' };
      const result = jsonToAccountPaymentMethodType(res);
      expect(result.payment_type).toBe('NORMAL');
    });

    it('parses boolean fields', () => {
      const res = {
        collect_billing_details_from_wallets: true,
        collect_shipping_details_from_wallets: true,
        is_tax_calculation_enabled: true,
        request_external_three_ds_authentication: true,
        show_surcharge_breakup_screen: true,
      };
      const result = jsonToAccountPaymentMethodType(res);
      expect(result.collect_billing_details_from_wallets).toBe(true);
      expect(result.collect_shipping_details_from_wallets).toBe(true);
      expect(result.is_tax_calculation_enabled).toBe(true);
      expect(result.request_external_three_ds_authentication).toBe(true);
      expect(result.show_surcharge_breakup_screen).toBe(true);
    });

    it('parses optional string fields', () => {
      const res = {
        payment_type: 'new_mandate',
        mandate_payment: 'mandate_123',
      };
      const result = jsonToAccountPaymentMethodType(res);
      expect(result.payment_type_str).toBe('new_mandate');
      expect(result.mandate_payment).toBe('mandate_123');
    });

    it('handles empty response with defaults', () => {
      const res = {};
      const result = jsonToAccountPaymentMethodType(res);
      expect(result.merchant_name).toBe('');
      expect(result.currency).toBe('');
      expect(result.payment_type).toBe('NORMAL');
      expect(result.payment_methods).toEqual([]);
      expect(result.redirect_url).toBe('');
    });
  });

  describe('getEligibleConnectorFromCardNetwork', () => {
    it('extracts eligible connectors from card networks', () => {
      const cardNetworks = [
        { card_network: 'visa', eligible_connectors: ['stripe', 'adyen'] },
        { card_network: 'mastercard', eligible_connectors: ['paypal'] },
      ];
      const result = getEligibleConnectorFromCardNetwork(cardNetworks);
      expect(result).toEqual(['stripe', 'adyen', 'paypal']);
    });

    it('returns empty array for empty input', () => {
      const result = getEligibleConnectorFromCardNetwork([]);
      expect(result).toEqual([]);
    });

    it('handles card networks with empty eligible_connectors', () => {
      const cardNetworks = [
        { card_network: 'visa', eligible_connectors: [] },
        { card_network: 'mastercard', eligible_connectors: ['stripe'] },
      ];
      const result = getEligibleConnectorFromCardNetwork(cardNetworks);
      expect(result).toEqual(['stripe']);
    });
  });

  describe('getEligibleConnectorFromPaymentExperience', () => {
    it('extracts eligible connectors from payment experiences', () => {
      const paymentExperience = [
        { payment_experience_type: 'invoke_sdk_client', payment_experience_type_decode: 'INVOKE_SDK_CLIENT', eligible_connectors: ['stripe'] },
        { payment_experience_type: 'redirect_to_url', payment_experience_type_decode: 'REDIRECT_TO_URL', eligible_connectors: ['adyen', 'paypal'] },
      ];
      const result = getEligibleConnectorFromPaymentExperience(paymentExperience);
      expect(result).toEqual(['stripe', 'adyen', 'paypal']);
    });

    it('returns empty array for empty input', () => {
      const result = getEligibleConnectorFromPaymentExperience([]);
      expect(result).toEqual([]);
    });

    it('handles payment experiences with empty eligible_connectors', () => {
      const paymentExperience = [
        { payment_experience_type: 'invoke_sdk_client', payment_experience_type_decode: 'INVOKE_SDK_CLIENT', eligible_connectors: [] },
        { payment_experience_type: 'redirect_to_url', payment_experience_type_decode: 'REDIRECT_TO_URL', eligible_connectors: ['stripe'] },
      ];
      const result = getEligibleConnectorFromPaymentExperience(paymentExperience);
      expect(result).toEqual(['stripe']);
    });
  });
});
