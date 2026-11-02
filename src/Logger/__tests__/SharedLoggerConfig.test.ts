import * as Config from '../../../shared-code/sdk-utils/logging/SharedLoggerConfig.bs.js';

describe('shared logger host policies', () => {
  it('preserves distinct masking policies and web array-path overrides', () => {
    expect(Config.Native.shouldMaskField('locale')).toBe(false);
    expect(Config.Web.shouldMaskField('locale')).toBe(true);
    expect(Config.Native.shouldMaskField('wallets.layout')).toBe(true);
    expect(Config.Web.shouldMaskField('wallets.layout')).toBe(false);
    expect(Config.Web.shouldMaskField('wallets[2].walletReturnUrl')).toBe(true);
    expect(
      Config.Web.shouldMaskField(
        'paymentMethodsConfig[0].paymentMethodTypes[1].message.value',
      ),
    ).toBe(true);
    expect(Config.Web.shouldMaskField('terms.card')).toBe(false);
    expect(Config.Native.shouldMaskField('terms.card')).toBe(true);
  });

  it('preserves the platform-specific DDC milestone severity', () => {
    expect(Config.Native.ddcStartedSeverity).toBe('INFO');
    expect(Config.Web.ddcStartedSeverity).toBe('DEBUG');
  });

  it('suppresses the native default when only a custom backend is supplied', () => {
    const fallback = jest.fn(() => 'default');
    expect(Config.selectNativeEndpoint('backend', undefined, fallback)).toBeUndefined();
    expect(fallback).not.toHaveBeenCalled();
    expect(Config.selectNativeEndpoint('backend', '', fallback)).toBe('');
    expect(fallback).not.toHaveBeenCalled();
    expect(Config.selectNativeEndpoint(undefined, undefined, fallback)).toBe('default');
    expect(fallback).toHaveBeenCalledTimes(1);
  });

  it('isolates native transport state while preserving prepared header identity', () => {
    const first = Config.makeTransport();
    const second = Config.makeTransport();
    first.endpoint.contents = 'native endpoint';
    first.headers.contents.custom = 'header';
    expect(second.endpoint.contents).toBe('');
    expect(second.headers.contents).toEqual({});
    const headers = {Authorization: 'retained', 'Content-Type': 'old'};
    expect(Config.prepareNativeHeaders(headers, 'ios')).toBe(headers);
    expect(headers).toEqual({
      Authorization: 'retained',
      'Content-Type': 'application/json',
      'X-Client-Platform': 'ios',
    });
  });
});

describe('typed Web defaults and explicit overrides', () => {
  it('uses the shared record for absent overrides', () => {
    expect(Config.Web.resolveEnabled(undefined)).toBe(Config.defaults.enableLogging);
    expect(Config.Web.resolveEndpoint(undefined)).toBe(Config.defaults.endpoint);
    expect(Config.Web.resolveMinimumRank(undefined)).toBe(Config.defaults.minimumRank);
    expect(Config.Web.resolveMaxRowsPerEventName(undefined)).toBe(Config.defaults.maxRowsPerEventName);
    expect(Config.Web.resolveMaxUserEventsPerName(undefined)).toBe(Config.defaults.maxUserEventsPerName);
  });

  it('preserves explicit false, zero and empty strings without truthiness fallbacks', () => {
    expect(Config.Web.resolveEnabled(false)).toBe(false);
    expect(Config.Web.resolveEnabled(true)).toBe(true);
    expect(Config.Web.resolveMaxRowsPerEventName(0)).toBe(0);
    expect(Config.Web.resolveMaxUserEventsPerName(0)).toBe(0);
    expect(Config.Web.resolveEndpoint('')).toBe('');
    expect(Config.Web.resolveMinimumRank('')).toBe(0);
  });

  it('retains endpoint trimming and the existing severity mapping', () => {
    expect(Config.Web.resolveEndpoint(' https://logs.test/ingest ')).toBe('https://logs.test/ingest');
    expect(Config.Web.resolveMinimumRank(' warning ')).toBe(2);
    expect(Config.Web.resolveMinimumRank('SILENT')).toBe(4);
  });
});
