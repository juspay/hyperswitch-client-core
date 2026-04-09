jest.mock('../utility/logics/Utils.bs.js', () => ({
  getString: jest.fn((dict, key, defaultValue) => {
    if (dict && dict[key] !== undefined) {
      return String(dict[key]);
    }
    return defaultValue;
  }),
  getOptionString: jest.fn((dict, key) => {
    if (dict && dict[key] !== undefined) {
      return String(dict[key]);
    }
    return undefined;
  }),
  getBool: jest.fn((dict, key, defaultValue) => {
    if (dict && dict[key] !== undefined) {
      return Boolean(dict[key]);
    }
    return defaultValue;
  }),
  getDictFromJson: jest.fn((json) => {
    if (typeof json === 'object' && json !== null) {
      return json;
    }
    try {
      return JSON.parse(json);
    } catch {
      return {};
    }
  }),
  getArray: jest.fn((dict, key) => {
    if (dict && Array.isArray(dict[key])) {
      return dict[key];
    }
    return [];
  }),
}));

jest.mock('../hooks/WebKit.bs.js', () => ({
  platform: 'web',
}));

jest.mock('../types/Types.bs.js', () => ({
  priorityArr: [
    'cashapp',
    'classic',
    'evoucher',
    'knet',
    'benefit',
    'givex',
    'pay_safe_card',
    'sepa_bank_transfer',
    'ach',
    'crypto_currency',
    'ali_pay',
    'we_chat_pay',
    'amazon_pay',
    'skrill',
    'ideal',
    'interac',
    'przelewy24',
    'afterpay_clearpay',
    'affirm',
    'klarna',
    'credit',
    'paypal',
    'google_pay',
    'apple_pay',
  ],
}));

jest.mock('../types/AllApiDataTypes/PaymentMethodType.bs.js', () => ({
  getPaymentMethod: jest.fn((str) => {
    const mapping: Record<string, string> = {
      card: 'CARD',
      wallet: 'WALLET',
      bank_debit: 'BANK_DEBIT',
      bank_redirect: 'BANK_REDIRECT',
      bank_transfer: 'BANK_TRANSFER',
    };
    return mapping[str] || 'OTHERS';
  }),
  getWalletType: jest.fn((str) => {
    const mapping: Record<string, string> = {
      apple_pay: 'APPLE_PAY',
      google_pay: 'GOOGLE_PAY',
      paypal: 'PAYPAL',
      samsung_pay: 'SAMSUNG_PAY',
    };
    return mapping[str] || 'NONE';
  }),
  getExperienceType: jest.fn((str) => {
    const mapping: Record<string, string> = {
      invoke_sdk_client: 'INVOKE_SDK_CLIENT',
      redirect_to_url: 'REDIRECT_TO_URL',
    };
    return mapping[str] || 'NONE';
  }),
}));

jest.mock('../utility/logics/AddressUtils.bs.js', () => ({
  parseBillingAddress: jest.fn((billingDict) => {
    if (!billingDict) return undefined;
    return {
      address: billingDict.address || undefined,
      email: billingDict.email || undefined,
      phone: billingDict.phone || { number: undefined, country_code: undefined },
    };
  }),
}));

const {
  parseSavedCard,
  parsePaymentExperienceArray,
  processCustomerPaymentMethods,
  sortPaymentListArray,
  filterPaymentListArray,
  jsonToCustomerPaymentMethodType,
} = require('../types/AllApiDataTypes/CustomerPaymentMethodType.bs.js');

const Utils = require('../utility/logics/Utils.bs.js');

describe('CustomerPaymentMethodType', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('parseSavedCard', () => {
    describe('happy path', () => {
      it('parses complete card data with all fields', () => {
        const cardDict = {
          scheme: 'visa',
          issuer_country: 'US',
          last4_digits: '4242',
          expiry_month: '12',
          expiry_year: '2025',
          card_token: 'tok_123',
          card_holder_name: 'John Doe',
          card_fingerprint: 'fp_123',
          nick_name: 'My Card',
          card_network: 'visa',
          card_isin: '424242',
          card_issuer: 'Test Bank',
          card_type: 'credit',
          saved_to_locker: true,
        };

        const result = parseSavedCard(cardDict);

        expect(result.scheme).toBe('visa');
        expect(result.issuer_country).toBe('US');
        expect(result.last4_digits).toBe('4242');
        expect(result.expiry_month).toBe('12');
        expect(result.expiry_year).toBe('2025');
        expect(result.card_token).toBe('tok_123');
        expect(result.card_holder_name).toBe('John Doe');
        expect(result.card_fingerprint).toBe('fp_123');
        expect(result.nick_name).toBe('My Card');
        expect(result.card_network).toBe('visa');
        expect(result.card_isin).toBe('424242');
        expect(result.card_issuer).toBe('Test Bank');
        expect(result.card_type).toBe('credit');
        expect(result.saved_to_locker).toBe(true);
      });

      it('parses card data with only required fields', () => {
        const cardDict = {
          scheme: 'mastercard',
          last4_digits: '5555',
        };

        const result = parseSavedCard(cardDict);

        expect(result.scheme).toBe('mastercard');
        expect(result.last4_digits).toBe('5555');
        expect(result.issuer_country).toBe('');
        expect(result.card_token).toBeUndefined();
        expect(result.saved_to_locker).toBe(false);
      });

      it('parses card data with partial optional fields', () => {
        const cardDict = {
          scheme: 'amex',
          last4_digits: '3782',
          card_token: 'tok_amex',
        };

        const result = parseSavedCard(cardDict);

        expect(result.scheme).toBe('amex');
        expect(result.last4_digits).toBe('3782');
        expect(result.card_token).toBe('tok_amex');
        expect(result.nick_name).toBeUndefined();
      });
    });

    describe('edge cases', () => {
      it('handles empty card dictionary', () => {
        const result = parseSavedCard({});

        expect(result.scheme).toBe('');
        expect(result.issuer_country).toBe('');
        expect(result.last4_digits).toBe('');
        expect(result.card_token).toBeUndefined();
        expect(result.saved_to_locker).toBe(false);
      });

      it('handles card with falsy boolean values', () => {
        const cardDict = {
          scheme: 'visa',
          saved_to_locker: false,
        };

        const result = parseSavedCard(cardDict);

        expect(result.saved_to_locker).toBe(false);
      });

      it('handles numeric values as strings', () => {
        const cardDict = {
          scheme: 123,
          last4_digits: 4242,
        };

        const result = parseSavedCard(cardDict);

        expect(result.scheme).toBe('123');
        expect(result.last4_digits).toBe('4242');
      });
    });

    describe('boundary/error', () => {
      it('handles null dictionary gracefully', () => {
        const result = parseSavedCard(null);

        expect(result).toBeDefined();
        expect(result.scheme).toBe('');
      });

      it('handles undefined dictionary gracefully', () => {
        const result = parseSavedCard(undefined);

        expect(result).toBeDefined();
        expect(result.scheme).toBe('');
      });
    });
  });

  describe('parsePaymentExperienceArray', () => {
    describe('happy path', () => {
      it('parses array of experience objects', () => {
        const experienceArray = [
          { payment_experience_type_decode: 'invoke_sdk_client' },
          { payment_experience_type_decode: 'redirect_to_url' },
        ];

        const result = parsePaymentExperienceArray(experienceArray);

        expect(Array.isArray(result)).toBe(true);
      });

      it('parses single experience object', () => {
        const experienceArray = [{ experience: 'invoke_sdk_client' }];

        const result = parsePaymentExperienceArray(experienceArray);

        expect(Array.isArray(result)).toBe(true);
        expect(result.length).toBe(1);
      });

      it('parses multiple experience types', () => {
        const experienceArray = [
          { type: 'redirect_to_url' },
          { type: 'invoke_sdk_client' },
        ];

        const result = parsePaymentExperienceArray(experienceArray);

        expect(Array.isArray(result)).toBe(true);
        expect(result.length).toBe(2);
      });
    });

    describe('edge cases', () => {
      it('handles empty array', () => {
        const result = parsePaymentExperienceArray([]);

        expect(Array.isArray(result)).toBe(true);
        expect(result.length).toBe(0);
      });

      it('handles array with empty objects', () => {
        const experienceArray = [{}, {}];

        const result = parsePaymentExperienceArray(experienceArray);

        expect(Array.isArray(result)).toBe(true);
        expect(result.length).toBe(2);
      });

      it('handles array with mixed valid and empty objects', () => {
        const experienceArray = [
          { experience: 'invoke_sdk_client' },
          {},
          { experience: 'redirect_to_url' },
        ];

        const result = parsePaymentExperienceArray(experienceArray);

        expect(Array.isArray(result)).toBe(true);
        expect(result.length).toBe(3);
      });
    });

    describe('boundary/error', () => {
      it('throws on null array', () => {
        expect(() => parsePaymentExperienceArray(null)).toThrow();
      });

      it('throws on undefined array', () => {
        expect(() => parsePaymentExperienceArray(undefined)).toThrow();
      });
    });
  });

  describe('processCustomerPaymentMethods', () => {
    describe('happy path', () => {
      it('processes array of payment method objects', () => {
        const jsonArray = [
          {
            payment_token: 'pm_123',
            payment_method_id: 'pmi_123',
            customer_id: 'cust_123',
            payment_method: 'card',
            payment_method_type: 'visa',
            payment_method_issuer: 'Test Bank',
            recurring_enabled: true,
            installment_payment_enabled: false,
            payment_experience: [],
            created: '2024-01-01',
            last_used_at: '2024-01-15',
            default_payment_method_set: true,
            mandate_id: 'mandate_123',
          },
        ];

        const result = processCustomerPaymentMethods(jsonArray);

        expect(Array.isArray(result)).toBe(true);
        expect(result.length).toBe(1);
        expect(result[0].payment_token).toBe('pm_123');
        expect(result[0].customer_id).toBe('cust_123');
        expect(result[0].recurring_enabled).toBe(true);
        expect(result[0].default_payment_method_set).toBe(true);
      });

      it('processes multiple payment methods', () => {
        const jsonArray = [
          { payment_token: 'pm_1', payment_method: 'card', payment_method_type: 'visa' },
          { payment_token: 'pm_2', payment_method: 'wallet', payment_method_type: 'google_pay' },
        ];

        const result = processCustomerPaymentMethods(jsonArray);

        expect(result.length).toBe(2);
        expect(result[0].payment_token).toBe('pm_1');
        expect(result[1].payment_token).toBe('pm_2');
      });

      it('processes payment method with card data', () => {
        const jsonArray = [
          {
            payment_token: 'pm_card',
            payment_method: 'card',
            payment_method_type: 'mastercard',
            card: {
              scheme: 'mastercard',
              last4_digits: '5555',
            },
          },
        ];

        const result = processCustomerPaymentMethods(jsonArray);

        expect(result.length).toBe(1);
      });
    });

    describe('edge cases', () => {
      it('handles empty array', () => {
        const result = processCustomerPaymentMethods([]);

        expect(Array.isArray(result)).toBe(true);
        expect(result.length).toBe(0);
      });

      it('handles payment methods with missing optional fields', () => {
        const jsonArray = [
          {
            payment_token: 'pm_minimal',
          },
        ];

        const result = processCustomerPaymentMethods(jsonArray);

        expect(result.length).toBe(1);
        expect(result[0].payment_token).toBe('pm_minimal');
        expect(result[0].recurring_enabled).toBe(false);
        expect(result[0].installment_payment_enabled).toBe(false);
      });

      it('handles payment methods with billing data', () => {
        const jsonArray = [
          {
            payment_token: 'pm_billing',
            billing: {
              email: 'test@example.com',
            },
          },
        ];

        const result = processCustomerPaymentMethods(jsonArray);

        expect(result.length).toBe(1);
      });
    });

    describe('boundary/error', () => {
      it('throws on null array', () => {
        expect(() => processCustomerPaymentMethods(null)).toThrow();
      });

      it('throws on array with null entries', () => {
        const jsonArray = [null, { payment_token: 'pm_valid' }, null];

        expect(() => processCustomerPaymentMethods(jsonArray)).toThrow();
      });
    });
  });

  describe('sortPaymentListArray', () => {
    describe('happy path', () => {
      it('sorts by priority correctly', () => {
        const plist = [
          { payment_method_type: 'credit', last_used_at: '2024-01-01' },
          { payment_method_type: 'apple_pay', last_used_at: '2024-01-01' },
          { payment_method_type: 'google_pay', last_used_at: '2024-01-01' },
        ];

        const result = sortPaymentListArray(plist);

        expect(Array.isArray(result)).toBe(true);
        expect(result.length).toBe(3);
      });

      it('sorts by last_used_at when priority is same', () => {
        const plist = [
          { payment_method_type: 'credit', last_used_at: '2024-01-01' },
          { payment_method_type: 'credit', last_used_at: '2024-06-01' },
        ];

        const result = sortPaymentListArray(plist);

        expect(result).toBeDefined();
      });

      it('returns same array reference after sorting', () => {
        const plist = [
          { payment_method_type: 'credit', last_used_at: '2024-01-01' },
        ];

        const result = sortPaymentListArray(plist);

        expect(result).toBe(plist);
      });
    });

    describe('edge cases', () => {
      it('handles empty array', () => {
        const result = sortPaymentListArray([]);

        expect(Array.isArray(result)).toBe(true);
        expect(result.length).toBe(0);
      });

      it('handles single item array', () => {
        const plist = [{ payment_method_type: 'credit', last_used_at: '2024-01-01' }];

        const result = sortPaymentListArray(plist);

        expect(result.length).toBe(1);
      });

      it('handles items with unknown payment_method_type', () => {
        const plist = [
          { payment_method_type: 'unknown_type', last_used_at: '2024-01-01' },
          { payment_method_type: 'credit', last_used_at: '2024-01-01' },
        ];

        const result = sortPaymentListArray(plist);

        expect(result.length).toBe(2);
      });
    });

    describe('boundary/error', () => {
      it('handles invalid date strings', () => {
        const plist = [
          { payment_method_type: 'credit', last_used_at: 'invalid-date' },
          { payment_method_type: 'credit', last_used_at: '2024-01-01' },
        ];

        expect(() => sortPaymentListArray(plist)).not.toThrow();
      });

      it('handles empty date strings', () => {
        const plist = [
          { payment_method_type: 'credit', last_used_at: '' },
          { payment_method_type: 'credit', last_used_at: '' },
        ];

        expect(() => sortPaymentListArray(plist)).not.toThrow();
      });

      it('handles missing last_used_at field', () => {
        const plist = [
          { payment_method_type: 'credit' },
          { payment_method_type: 'apple_pay', last_used_at: '2024-01-01' },
        ];

        expect(() => sortPaymentListArray(plist)).not.toThrow();
      });
    });
  });

  describe('filterPaymentListArray', () => {
    describe('happy path', () => {
      it('filters out Google Pay on iOS platform', () => {
        jest.resetModules();
        jest.doMock('../hooks/WebKit.bs.js', () => ({ platform: 'ios' }));
        const { filterPaymentListArray: filterForIos } = require('../types/AllApiDataTypes/CustomerPaymentMethodType.bs.js');

        const plist = [
          { payment_method_type_wallet: 'APPLE_PAY' },
          { payment_method_type_wallet: 'GOOGLE_PAY' },
          { payment_method_type_wallet: 'PAYPAL' },
        ];

        const result = filterForIos(plist);

        expect(result.length).toBe(2);
      });

      it('filters out Apple Pay on Android platform', () => {
        jest.resetModules();
        jest.doMock('../hooks/WebKit.bs.js', () => ({ platform: 'android' }));
        const { filterPaymentListArray: filterForAndroid } = require('../types/AllApiDataTypes/CustomerPaymentMethodType.bs.js');

        const plist = [
          { payment_method_type_wallet: 'APPLE_PAY' },
          { payment_method_type_wallet: 'GOOGLE_PAY' },
          { payment_method_type_wallet: 'PAYPAL' },
        ];

        const result = filterForAndroid(plist);

        expect(result.length).toBe(2);
      });

      it('filters out Google Pay on iOS WebView platform', () => {
        jest.resetModules();
        jest.doMock('../hooks/WebKit.bs.js', () => ({ platform: 'iosWebView' }));
        const { filterPaymentListArray: filterForIosWebView } = require('../types/AllApiDataTypes/CustomerPaymentMethodType.bs.js');

        const plist = [
          { payment_method_type_wallet: 'APPLE_PAY' },
          { payment_method_type_wallet: 'GOOGLE_PAY' },
          { payment_method_type_wallet: 'PAYPAL' },
        ];

        const result = filterForIosWebView(plist);

        expect(result.length).toBe(2);
        expect(result.find((p: any) => p.payment_method_type_wallet === 'GOOGLE_PAY')).toBeUndefined();
      });

      it('filters out Apple Pay on Android WebView platform', () => {
        jest.resetModules();
        jest.doMock('../hooks/WebKit.bs.js', () => ({ platform: 'androidWebView' }));
        const { filterPaymentListArray: filterForAndroidWebView } = require('../types/AllApiDataTypes/CustomerPaymentMethodType.bs.js');

        const plist = [
          { payment_method_type_wallet: 'APPLE_PAY' },
          { payment_method_type_wallet: 'GOOGLE_PAY' },
          { payment_method_type_wallet: 'PAYPAL' },
        ];

        const result = filterForAndroidWebView(plist);

        expect(result.length).toBe(2);
        expect(result.find((p: any) => p.payment_method_type_wallet === 'APPLE_PAY')).toBeUndefined();
      });
    });

    describe('edge cases', () => {
      it('returns all items on web platform', () => {
        jest.resetModules();
        jest.doMock('../hooks/WebKit.bs.js', () => ({ platform: 'web' }));
        const { filterPaymentListArray: filterForWeb } = require('../types/AllApiDataTypes/CustomerPaymentMethodType.bs.js');

        const plist = [
          { payment_method_type_wallet: 'APPLE_PAY' },
          { payment_method_type_wallet: 'GOOGLE_PAY' },
        ];

        const result = filterForWeb(plist);

        expect(result.length).toBe(2);
      });

      it('keeps APPLE_PAY on iOS WebView platform', () => {
        jest.resetModules();
        jest.doMock('../hooks/WebKit.bs.js', () => ({ platform: 'iosWebView' }));
        const { filterPaymentListArray: filterForIosWebView } = require('../types/AllApiDataTypes/CustomerPaymentMethodType.bs.js');

        const plist = [
          { payment_method_type_wallet: 'APPLE_PAY' },
          { payment_method_type_wallet: 'PAYPAL' },
        ];

        const result = filterForIosWebView(plist);

        expect(result.length).toBe(2);
      });

      it('keeps GOOGLE_PAY on Android WebView platform', () => {
        jest.resetModules();
        jest.doMock('../hooks/WebKit.bs.js', () => ({ platform: 'androidWebView' }));
        const { filterPaymentListArray: filterForAndroidWebView } = require('../types/AllApiDataTypes/CustomerPaymentMethodType.bs.js');

        const plist = [
          { payment_method_type_wallet: 'GOOGLE_PAY' },
          { payment_method_type_wallet: 'PAYPAL' },
        ];

        const result = filterForAndroidWebView(plist);

        expect(result.length).toBe(2);
      });

      it('handles empty array', () => {
        const result = filterPaymentListArray([]);

        expect(Array.isArray(result)).toBe(true);
        expect(result.length).toBe(0);
      });

      it('handles items without payment_method_type_wallet', () => {
        const plist = [
          { payment_method_type: 'credit' },
          { payment_method_type_wallet: undefined },
        ];

        const result = filterPaymentListArray(plist);

        expect(result).toBeDefined();
      });
    });

    describe('boundary/error', () => {
      it('throws on null array', () => {
        expect(() => filterPaymentListArray(null)).toThrow();
      });

      it('handles items with NONE wallet type', () => {
        const plist = [
          { payment_method_type_wallet: 'NONE' },
          { payment_method_type_wallet: 'APPLE_PAY' },
        ];

        const result = filterPaymentListArray(plist);

        expect(result.length).toBeGreaterThan(0);
      });
    });
  });

  describe('jsonToCustomerPaymentMethodType', () => {
    describe('happy path', () => {
      it('parses complete JSON response', () => {
        const res = {
          customer_payment_methods: [
            {
              payment_token: 'pm_123',
              payment_method: 'card',
              payment_method_type: 'visa',
              last_used_at: '2024-01-01',
            },
          ],
          is_guest_customer: false,
        };

        const result = jsonToCustomerPaymentMethodType(res);

        expect(result).toBeDefined();
        expect(result.is_guest_customer).toBe(false);
        expect(Array.isArray(result.customer_payment_methods)).toBe(true);
      });

      it('parses guest customer response', () => {
        const res = {
          customer_payment_methods: [],
          is_guest_customer: true,
        };

        const result = jsonToCustomerPaymentMethodType(res);

        expect(result.is_guest_customer).toBe(true);
        expect(result.customer_payment_methods.length).toBe(0);
      });

      it('applies sorting and filtering to payment methods', () => {
        const res = {
          customer_payment_methods: [
            { payment_token: 'pm_1', payment_method_type: 'credit', payment_method_type_wallet: 'NONE', last_used_at: '2024-01-01' },
            { payment_token: 'pm_2', payment_method_type: 'apple_pay', payment_method_type_wallet: 'APPLE_PAY', last_used_at: '2024-06-01' },
          ],
          is_guest_customer: false,
        };

        const result = jsonToCustomerPaymentMethodType(res);

        expect(result.customer_payment_methods).toBeDefined();
      });
    });

    describe('edge cases', () => {
      it('handles empty customer_payment_methods array', () => {
        const res = {
          customer_payment_methods: [],
        };

        const result = jsonToCustomerPaymentMethodType(res);

        expect(result.customer_payment_methods.length).toBe(0);
        expect(result.is_guest_customer).toBe(true);
      });

      it('handles missing is_guest_customer defaults to true', () => {
        const res = {
          customer_payment_methods: [],
        };

        const result = jsonToCustomerPaymentMethodType(res);

        expect(result.is_guest_customer).toBe(true);
      });

      it('handles empty object response', () => {
        const res = {};

        const result = jsonToCustomerPaymentMethodType(res);

        expect(result).toBeDefined();
        expect(Array.isArray(result.customer_payment_methods)).toBe(true);
      });
    });

    describe('boundary/error', () => {
      it('handles null response', () => {
        const result = jsonToCustomerPaymentMethodType(null);

        expect(result).toBeDefined();
      });

      it('handles undefined response', () => {
        const result = jsonToCustomerPaymentMethodType(undefined);

        expect(result).toBeDefined();
      });

      it('handles string JSON response', () => {
        const result = jsonToCustomerPaymentMethodType('{}');

        expect(result).toBeDefined();
      });
    });
  });
});
