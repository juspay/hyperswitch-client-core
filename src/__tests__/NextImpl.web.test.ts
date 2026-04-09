const { clistRes, listRes, sessionsRes } = require('../utility/config/next/NextImpl.web.bs.js');

describe('NextImpl.web', () => {
  describe('clistRes', () => {
    it('parses to a valid customer list object', () => {
      expect(clistRes).toBeDefined();
      expect(typeof clistRes).toBe('object');
    });

    it('contains customer_payment_methods array', () => {
      expect(clistRes).toHaveProperty('customer_payment_methods');
      expect(Array.isArray(clistRes.customer_payment_methods)).toBe(true);
    });

    it('has is_guest_customer property set to true', () => {
      expect(clistRes).toHaveProperty('is_guest_customer', true);
    });

    it('customer_payment_methods is empty array', () => {
      expect(clistRes.customer_payment_methods).toEqual([]);
    });
  });

  describe('listRes', () => {
    it('parses to a valid list response object', () => {
      expect(listRes).toBeDefined();
      expect(typeof listRes).toBe('object');
    });

    it('contains redirect_url property', () => {
      expect(listRes).toHaveProperty('redirect_url');
      expect(listRes.redirect_url).toBe('https://www.example.com/success');
    });

    it('contains currency property', () => {
      expect(listRes).toHaveProperty('currency', 'USD');
    });

    it('contains payment_methods array', () => {
      expect(listRes).toHaveProperty('payment_methods');
      expect(Array.isArray(listRes.payment_methods)).toBe(true);
      expect(listRes.payment_methods.length).toBeGreaterThan(0);
    });

    it('payment_methods contain payment_method property', () => {
      const firstPaymentMethod = listRes.payment_methods[0];
      expect(firstPaymentMethod).toHaveProperty('payment_method', 'bank_transfer');
    });

    it('payment_method_types contain required_fields', () => {
      const firstPaymentMethod = listRes.payment_methods[0];
      const firstPmType = firstPaymentMethod.payment_method_types[0];
      expect(firstPmType).toHaveProperty('required_fields');
      expect(firstPmType.required_fields['billing.email']).toBeDefined();
      expect(firstPmType.required_fields['billing.email'].display_name).toBe('email');
    });

    it('payment_method_types contain surcharge_details', () => {
      const firstPaymentMethod = listRes.payment_methods[0];
      const firstPmType = firstPaymentMethod.payment_method_types[0];
      expect(firstPmType).toHaveProperty('surcharge_details');
      expect(firstPmType.surcharge_details).toHaveProperty('surcharge');
      expect(firstPmType.surcharge_details.surcharge.type).toBe('rate');
    });
  });

  describe('sessionsRes', () => {
    it('parses to a valid sessions response object', () => {
      expect(sessionsRes).toBeDefined();
      expect(typeof sessionsRes).toBe('object');
    });

    it('contains payment_id property', () => {
      expect(sessionsRes).toHaveProperty('payment_id', 'pay_NqAQn9DZQr0uuONSmV9K');
    });

    it('contains client_secret property', () => {
      expect(sessionsRes).toHaveProperty('client_secret', 'pay_sample_secret_sample');
    });

    it('contains session_token array', () => {
      expect(sessionsRes).toHaveProperty('session_token');
      expect(Array.isArray(sessionsRes.session_token)).toBe(true);
      expect(sessionsRes.session_token.length).toBeGreaterThan(0);
    });

    it('session_token contains wallet_name', () => {
      const firstSession = sessionsRes.session_token[0];
      expect(firstSession).toHaveProperty('wallet_name', 'google_pay');
    });

    it('session_token contains merchant_info', () => {
      const firstSession = sessionsRes.session_token[0];
      expect(firstSession).toHaveProperty('merchant_info');
      expect(firstSession.merchant_info).toHaveProperty('merchant_id', 'juspay_us_sandbox');
      expect(firstSession.merchant_info).toHaveProperty('merchant_name', 'juspay_us_sandbox');
    });

    it('session_token contains shipping_address_required property', () => {
      const firstSession = sessionsRes.session_token[0];
      expect(firstSession).toHaveProperty('shipping_address_required', false);
    });

    it('session_token contains email_required property', () => {
      const firstSession = sessionsRes.session_token[0];
      expect(firstSession).toHaveProperty('email_required', true);
    });

    it('session_token contains allowed_payment_methods array', () => {
      const firstSession = sessionsRes.session_token[0];
      expect(firstSession).toHaveProperty('allowed_payment_methods');
      expect(Array.isArray(firstSession.allowed_payment_methods)).toBe(true);
    });

    it('allowed_payment_methods contains CARD type with parameters', () => {
      const firstSession = sessionsRes.session_token[0];
      const firstAllowedMethod = firstSession.allowed_payment_methods[0];
      expect(firstAllowedMethod).toHaveProperty('type', 'CARD');
      expect(firstAllowedMethod).toHaveProperty('parameters');
      expect(firstAllowedMethod.parameters).toHaveProperty('allowed_auth_methods');
      expect(firstAllowedMethod.parameters.allowed_auth_methods).toContain('PAN_ONLY');
      expect(firstAllowedMethod.parameters.allowed_auth_methods).toContain('CRYPTOGRAM_3DS');
    });
  });
});
