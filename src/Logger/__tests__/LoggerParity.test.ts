import * as Utils from '../core/LoggerUtils.bs.js';
import * as Events from '../sdk/SdkLoggerEvents.bs.js';
import * as MerchantEvents from '../merchant/MerchantLoggerEvents.bs.js';

describe('shared event serialization', () => {
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
