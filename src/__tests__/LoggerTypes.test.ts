import {getApiInitEvent} from '../types/LoggerTypes.bs.js';

describe('LoggerTypes', () => {
  describe('getApiInitEvent', () => {
    it('returns RETRIEVE_CALL_INIT for RETRIEVE_CALL', () => {
      expect(getApiInitEvent('RETRIEVE_CALL')).toBe('RETRIEVE_CALL_INIT');
    });

    it('returns CONFIRM_CALL_INIT for CONFIRM_CALL', () => {
      expect(getApiInitEvent('CONFIRM_CALL')).toBe('CONFIRM_CALL_INIT');
    });

    it('returns SESSIONS_CALL_INIT for SESSIONS_CALL', () => {
      expect(getApiInitEvent('SESSIONS_CALL')).toBe('SESSIONS_CALL_INIT');
    });

    it('returns PAYMENT_METHODS_CALL_INIT for PAYMENT_METHODS_CALL', () => {
      expect(getApiInitEvent('PAYMENT_METHODS_CALL')).toBe(
        'PAYMENT_METHODS_CALL_INIT',
      );
    });

    it('returns CUSTOMER_PAYMENT_METHODS_CALL_INIT for CUSTOMER_PAYMENT_METHODS_CALL', () => {
      expect(getApiInitEvent('CUSTOMER_PAYMENT_METHODS_CALL')).toBe(
        'CUSTOMER_PAYMENT_METHODS_CALL_INIT',
      );
    });

    it('returns CONFIG_CALL_INIT for CONFIG_CALL', () => {
      expect(getApiInitEvent('CONFIG_CALL')).toBe('CONFIG_CALL_INIT');
    });

    it('returns AUTHENTICATION_CALL_INIT for AUTHENTICATION_CALL', () => {
      expect(getApiInitEvent('AUTHENTICATION_CALL')).toBe(
        'AUTHENTICATION_CALL_INIT',
      );
    });

    it('returns AUTHORIZE_CALL_INIT for AUTHORIZE_CALL', () => {
      expect(getApiInitEvent('AUTHORIZE_CALL')).toBe('AUTHORIZE_CALL_INIT');
    });

    it('returns POLL_STATUS_CALL_INIT for POLL_STATUS_CALL', () => {
      expect(getApiInitEvent('POLL_STATUS_CALL')).toBe('POLL_STATUS_CALL_INIT');
    });

    it('returns DELETE_PAYMENT_METHODS_CALL_INIT for DELETE_PAYMENT_METHODS_CALL', () => {
      expect(getApiInitEvent('DELETE_PAYMENT_METHODS_CALL')).toBe(
        'DELETE_PAYMENT_METHODS_CALL_INIT',
      );
    });

    it('returns ADD_PAYMENT_METHOD_CALL_INIT for ADD_PAYMENT_METHOD_CALL', () => {
      expect(getApiInitEvent('ADD_PAYMENT_METHOD_CALL')).toBe(
        'ADD_PAYMENT_METHOD_CALL_INIT',
      );
    });

    it('returns undefined for unknown event type', () => {
      expect(getApiInitEvent('UNKNOWN_EVENT')).toBeUndefined();
    });

    it('returns undefined for empty string', () => {
      expect(getApiInitEvent('')).toBeUndefined();
    });
  });
});
