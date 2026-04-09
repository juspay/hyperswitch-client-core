import {
  shouldEmitEvent,
  buildCardInfo,
  cardInfoToJson,
  computeFormStatus,
  buildPaymentMethodStatusEvent,
  paymentMethodStatusEventToJson,
  buildFormStatusEvent,
  formStatusEventToJson,
  buildPaymentMethodInfoAddress,
  paymentMethodInfoAddressToJson,
} from '../../shared-code/sdk-utils/events/PaymentEventData.bs.js';

describe('PaymentEventData', () => {
  describe('shouldEmitEvent', () => {
    it('returns true when event is subscribed', () => {
      expect(shouldEmitEvent('FormStatus', ['FormStatus', 'PaymentMethodStatus'])).toBe(true);
    });

    it('returns false when event is not subscribed', () => {
      expect(shouldEmitEvent('FormStatus', ['PaymentMethodStatus'])).toBe(false);
    });

    it('returns false for empty subscription list', () => {
      expect(shouldEmitEvent('FormStatus', [])).toBe(false);
    });
  });

  describe('buildCardInfo', () => {
    it('builds card info from valid card data', () => {
      const info = buildCardInfo('4111111111111111', '12/25', '123', 'Visa');
      expect(info.brand).toBe('Visa');
      expect(info.bin).toBe('411111');
      expect(info.last4).toBe('1111');
    });

    it('handles partial card data', () => {
      const info = buildCardInfo('4111', '12/25', '1', 'Visa');
      expect(info.brand).toBe('Visa');
      expect(info.bin).toBeUndefined();
      expect(info.last4).toBeUndefined();
    });

    it('handles empty card data', () => {
      const info = buildCardInfo('', '', '', '');
      expect(info.brand).toBeUndefined();
      expect(info.bin).toBeUndefined();
      expect(info.last4).toBeUndefined();
    });
  });

  describe('cardInfoToJson', () => {
    it('produces valid JSON object', () => {
      const info = {
        bin: '411111',
        last4: '1111',
        brand: 'Visa',
        expiryMonth: '12',
        expiryYear: '2025',
        formattedExpiry: '12/25',
        isCardNumberComplete: true,
        isCvcComplete: true,
        isExpiryComplete: true,
        isCardNumberValid: true,
        isExpiryValid: true,
      };
      const json = cardInfoToJson(info);
      expect(json.bin).toBe('411111');
      expect(json.last4).toBe('1111');
      expect(json.brand).toBe('Visa');
    });

    it('handles undefined values', () => {
      const info = {
        bin: undefined,
        last4: undefined,
        brand: undefined,
        expiryMonth: undefined,
        expiryYear: undefined,
        formattedExpiry: undefined,
        isCardNumberComplete: false,
        isCvcComplete: false,
        isExpiryComplete: false,
        isCardNumberValid: false,
        isExpiryValid: false,
      };
      const json = cardInfoToJson(info);
      expect(json.bin).toBeNull();
      expect(json.last4).toBeNull();
      expect(json.brand).toBeNull();
    });
  });

  describe('computeFormStatus', () => {
    it('returns Complete when isComplete is true', () => {
      expect(computeFormStatus(true, false)).toBe('Complete');
    });

    it('returns Empty when isEmpty is true and not complete', () => {
      expect(computeFormStatus(false, true)).toBe('Empty');
    });

    it('returns Filling when neither complete nor empty', () => {
      expect(computeFormStatus(false, false)).toBe('Filling');
    });
  });

  describe('buildPaymentMethodStatusEvent', () => {
    it('builds event with required fields', () => {
      const event = buildPaymentMethodStatusEvent('card', 'credit', false, false);
      expect(event.paymentMethod).toBe('card');
      expect(event.paymentMethodType).toBe('credit');
      expect(event.isSavedPaymentMethod).toBe(false);
      expect(event.isOneClickWallet).toBe(false);
    });

    it('handles optional parameters', () => {
      const event = buildPaymentMethodStatusEvent('card', 'credit');
      expect(event.isSavedPaymentMethod).toBe(false);
      expect(event.isOneClickWallet).toBe(false);
    });
  });

  describe('paymentMethodStatusEventToJson', () => {
    it('produces valid JSON', () => {
      const json = paymentMethodStatusEventToJson('card', 'credit', true, false);
      expect(json.paymentMethod).toBe('card');
      expect(json.paymentMethodType).toBe('credit');
      expect(json.isSavedPaymentMethod).toBe(true);
      expect(json.isOneClickWallet).toBe(false);
    });
  });

  describe('buildFormStatusEvent', () => {
    it('builds form status event', () => {
      const event = buildFormStatusEvent('Complete');
      expect(event.status).toBe('COMPLETE');
    });

    it('handles different statuses', () => {
      expect(buildFormStatusEvent('Empty').status).toBe('EMPTY');
      expect(buildFormStatusEvent('Filling').status).toBe('FILLING');
    });
  });

  describe('formStatusEventToJson', () => {
    it('produces valid JSON', () => {
      const json = formStatusEventToJson('Complete');
      expect(json.status).toBe('COMPLETE');
    });
  });

  describe('buildPaymentMethodInfoAddress', () => {
    it('builds address info', () => {
      const address = buildPaymentMethodInfoAddress('US', 'CA', '90210');
      expect(address.country).toBe('US');
      expect(address.state).toBe('CA');
      expect(address.postalCode).toBe('90210');
    });
  });

  describe('paymentMethodInfoAddressToJson', () => {
    it('produces valid JSON', () => {
      const json = paymentMethodInfoAddressToJson('US', 'CA', '90210');
      expect(json.country).toBe('US');
      expect(json.state).toBe('CA');
      expect(json.postalCode).toBe('90210');
    });
  });
});
