import {
  formStatusValueToString,
  formStatusValueFromString,
  eventToString,
  eventFromString,
} from '../../shared-code/sdk-utils/events/PaymentEventTypes.bs.js';

describe('PaymentEventTypes', () => {
  describe('formStatusValueToString', () => {
    it('converts Empty to string', () => {
      expect(formStatusValueToString('Empty')).toBe('EMPTY');
    });

    it('converts Filling to string', () => {
      expect(formStatusValueToString('Filling')).toBe('FILLING');
    });

    it('converts Complete to string', () => {
      expect(formStatusValueToString('Complete')).toBe('COMPLETE');
    });
  });

  describe('formStatusValueFromString', () => {
    it('converts EMPTY string to Empty', () => {
      expect(formStatusValueFromString('EMPTY')).toBe('Empty');
    });

    it('converts FILLING string to Filling', () => {
      expect(formStatusValueFromString('FILLING')).toBe('Filling');
    });

    it('converts COMPLETE string to Complete', () => {
      expect(formStatusValueFromString('COMPLETE')).toBe('Complete');
    });

    it('returns Empty for unknown string', () => {
      expect(formStatusValueFromString('UNKNOWN')).toBe('Empty');
    });

    it('returns Empty for empty string', () => {
      expect(formStatusValueFromString('')).toBe('Empty');
    });
  });

  describe('formStatusValue round-trip', () => {
    it('round-trips Empty', () => {
      expect(formStatusValueFromString(formStatusValueToString('Empty'))).toBe('Empty');
    });

    it('round-trips Filling', () => {
      expect(formStatusValueFromString(formStatusValueToString('Filling'))).toBe('Filling');
    });

    it('round-trips Complete', () => {
      expect(formStatusValueFromString(formStatusValueToString('Complete'))).toBe('Complete');
    });
  });

  describe('eventToString', () => {
    it('converts PaymentMethodInfoCard to string', () => {
      expect(eventToString('PaymentMethodInfoCard')).toBe('PAYMENT_METHOD_INFO_CARD');
    });

    it('converts PaymentMethodStatus to string', () => {
      expect(eventToString('PaymentMethodStatus')).toBe('PAYMENT_METHOD_STATUS');
    });

    it('converts FormStatus to string', () => {
      expect(eventToString('FormStatus')).toBe('FORM_STATUS');
    });

    it('converts PaymentMethodInfoBillingAddress to string', () => {
      expect(eventToString('PaymentMethodInfoBillingAddress')).toBe('PAYMENT_METHOD_INFO_BILLING_ADDRESS');
    });

    it('converts UnknownEvent to string', () => {
      expect(eventToString('UnknownEvent')).toBe('UNKNOWN_EVENT');
    });
  });

  describe('eventFromString', () => {
    it('converts PAYMENT_METHOD_INFO_CARD string to type', () => {
      expect(eventFromString('PAYMENT_METHOD_INFO_CARD')).toBe('PaymentMethodInfoCard');
    });

    it('converts PAYMENT_METHOD_STATUS string to type', () => {
      expect(eventFromString('PAYMENT_METHOD_STATUS')).toBe('PaymentMethodStatus');
    });

    it('converts FORM_STATUS string to type', () => {
      expect(eventFromString('FORM_STATUS')).toBe('FormStatus');
    });

    it('converts PAYMENT_METHOD_INFO_BILLING_ADDRESS string to type', () => {
      expect(eventFromString('PAYMENT_METHOD_INFO_BILLING_ADDRESS')).toBe('PaymentMethodInfoBillingAddress');
    });

    it('returns UnknownEvent for unknown string', () => {
      expect(eventFromString('UNKNOWN')).toBe('UnknownEvent');
    });

    it('returns UnknownEvent for empty string', () => {
      expect(eventFromString('')).toBe('UnknownEvent');
    });
  });

  describe('eventToString round-trip', () => {
    it('round-trips PaymentMethodInfoCard', () => {
      expect(eventFromString(eventToString('PaymentMethodInfoCard'))).toBe('PaymentMethodInfoCard');
    });

    it('round-trips PaymentMethodStatus', () => {
      expect(eventFromString(eventToString('PaymentMethodStatus'))).toBe('PaymentMethodStatus');
    });

    it('round-trips FormStatus', () => {
      expect(eventFromString(eventToString('FormStatus'))).toBe('FormStatus');
    });

    it('round-trips UnknownEvent', () => {
      expect(eventFromString(eventToString('UnknownEvent'))).toBe('UnknownEvent');
    });
  });
});
