import {readFileSync} from 'fs';
import path from 'path';

import {BrowserRedirectionHooks} from '../src/hooks/AllPaymentHelperHooks.bs.js';

const runRedirectSuccess = status => {
  const calls = {response: [], error: []};
  const handler = BrowserRedirectionHooks.useBrowserRedirectionSuccessHook();
  handler(
    status === null ? null : {status},
    (errorMessage, closeSDK) => calls.error.push({errorMessage, closeSDK}),
    (paymentStatus, statusPayload) => calls.response.push({paymentStatus, statusPayload}),
  );
  return calls;
};

describe('redirect-return status handling (current behaviour)', () => {
  it.each(['processing', 'requires_capture', 'requires_confirmation', 'requires_merchant_action'])(
    'maps %s to ProcessingPayments via responseCallback',
    status => {
      const calls = runRedirectSuccess(status);
      expect(calls.error).toHaveLength(0);
      expect(calls.response).toHaveLength(1);
      expect(calls.response[0].paymentStatus).toBe('ProcessingPayments');
      expect(calls.response[0].statusPayload.status).toBe(status);
    },
  );

  it('also treats cancelled as ProcessingPayments here — unlike the confirm-response site', () => {
    const calls = runRedirectSuccess('cancelled');
    expect(calls.error).toHaveLength(0);
    expect(calls.response[0].paymentStatus).toBe('ProcessingPayments');
  });

  it('maps succeeded to PaymentSuccess', () => {
    const calls = runRedirectSuccess('succeeded');
    expect(calls.error).toHaveLength(0);
    expect(calls.response[0].paymentStatus).toBe('PaymentSuccess');
  });

  it('routes every other status to errorCallback with closeSDK true', () => {
    for (const status of ['failed', 'requires_payment_method', 'requires_customer_action', '']) {
      const calls = runRedirectSuccess(status);
      expect(calls.response).toHaveLength(0);
      expect(calls.error).toHaveLength(1);
      expect(calls.error[0].closeSDK).toBe(true);
      expect(calls.error[0].errorMessage.status).toBe(status);
    }
  });

  it('treats a null response as the default confirm error', () => {
    const calls = runRedirectSuccess(null);
    expect(calls.response).toHaveLength(0);
    expect(calls.error).toHaveLength(1);
    expect(calls.error[0].errorMessage.code).toBe('confirmPayment failed');
  });

  it('carries no card data into either callback payload', () => {
    const serialized = JSON.stringify(runRedirectSuccess('requires_capture'));
    for (const forbidden of ['card_number', 'card_cvc', 'cardNumber', 'last4', 'bin']) {
      expect(serialized).not.toContain(forbidden);
    }
  });
});

describe('confirm-response status handling (source pin, not behavioural)', () => {
  const source = readFileSync(
    path.join(__dirname, '../src/hooks/AllPaymentHooks.res'),
    'utf8',
  );

  it('groups requires_capture, processing, requires_confirmation and requires_merchant_action into one arm', () => {
    const arm = /\|\s*"requires_capture"\s*\|\s*"processing"\s*\|\s*"requires_confirmation"\s*\|\s*"requires_merchant_action"\s*=>\s*([\s\S]{0,160}?)\n/.exec(
      source,
    );
    expect(arm).not.toBeNull();
    expect(arm[1]).toContain('ProcessingPayments');
    expect(arm[1]).toContain('responseCallback');
  });

  it('handles succeeded separately as PaymentSuccess', () => {
    expect(/\|\s*"succeeded"\s*=>/.test(source)).toBe(true);
    expect(source).toContain('~paymentStatus=PaymentSuccess');
  });

  it('handles requires_customer_action separately as a browser redirection', () => {
    const arm = /\|\s*"requires_customer_action"\s*=>([\s\S]{0,600}?)\n\s*\|\s/.exec(source);
    expect(arm).not.toBeNull();
    expect(arm[1]).toContain('browserRedirectionHandler');
  });

  it('does NOT treat cancelled as processing on the confirm response', () => {
    const arm = /\|\s*"requires_capture"[\s\S]{0,200}?=>/.exec(source);
    expect(arm[0]).not.toContain('cancelled');
  });
});
