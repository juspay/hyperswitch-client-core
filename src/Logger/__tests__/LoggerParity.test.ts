import * as Utils from '../core/LoggerUtils.bs.js';
import * as Events from '../sdk/SdkLoggerEvents.bs.js';
import * as MerchantEvents from '../merchant/MerchantLoggerEvents.bs.js';

const {checkParity} = require('../../../scripts/check-logger-parity.cjs');
const baseline = require('./fixtures/web-contracts.json');

describe('web logger parity', () => {
  it('keeps shared events, payload types, enums, and schema version aligned', () => {
    expect(() => checkParity()).not.toThrow();
  });

  it('rejects an incompatible shared payload contract', () => {
    const changed = JSON.parse(JSON.stringify(baseline));
    changed.sdk.paymentOutcomeData =
      '{status:string,manualRetryAllowed?:bool,requiredField:string}';
    expect(() => checkParity(undefined, changed)).toThrow(
      'payload fields drifted',
    );
  });

  it('rejects missing shared events instead of allowing arbitrary native differences', () => {
    const changed = JSON.parse(JSON.stringify(baseline));
    changed.sdk.stateEvent += '|NewSharedState';
    expect(() => checkParity(undefined, changed)).toThrow(
      'shared event/enum values drifted',
    );
  });

  it('serializes the shared vault and verification values like web', () => {
    const field = {
      TAG: 'CardFieldRendered',
      _0: {scope: 'VaultForm', field: 'cardNumber'},
    };
    const spec = Utils.spec(field);
    expect(
      Utils.eventName('STATE', spec.action, spec.subject, spec.outcome),
    ).toBe('state.card_field_rendered');
    expect(Object.fromEntries(Utils.eventDetails(field))).toEqual({
      scope: 'VAULT_FORM',
      field: 'cardNumber',
    });
    expect(
      Object.fromEntries(
        Utils.eventDetails({
          TAG: 'CustomerVerificationSubmitted',
          _0: {source: 'ClickToPayOtp', provider: 'VisaUctp'},
        }),
      ),
    ).toEqual({source: 'CLICK_TO_PAY_OTP', provider: 'VISA_UCTP'});
    expect(Events.stateSeverity(field)).toBe('DEBUG');
    expect(MerchantEvents.merchantIssueSeverity('DynamicFieldsConfig')).toBe(
      'WARNING',
    );
  });
});
