import { BrowserRedirectionHooks } from '../hooks/AllPaymentHelperHooks.bs.js';

describe('AllPaymentHelperHooks', () => {
  describe('BrowserRedirectionHooks', () => {
    describe('useBrowserRedirectionSuccessHook', () => {
      const handler = BrowserRedirectionHooks.useBrowserRedirectionSuccessHook();

      it('calls errorCallback with defaultConfirmError when response is null', () => {
        const errorCallback = jest.fn();
        const responseCallback = jest.fn();
        handler(null, errorCallback, responseCallback);
        expect(errorCallback).toHaveBeenCalledWith(
          {
            message: 'An unknown error has occurred please retry',
            code: 'confirmPayment failed',
            type_: '',
            status: 'failed',
          },
          true,
          undefined,
        );
        expect(responseCallback).not.toHaveBeenCalled();
      });

      it('calls responseCallback with PaymentSuccess for succeeded status', () => {
        const errorCallback = jest.fn();
        const responseCallback = jest.fn();
        handler({ status: 'succeeded' }, errorCallback, responseCallback);
        expect(responseCallback).toHaveBeenCalledWith('PaymentSuccess', {
          message: '',
          code: '',
          type_: '',
          status: 'succeeded',
        });
        expect(errorCallback).not.toHaveBeenCalled();
      });

      it('calls responseCallback with ProcessingPayments for processing status', () => {
        const errorCallback = jest.fn();
        const responseCallback = jest.fn();
        handler({ status: 'processing' }, errorCallback, responseCallback);
        expect(responseCallback).toHaveBeenCalledWith('ProcessingPayments', {
          message: '',
          code: '',
          type_: '',
          status: 'processing',
        });
        expect(errorCallback).not.toHaveBeenCalled();
      });

      it('calls responseCallback with ProcessingPayments for cancelled status', () => {
        const errorCallback = jest.fn();
        const responseCallback = jest.fn();
        handler({ status: 'cancelled' }, errorCallback, responseCallback);
        expect(responseCallback).toHaveBeenCalledWith('ProcessingPayments', {
          message: '',
          code: '',
          type_: '',
          status: 'cancelled',
        });
        expect(errorCallback).not.toHaveBeenCalled();
      });

      it('calls responseCallback with ProcessingPayments for requires_capture status', () => {
        const errorCallback = jest.fn();
        const responseCallback = jest.fn();
        handler({ status: 'requires_capture' }, errorCallback, responseCallback);
        expect(responseCallback).toHaveBeenCalledWith('ProcessingPayments', {
          message: '',
          code: '',
          type_: '',
          status: 'requires_capture',
        });
      });

      it('calls responseCallback with ProcessingPayments for requires_confirmation status', () => {
        const errorCallback = jest.fn();
        const responseCallback = jest.fn();
        handler({ status: 'requires_confirmation' }, errorCallback, responseCallback);
        expect(responseCallback).toHaveBeenCalledWith('ProcessingPayments', {
          message: '',
          code: '',
          type_: '',
          status: 'requires_confirmation',
        });
      });

      it('calls responseCallback with ProcessingPayments for requires_merchant_action status', () => {
        const errorCallback = jest.fn();
        const responseCallback = jest.fn();
        handler({ status: 'requires_merchant_action' }, errorCallback, responseCallback);
        expect(responseCallback).toHaveBeenCalledWith('ProcessingPayments', {
          message: '',
          code: '',
          type_: '',
          status: 'requires_merchant_action',
        });
      });

      it('calls errorCallback for failed status (default branch)', () => {
        const errorCallback = jest.fn();
        const responseCallback = jest.fn();
        handler({ status: 'failed' }, errorCallback, responseCallback);
        expect(errorCallback).toHaveBeenCalledWith(
          {
            message: '',
            code: '',
            type_: '',
            status: 'failed',
          },
          true,
          undefined,
        );
        expect(responseCallback).not.toHaveBeenCalled();
      });

      it('calls errorCallback for unknown status (default branch)', () => {
        const errorCallback = jest.fn();
        const responseCallback = jest.fn();
        handler({ status: 'some_unknown_status' }, errorCallback, responseCallback);
        expect(errorCallback).toHaveBeenCalledWith(
          {
            message: '',
            code: '',
            type_: '',
            status: 'some_unknown_status',
          },
          true,
          undefined,
        );
      });

      it('calls errorCallback with empty status when response has no status field', () => {
        const errorCallback = jest.fn();
        const responseCallback = jest.fn();
        handler({}, errorCallback, responseCallback);
        // When status is empty string, falls into default branch
        expect(errorCallback).toHaveBeenCalledWith(
          {
            message: '',
            code: '',
            type_: '',
            status: '',
          },
          true,
          undefined,
        );
      });

      it('calls errorCallback with empty status for non-object response', () => {
        const errorCallback = jest.fn();
        const responseCallback = jest.fn();
        // getDictFromJson on a non-object returns empty dict, so status = ""
        handler('just a string', errorCallback, responseCallback);
        expect(errorCallback).toHaveBeenCalledWith(
          {
            message: '',
            code: '',
            type_: '',
            status: '',
          },
          true,
          undefined,
        );
      });
    });

    describe('useBrowserRedirectionCancelHook', () => {
      const handler = BrowserRedirectionHooks.useBrowserRedirectionCancelHook();

      it('calls responseCallback with ProcessingPayments for ACH payment method', () => {
        const errorCallback = jest.fn();
        const responseCallback = jest.fn();
        handler(errorCallback, responseCallback, 'ach');
        expect(responseCallback).toHaveBeenCalledWith('ProcessingPayments', {
          message: '',
          code: '',
          type_: '',
          status: 'Pending',
        });
        expect(errorCallback).not.toHaveBeenCalled();
      });

      it('calls errorCallback with cancelled status for non-ACH payment method', () => {
        const errorCallback = jest.fn();
        const responseCallback = jest.fn();
        handler(errorCallback, responseCallback, 'card');
        expect(errorCallback).toHaveBeenCalledWith(
          {
            message: '',
            code: '',
            type_: '',
            status: 'cancelled',
          },
          true,
          undefined,
        );
        expect(responseCallback).not.toHaveBeenCalled();
      });

      it('calls errorCallback when payment method is undefined', () => {
        const errorCallback = jest.fn();
        const responseCallback = jest.fn();
        handler(errorCallback, responseCallback, undefined);
        expect(errorCallback).toHaveBeenCalledWith(
          {
            message: '',
            code: '',
            type_: '',
            status: 'cancelled',
          },
          true,
          undefined,
        );
      });

      it('calls errorCallback when payment method is empty string', () => {
        const errorCallback = jest.fn();
        const responseCallback = jest.fn();
        handler(errorCallback, responseCallback, '');
        expect(errorCallback).toHaveBeenCalledWith(
          {
            message: '',
            code: '',
            type_: '',
            status: 'cancelled',
          },
          true,
          undefined,
        );
      });

      it('calls errorCallback for wallet payment method', () => {
        const errorCallback = jest.fn();
        const responseCallback = jest.fn();
        handler(errorCallback, responseCallback, 'google_pay');
        expect(errorCallback).toHaveBeenCalledWith(
          expect.objectContaining({ status: 'cancelled' }),
          true,
          undefined,
        );
      });
    });

    describe('useBrowserRedirectionFailedHook', () => {
      const handler = BrowserRedirectionHooks.useBrowserRedirectionFailedHook();

      it('calls errorCallback with failed status', () => {
        const errorCallback = jest.fn();
        handler(errorCallback);
        expect(errorCallback).toHaveBeenCalledWith(
          {
            message: '',
            code: '',
            type_: '',
            status: 'failed',
          },
          true,
          undefined,
        );
      });

      it('always passes true as second argument to errorCallback', () => {
        const errorCallback = jest.fn();
        handler(errorCallback);
        expect(errorCallback.mock.calls[0][1]).toBe(true);
      });

      it('always passes undefined as third argument to errorCallback', () => {
        const errorCallback = jest.fn();
        handler(errorCallback);
        expect(errorCallback.mock.calls[0][2]).toBeUndefined();
      });
    });
  });
});
