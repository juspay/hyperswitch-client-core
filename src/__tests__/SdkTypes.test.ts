import {
  walletNameMapper,
  walletNameToTypeMapper,
  widgetToStrMapper,
  walletTypeToStrMapper,
  sdkStateToStrMapper,
  defaultAppearance,
  getColorFromDict,
  getPrimaryButtonColorFromDict,
  getAppearanceObj,
  getPrimaryColor,
  parseConfigurationDict,
  nativeJsonToRecord,
  defaultCountry,
} from '../types/SdkTypes.bs.js';

jest.mock('../hooks/WebKit.bs.js', () => ({
  platform: 'web',
}));

jest.mock('react-native', () => ({
  Platform: {
    OS: 'web',
  },
}));

const rnKeys = {
  locale: 'locale',
  colors: 'colors',
  light: 'light',
  dark: 'dark',
  primary: 'primary',
  background: 'background',
  componentBackground: 'componentBackground',
  componentBorder: 'componentBorder',
  componentDivider: 'componentDivider',
  componentText: 'componentText',
  primaryText: 'primaryText',
  secondaryText: 'secondaryText',
  placeholderText: 'placeholderText',
  icon: 'icon',
  error: 'error',
  shapes: 'shapes',
  borderRadius: 'borderRadius',
  borderWidth: 'borderWidth',
  shadow: 'shadow',
  shadow_color: 'color',
  shadow_opacity: 'opacity',
  shadow_blurRadius: 'blurRadius',
  shadow_offset: 'offset',
  shadow_intensity: 'intensity',
  x: 'x',
  y: 'y',
  font: 'font',
  family: 'fontResId',
  scale: 'sizeScaleFactor',
  headingTextSizeAdjust: 'headingTextSizeAdjust',
  subHeadingTextSizeAdjust: 'subHeadingTextSizeAdjust',
  placeholderTextSizeAdjust: 'placeholderTextSizeAdjust',
  buttonTextSizeAdjust: 'buttonTextSizeAdjust',
  errorTextSizeAdjust: 'errorTextSizeAdjust',
  linkTextSizeAdjust: 'linkTextSizeAdjust',
  modalTextSizeAdjust: 'modalTextSizeAdjust',
  cardTextSizeAdjust: 'cardTextSizeAdjust',
  primaryButton: 'primaryButton',
  primaryButton_font: 'typography',
  primaryButton_family: 'fontResId',
  primaryButton_scale: 'fontSizeSp',
  primaryButton_shapes: 'shapes',
  primaryButton_borderRadius: 'borderRadius',
  primaryButton_borderWidth: 'borderWidth',
  primaryButton_shadow: 'shadow',
  primaryButton_color: 'colors',
  primaryButton_intensity: 'intensity',
  primaryButton_opacity: '',
  primaryButton_blurRadius: '',
  primaryButton_offset: '',
  primaryButton_light: 'light',
  primaryButton_dark: 'dark',
  primaryButton_background: 'background',
  primaryButton_text: 'text',
  primaryButton_border: 'border',
  loadingBgColor: 'loaderBackground',
  loadingFgColor: 'loaderForeground',
};

describe('SdkTypes', () => {
  describe('walletNameMapper', () => {
    it('maps apple_pay to Apple Pay', () => {
      expect(walletNameMapper('apple_pay')).toBe('Apple Pay');
    });

    it('maps google_pay to Google Pay', () => {
      expect(walletNameMapper('google_pay')).toBe('Google Pay');
    });

    it('maps paypal to Paypal', () => {
      expect(walletNameMapper('paypal')).toBe('Paypal');
    });

    it('maps samsung_pay to Samsung Pay', () => {
      expect(walletNameMapper('samsung_pay')).toBe('Samsung Pay');
    });

    it('returns empty string for unknown wallet', () => {
      expect(walletNameMapper('unknown_wallet')).toBe('');
    });

    it('returns empty string for empty string', () => {
      expect(walletNameMapper('')).toBe('');
    });
  });

  describe('walletNameToTypeMapper', () => {
    it('maps Apple Pay to APPLE_PAY', () => {
      expect(walletNameToTypeMapper('Apple Pay')).toBe('APPLE_PAY');
    });

    it('maps Google Pay to GOOGLE_PAY', () => {
      expect(walletNameToTypeMapper('Google Pay')).toBe('GOOGLE_PAY');
    });

    it('maps Paypal to PAYPAL', () => {
      expect(walletNameToTypeMapper('Paypal')).toBe('PAYPAL');
    });

    it('maps Samsung Pay to SAMSUNG_PAY', () => {
      expect(walletNameToTypeMapper('Samsung Pay')).toBe('SAMSUNG_PAY');
    });

    it('returns NONE for unknown wallet name', () => {
      expect(walletNameToTypeMapper('Unknown')).toBe('NONE');
    });

    it('returns NONE for empty string', () => {
      expect(walletNameToTypeMapper('')).toBe('NONE');
    });
  });

  describe('widgetToStrMapper', () => {
    it('maps GOOGLE_PAY to GOOGLE_PAY', () => {
      expect(widgetToStrMapper('GOOGLE_PAY')).toBe('GOOGLE_PAY');
    });

    it('maps PAYPAL to PAYPAL', () => {
      expect(widgetToStrMapper('PAYPAL')).toBe('PAYPAL');
    });

    it('returns empty string for unknown widget', () => {
      expect(widgetToStrMapper('UNKNOWN')).toBe('');
    });

    it('returns empty string for empty string', () => {
      expect(widgetToStrMapper('')).toBe('');
    });
  });

  describe('walletTypeToStrMapper', () => {
    it('maps GOOGLE_PAY to google_pay', () => {
      expect(walletTypeToStrMapper('GOOGLE_PAY')).toBe('google_pay');
    });

    it('maps APPLE_PAY to apple_pay', () => {
      expect(walletTypeToStrMapper('APPLE_PAY')).toBe('apple_pay');
    });

    it('maps PAYPAL to paypal', () => {
      expect(walletTypeToStrMapper('PAYPAL')).toBe('paypal');
    });

    it('maps SAMSUNG_PAY to samsung_pay', () => {
      expect(walletTypeToStrMapper('SAMSUNG_PAY')).toBe('samsung_pay');
    });

    it('maps NONE to empty string', () => {
      expect(walletTypeToStrMapper('NONE')).toBe('');
    });
  });

  describe('sdkStateToStrMapper', () => {
    it('maps PaymentSheet to PAYMENT_SHEET', () => {
      expect(sdkStateToStrMapper('PaymentSheet')).toBe('PAYMENT_SHEET');
    });

    it('maps ButtonSheet to BUTTON_SHEET', () => {
      expect(sdkStateToStrMapper('ButtonSheet')).toBe('BUTTON_SHEET');
    });

    it('maps TabSheet to TAB_SHEET', () => {
      expect(sdkStateToStrMapper('TabSheet')).toBe('TAB_SHEET');
    });

    it('maps WidgetPaymentSheet to WIDGET_PAYMENT_SHEET', () => {
      expect(sdkStateToStrMapper('WidgetPaymentSheet')).toBe('WIDGET_PAYMENT_SHEET');
    });

    it('maps WidgetButtonSheet to WIDGET_BUTTON_SHEET', () => {
      expect(sdkStateToStrMapper('WidgetButtonSheet')).toBe('WIDGET_BUTTON_SHEET');
    });

    it('maps WidgetTabSheet to WIDGET_TAB_SHEET', () => {
      expect(sdkStateToStrMapper('WidgetTabSheet')).toBe('WIDGET_TAB_SHEET');
    });

    it('maps HostedCheckout to HOSTED_CHECKOUT', () => {
      expect(sdkStateToStrMapper('HostedCheckout')).toBe('HOSTED_CHECKOUT');
    });

    it('maps CardWidget to CARD_FORM', () => {
      expect(sdkStateToStrMapper('CardWidget')).toBe('CARD_FORM');
    });

    it('maps ExpressCheckoutWidget to EXPRESS_CHECKOUT_WIDGET', () => {
      expect(sdkStateToStrMapper('ExpressCheckoutWidget')).toBe('EXPRESS_CHECKOUT_WIDGET');
    });

    it('maps PaymentMethodsManagement to PAYMENT_METHODS_MANAGEMENT', () => {
      expect(sdkStateToStrMapper('PaymentMethodsManagement')).toBe('PAYMENT_METHODS_MANAGEMENT');
    });

    it('maps Headless to HEADLESS', () => {
      expect(sdkStateToStrMapper('Headless')).toBe('HEADLESS');
    });

    it('maps NoView to NO_VIEW', () => {
      expect(sdkStateToStrMapper('NoView')).toBe('NO_VIEW');
    });

    it('handles CustomWidget object with GOOGLE_PAY', () => {
      expect(sdkStateToStrMapper({ _0: 'GOOGLE_PAY' })).toBe('GOOGLE_PAY');
    });

    it('handles CustomWidget object with PAYPAL', () => {
      expect(sdkStateToStrMapper({ _0: 'PAYPAL' })).toBe('PAYPAL');
    });
  });

  describe('defaultAppearance', () => {
    it('has default theme as Default', () => {
      expect(defaultAppearance.theme).toBe('Default');
    });

    it('has default layout as Tab', () => {
      expect(defaultAppearance.layout).toBe('Tab');
    });

    it('has undefined locale by default', () => {
      expect(defaultAppearance.locale).toBeUndefined();
    });

    it('has googlePay with buttonType PLAIN', () => {
      expect(defaultAppearance.googlePay.buttonType).toBe('PLAIN');
    });

    it('has applePay with buttonType plain', () => {
      expect(defaultAppearance.applePay.buttonType).toBe('plain');
    });
  });

  describe('getColorFromDict', () => {
    const keys = {
      primary: 'primary',
      background: 'background',
      componentBackground: 'componentBackground',
      componentBorder: 'componentBorder',
      componentDivider: 'componentDivider',
      componentText: 'componentText',
      primaryText: 'primaryText',
      secondaryText: 'secondaryText',
      placeholderText: 'placeholderText',
      icon: 'icon',
      error: 'error',
      loadingBgColor: 'loadingBgColor',
      loadingFgColor: 'loadingFgColor',
    };

    it('extracts all colors from dict', () => {
      const colorDict = {
        primary: '#FF0000',
        background: '#FFFFFF',
        componentBackground: '#F5F5F5',
        componentBorder: '#CCCCCC',
        componentDivider: '#DDDDDD',
        componentText: '#333333',
        primaryText: '#000000',
        secondaryText: '#666666',
        placeholderText: '#999999',
        icon: '#444444',
        error: '#FF0000',
        loadingBgColor: '#EEEEEE',
        loadingFgColor: '#0000FF',
      };
      const result = getColorFromDict(colorDict, keys);
      expect(result.primary).toBe('#FF0000');
      expect(result.background).toBe('#FFFFFF');
      expect(result.error).toBe('#FF0000');
    });

    it('returns undefined for missing keys', () => {
      const result = getColorFromDict({}, keys);
      expect(result.primary).toBeUndefined();
      expect(result.background).toBeUndefined();
    });

    it('handles partial color dict', () => {
      const colorDict = { primary: '#FF0000' };
      const result = getColorFromDict(colorDict, keys);
      expect(result.primary).toBe('#FF0000');
      expect(result.background).toBeUndefined();
    });
  });

  describe('getPrimaryButtonColorFromDict', () => {
    const keys = {
      primaryButton_background: 'background',
      primaryButton_text: 'text',
      primaryButton_border: 'border',
    };

    it('extracts primary button colors from dict', () => {
      const dict = {
        background: '#000000',
        text: '#FFFFFF',
        border: '#CCCCCC',
      };
      const result = getPrimaryButtonColorFromDict(dict, keys);
      expect(result.background).toBe('#000000');
      expect(result.text).toBe('#FFFFFF');
      expect(result.border).toBe('#CCCCCC');
    });

    it('returns undefined for missing keys', () => {
      const result = getPrimaryButtonColorFromDict({}, keys);
      expect(result.background).toBeUndefined();
      expect(result.text).toBeUndefined();
      expect(result.border).toBeUndefined();
    });

    it('handles partial dict', () => {
      const dict = { background: '#000000' };
      const result = getPrimaryButtonColorFromDict(dict, keys);
      expect(result.background).toBe('#000000');
      expect(result.text).toBeUndefined();
    });
  });

  describe('getAppearanceObj', () => {
    it('returns default appearance for empty dict', () => {
      const result = getAppearanceObj({}, rnKeys, 'rn');
      expect(result.theme).toBe('Default');
      expect(result.layout).toBe('Tab');
      expect(result.locale).toBe('En');
    });

    it('parses locale from appearance dict', () => {
      const dict = { locale: 'fr' };
      const result = getAppearanceObj(dict, rnKeys, 'rn');
      expect(result.locale).toBe('Fr');
    });

    it('parses theme from appearance dict', () => {
      const dict = { theme: 'Dark' };
      const result = getAppearanceObj(dict, rnKeys, 'rn');
      expect(result.theme).toBe('Dark');
    });

    it('parses layout from appearance dict', () => {
      const dict = { layout: 'accordion' };
      const result = getAppearanceObj(dict, rnKeys, 'rn');
      expect(result.layout).toBe('Accordion');
    });

    it('parses spacedAccordion layout', () => {
      const dict = { layout: 'spacedAccordion' };
      const result = getAppearanceObj(dict, rnKeys, 'rn');
      expect(result.layout).toBe('SpacedAccordion');
    });

    it('parses Minimal theme', () => {
      const dict = { theme: 'Minimal' };
      const result = getAppearanceObj(dict, rnKeys, 'rn');
      expect(result.theme).toBe('Minimal');
    });

    it('parses FlatMinimal theme', () => {
      const dict = { theme: 'FlatMinimal' };
      const result = getAppearanceObj(dict, rnKeys, 'rn');
      expect(result.theme).toBe('FlatMinimal');
    });

    it('parses Light theme', () => {
      const dict = { theme: 'Light' };
      const result = getAppearanceObj(dict, rnKeys, 'rn');
      expect(result.theme).toBe('Light');
    });

    it('parses googlePay buttonType BOOK', () => {
      const dict = { googlePay: { buttonType: 'BOOK' } };
      const result = getAppearanceObj(dict, rnKeys, 'rn');
      expect(result.googlePay.buttonType).toBe('BOOK');
    });

    it('parses googlePay buttonType BUY', () => {
      const dict = { googlePay: { buttonType: 'BUY' } };
      const result = getAppearanceObj(dict, rnKeys, 'rn');
      expect(result.googlePay.buttonType).toBe('BUY');
    });

    it('parses googlePay buttonType CHECKOUT', () => {
      const dict = { googlePay: { buttonType: 'CHECKOUT' } };
      const result = getAppearanceObj(dict, rnKeys, 'rn');
      expect(result.googlePay.buttonType).toBe('CHECKOUT');
    });

    it('parses googlePay buttonType DONATE', () => {
      const dict = { googlePay: { buttonType: 'DONATE' } };
      const result = getAppearanceObj(dict, rnKeys, 'rn');
      expect(result.googlePay.buttonType).toBe('DONATE');
    });

    it('parses googlePay buttonType ORDER', () => {
      const dict = { googlePay: { buttonType: 'ORDER' } };
      const result = getAppearanceObj(dict, rnKeys, 'rn');
      expect(result.googlePay.buttonType).toBe('ORDER');
    });

    it('parses googlePay buttonType PAY', () => {
      const dict = { googlePay: { buttonType: 'PAY' } };
      const result = getAppearanceObj(dict, rnKeys, 'rn');
      expect(result.googlePay.buttonType).toBe('PAY');
    });

    it('parses googlePay buttonType SUBSCRIBE', () => {
      const dict = { googlePay: { buttonType: 'SUBSCRIBE' } };
      const result = getAppearanceObj(dict, rnKeys, 'rn');
      expect(result.googlePay.buttonType).toBe('SUBSCRIBE');
    });

    it('defaults googlePay buttonType to PLAIN for unknown', () => {
      const dict = { googlePay: { buttonType: 'UNKNOWN' } };
      const result = getAppearanceObj(dict, rnKeys, 'rn');
      expect(result.googlePay.buttonType).toBe('PLAIN');
    });

    it('parses applePay buttonType book', () => {
      const dict = { applePay: { buttonType: 'book' } };
      const result = getAppearanceObj(dict, rnKeys, 'rn');
      expect(result.applePay.buttonType).toBe('book');
    });

    it('parses applePay buttonType buy', () => {
      const dict = { applePay: { buttonType: 'buy' } };
      const result = getAppearanceObj(dict, rnKeys, 'rn');
      expect(result.applePay.buttonType).toBe('buy');
    });

    it('parses applePay buttonType checkout', () => {
      const dict = { applePay: { buttonType: 'checkout' } };
      const result = getAppearanceObj(dict, rnKeys, 'rn');
      expect(result.applePay.buttonType).toBe('checkout');
    });

    it('parses applePay buttonType donate', () => {
      const dict = { applePay: { buttonType: 'donate' } };
      const result = getAppearanceObj(dict, rnKeys, 'rn');
      expect(result.applePay.buttonType).toBe('donate');
    });

    it('parses applePay buttonType inStore', () => {
      const dict = { applePay: { buttonType: 'inStore' } };
      const result = getAppearanceObj(dict, rnKeys, 'rn');
      expect(result.applePay.buttonType).toBe('inStore');
    });

    it('parses applePay buttonType setUp', () => {
      const dict = { applePay: { buttonType: 'setUp' } };
      const result = getAppearanceObj(dict, rnKeys, 'rn');
      expect(result.applePay.buttonType).toBe('setUp');
    });

    it('parses applePay buttonType subscribe', () => {
      const dict = { applePay: { buttonType: 'subscribe' } };
      const result = getAppearanceObj(dict, rnKeys, 'rn');
      expect(result.applePay.buttonType).toBe('subscribe');
    });

    it('defaults applePay buttonType to plain for unknown', () => {
      const dict = { applePay: { buttonType: 'UNKNOWN' } };
      const result = getAppearanceObj(dict, rnKeys, 'rn');
      expect(result.applePay.buttonType).toBe('plain');
    });

    it('parses colors with light/dark variants for rn', () => {
      const dict = {
        colors: {
          light: { primary: '#FF0000' },
          dark: { primary: '#00FF00' },
        },
      };
      const result = getAppearanceObj(dict, rnKeys, 'rn');
      expect(result.colors.TAG).toBe('DefaultColors');
    });

    it('parses colors without light/dark variants for rn', () => {
      const dict = {
        colors: { primary: '#FF0000' },
      };
      const result = getAppearanceObj(dict, rnKeys, 'rn');
      expect(result.colors.TAG).toBe('Colors');
    });

    it('parses shapes with borderRadius', () => {
      const dict = { shapes: { borderRadius: 8 } };
      const result = getAppearanceObj(dict, rnKeys, 'rn');
      expect(result.shapes.borderRadius).toBe(8);
    });

    it('parses font settings', () => {
      const dict = { font: { sizeScaleFactor: 1.2 } };
      const result = getAppearanceObj(dict, rnKeys, 'rn');
      expect(result.font.scale).toBe(1.2);
    });

    it('handles from=flutter', () => {
      const result = getAppearanceObj({}, rnKeys, 'flutter');
      expect(result.theme).toBe('Default');
    });

    it('handles from=native with empty colors key', () => {
      const keysWithEmptyColors = { ...rnKeys, colors: '', light: 'light', dark: 'dark' };
      const dict = {
        light: { primary: '#FF0000' },
        dark: { primary: '#00FF00' },
      };
      const result = getAppearanceObj(dict, keysWithEmptyColors, 'native');
      expect(result.colors.TAG).toBe('DefaultColors');
    });

    it('handles from=native with non-empty colors key', () => {
      const dict = {
        colors: { primary: '#FF0000' },
      };
      const result = getAppearanceObj(dict, rnKeys, 'native');
      expect(result.colors.TAG).toBe('Colors');
    });

    it('parses googlePay buttonStyle with light=light', () => {
      const dict = {
        googlePay: {
          buttonType: 'BUY',
          buttonStyle: { light: 'light', dark: 'dark' },
        },
      };
      const result = getAppearanceObj(dict, rnKeys, 'rn');
      expect(result.googlePay.buttonStyle).toEqual({ light: 'light', dark: 'dark' });
    });

    it('parses googlePay buttonStyle with defaults for unknown values', () => {
      const dict = {
        googlePay: {
          buttonType: 'BUY',
          buttonStyle: { light: 'unknown', dark: 'unknown' },
        },
      };
      const result = getAppearanceObj(dict, rnKeys, 'rn');
      expect(result.googlePay.buttonStyle).toEqual({ light: 'dark', dark: 'light' });
    });

    it('parses applePay buttonStyle with light=white', () => {
      const dict = {
        applePay: {
          buttonType: 'buy',
          buttonStyle: { light: 'white', dark: 'black' },
        },
      };
      const result = getAppearanceObj(dict, rnKeys, 'rn');
      expect(result.applePay.buttonStyle).toEqual({ light: 'white', dark: 'black' });
    });

    it('parses applePay buttonStyle with light=whiteOutline', () => {
      const dict = {
        applePay: {
          buttonType: 'buy',
          buttonStyle: { light: 'whiteOutline', dark: 'whiteOutline' },
        },
      };
      const result = getAppearanceObj(dict, rnKeys, 'rn');
      expect(result.applePay.buttonStyle).toEqual({ light: 'whiteOutline', dark: 'whiteOutline' });
    });

    it('parses applePay buttonStyle with defaults for unknown values', () => {
      const dict = {
        applePay: {
          buttonType: 'buy',
          buttonStyle: { light: 'unknown', dark: 'unknown' },
        },
      };
      const result = getAppearanceObj(dict, rnKeys, 'rn');
      expect(result.applePay.buttonStyle).toEqual({ light: 'black', dark: 'white' });
    });

    it('parses primaryButton with light/dark color variants for rn', () => {
      const dict = {
        primaryButton: {
          colors: {
            light: { background: '#FFFFFF', text: '#000000', border: '#CCCCCC' },
            dark: { background: '#000000', text: '#FFFFFF', border: '#333333' },
          },
        },
      };
      const result = getAppearanceObj(dict, rnKeys, 'rn');
      expect(result.primaryButton.primaryButtonColor.TAG).toBe('PrimaryButtonDefault');
    });

    it('parses primaryButton without light/dark color variants for rn', () => {
      const dict = {
        primaryButton: {
          colors: { background: '#FFFFFF', text: '#000000', border: '#CCCCCC' },
        },
      };
      const result = getAppearanceObj(dict, rnKeys, 'rn');
      expect(result.primaryButton.primaryButtonColor.TAG).toBe('PrimaryButtonColor');
    });

    it('handles from=native with primaryButton_color non-empty', () => {
      const keysWithPrimaryButtonColor = { ...rnKeys, primaryButton_color: 'color', primaryButton_light: 'colorsLight', primaryButton_dark: 'colorsDark' };
      const dict = {
        primaryButton: {
          colorsLight: { background: '#FFFFFF' },
          colorsDark: { background: '#000000' },
        },
      };
      const result = getAppearanceObj(dict, keysWithPrimaryButtonColor, 'native');
      expect(result.primaryButton.primaryButtonColor.TAG).toBe('PrimaryButtonDefault');
    });

    it('handles from=native with empty primaryButton_color', () => {
      const keysWithEmptyPrimaryButtonColor = { ...rnKeys, primaryButton_color: '' };
      const dict = {
        primaryButton: {
          background: '#FFFFFF',
          text: '#000000',
          border: '#CCCCCC',
        },
      };
      const result = getAppearanceObj(dict, keysWithEmptyPrimaryButtonColor, 'native');
      expect(result.primaryButton.primaryButtonColor.TAG).toBe('PrimaryButtonColor');
    });
  });

  describe('getPrimaryColor', () => {
    it('returns primary from Colors type', () => {
      const colors = { TAG: 'Colors', _0: { primary: '#FF0000' } };
      expect(getPrimaryColor(colors)).toBe('#FF0000');
    });

    it('returns light primary from DefaultColors for Light theme', () => {
      const colors = {
        TAG: 'DefaultColors',
        _0: {
          light: { primary: '#FFFFFF' },
          dark: { primary: '#000000' },
        },
      };
      expect(getPrimaryColor(colors, 'Light')).toBe('#FFFFFF');
    });

    it('returns dark primary from DefaultColors for Dark theme', () => {
      const colors = {
        TAG: 'DefaultColors',
        _0: {
          light: { primary: '#FFFFFF' },
          dark: { primary: '#000000' },
        },
      };
      expect(getPrimaryColor(colors, 'Dark')).toBe('#000000');
    });

    it('returns light primary from DefaultColors for Default theme', () => {
      const colors = {
        TAG: 'DefaultColors',
        _0: {
          light: { primary: '#FFFFFF' },
          dark: { primary: '#000000' },
        },
      };
      expect(getPrimaryColor(colors, 'Default')).toBe('#FFFFFF');
    });

    it('returns undefined when primary is undefined in Colors', () => {
      const colors = { TAG: 'Colors', _0: { primary: undefined } };
      expect(getPrimaryColor(colors)).toBeUndefined();
    });

    it('returns undefined when light/dark primary is undefined', () => {
      const colors = {
        TAG: 'DefaultColors',
        _0: {
          light: { primary: undefined },
          dark: { primary: undefined },
        },
      };
      expect(getPrimaryColor(colors, 'Light')).toBeUndefined();
      expect(getPrimaryColor(colors, 'Dark')).toBeUndefined();
    });
  });

  describe('parseConfigurationDict', () => {
    it('returns default configuration for empty dict', () => {
      const result = parseConfigurationDict({}, 'rn');
      expect(result.allowsDelayedPaymentMethods).toBe(false);
      expect(result.displaySavedPaymentMethods).toBe(true);
      expect(result.displaySavedPaymentMethodsCheckbox).toBe(true);
      expect(result.displayDefaultSavedPaymentIcon).toBe(true);
      expect(result.enablePartialLoading).toBe(false);
      expect(result.displayMergedSavedMethods).toBe(false);
      expect(result.disableBranding).toBe(false);
    });

    it('parses allowsDelayedPaymentMethods', () => {
      const dict = { allowsDelayedPaymentMethods: true };
      const result = parseConfigurationDict(dict, 'rn');
      expect(result.allowsDelayedPaymentMethods).toBe(true);
    });

    it('parses allowsPaymentMethodsRequiringShippingAddress', () => {
      const dict = { allowsPaymentMethodsRequiringShippingAddress: true };
      const result = parseConfigurationDict(dict, 'rn');
      expect(result.allowsPaymentMethodsRequiringShippingAddress).toBe(true);
    });

    it('parses merchantDisplayName', () => {
      const dict = { merchantDisplayName: 'Test Merchant' };
      const result = parseConfigurationDict(dict, 'rn');
      expect(result.merchantDisplayName).toBe('Test Merchant');
    });

    it('parses primaryButtonLabel', () => {
      const dict = { primaryButtonLabel: 'Pay Now' };
      const result = parseConfigurationDict(dict, 'rn');
      expect(result.primaryButtonLabel).toBe('Pay Now');
    });

    it('parses paymentSheetHeaderText', () => {
      const dict = { paymentSheetHeaderLabel: 'Payment' };
      const result = parseConfigurationDict(dict, 'rn');
      expect(result.paymentSheetHeaderText).toBe('Payment');
    });

    it('parses savedPaymentScreenHeaderText', () => {
      const dict = { savedPaymentSheetHeaderLabel: 'Saved Cards' };
      const result = parseConfigurationDict(dict, 'rn');
      expect(result.savedPaymentScreenHeaderText).toBe('Saved Cards');
    });

    it('parses defaultBillingDetails', () => {
      const dict = {
        defaultBillingDetails: {
          name: 'John Doe',
          address: {
            city: 'New York',
            country: 'US',
            line1: '123 Main St',
            line2: 'Apt 4',
            postalCode: '10001',
            state: 'NY',
          },
          phoneNumber: '1234567890',
        },
      };
      const result = parseConfigurationDict(dict, 'rn');
      expect(result.defaultBillingDetails).toBeDefined();
    });

    it('parses shippingDetails', () => {
      const dict = {
        shippingDetails: {
          name: 'Jane Doe',
          address: {
            city: 'Boston',
            country: 'US',
            line1: '456 Oak Ave',
            postalCode: '02101',
            state: 'MA',
          },
          phoneNumber: '0987654321',
        },
      };
      const result = parseConfigurationDict(dict, 'rn');
      expect(result.shippingDetails).toBeDefined();
    });

    it('parses placeholder config', () => {
      const dict = {
        placeholder: {
          cardNumber: '0000 0000 0000 0000',
          expiryDate: 'MM/YY',
          cvv: 'CVV',
        },
      };
      const result = parseConfigurationDict(dict, 'rn');
      expect(result.placeholder.cardNumber).toBe('0000 0000 0000 0000');
      expect(result.placeholder.expiryDate).toBe('MM/YY');
      expect(result.placeholder.cvv).toBe('CVV');
    });

    it('parses defaultView', () => {
      const dict = { defaultView: true };
      const result = parseConfigurationDict(dict, 'rn');
      expect(result.defaultView).toBe(true);
    });

    it('parses netceteraSDKApiKey', () => {
      const dict = { netceteraSDKApiKey: 'test-api-key' };
      const result = parseConfigurationDict(dict, 'rn');
      expect(result.netceteraSDKApiKey).toBe('test-api-key');
    });

    it('parses primaryButtonColor', () => {
      const dict = { primaryButtonColor: '#FF0000' };
      const result = parseConfigurationDict(dict, 'rn');
      expect(result.primaryButtonColor).toBe('#FF0000');
    });

    it('parses displaySavedPaymentMethodsCheckbox', () => {
      const dict = { displaySavedPaymentMethodsCheckbox: false };
      const result = parseConfigurationDict(dict, 'rn');
      expect(result.displaySavedPaymentMethodsCheckbox).toBe(false);
    });

    it('parses displaySavedPaymentMethods', () => {
      const dict = { displaySavedPaymentMethods: false };
      const result = parseConfigurationDict(dict, 'rn');
      expect(result.displaySavedPaymentMethods).toBe(false);
    });

    it('parses displayDefaultSavedPaymentIcon', () => {
      const dict = { displayDefaultSavedPaymentIcon: false };
      const result = parseConfigurationDict(dict, 'rn');
      expect(result.displayDefaultSavedPaymentIcon).toBe(false);
    });

    it('parses enablePartialLoading', () => {
      const dict = { enablePartialLoading: true };
      const result = parseConfigurationDict(dict, 'rn');
      expect(result.enablePartialLoading).toBe(true);
    });

    it('parses displayMergedSavedMethods', () => {
      const dict = { displayMergedSavedMethods: true };
      const result = parseConfigurationDict(dict, 'rn');
      expect(result.displayMergedSavedMethods).toBe(true);
    });

    it('parses disableBranding', () => {
      const dict = { disableBranding: true };
      const result = parseConfigurationDict(dict, 'rn');
      expect(result.disableBranding).toBe(true);
    });

    it('handles default name in billingDetails', () => {
      const dict = {
        defaultBillingDetails: {
          name: 'default',
        },
      };
      const result = parseConfigurationDict(dict, 'rn');
      expect(result.defaultBillingDetails).toBeUndefined();
    });

    it('handles shippingDetails without address', () => {
      const dict = {
        shippingDetails: {
          name: 'Jane Doe',
        },
      };
      const result = parseConfigurationDict(dict, 'rn');
      expect(result.shippingDetails).toBeUndefined();
    });
  });

  describe('nativeJsonToRecord', () => {
    it('parses minimal valid JSON', () => {
      const json = { publishableKey: 'pk_snd_test' };
      const result = nativeJsonToRecord(json, 1);
      expect(result.publishableKey).toBe('pk_snd_test');
      expect(result.env).toBe('SANDBOX');
      expect(result.from).toBe('native');
      expect(result.sessionId).toBe('');
    });

    it('parses production publishableKey', () => {
      const json = { publishableKey: 'pk_prd_test' };
      const result = nativeJsonToRecord(json, 1);
      expect(result.env).toBe('PROD');
    });

    it('parses clientSecret', () => {
      const json = {
        publishableKey: 'pk_snd_test',
        clientSecret: 'cs_test_secret_123',
      };
      const result = nativeJsonToRecord(json, 1);
      expect(result.clientSecret).toBe('cs_test_secret_123');
      expect(result.paymentMethodId).toBe('cs_test');
    });

    it('parses ephemeralKey', () => {
      const json = {
        publishableKey: 'pk_snd_test',
        ephemeralKey: 'ek_test',
      };
      const result = nativeJsonToRecord(json, 1);
      expect(result.ephemeralKey).toBe('ek_test');
    });

    it('parses customBackendUrl', () => {
      const json = {
        publishableKey: 'pk_snd_test',
        customBackendUrl: 'https://api.example.com',
      };
      const result = nativeJsonToRecord(json, 1);
      expect(result.customBackendUrl).toBe('https://api.example.com');
    });

    it('parses customLogUrl', () => {
      const json = {
        publishableKey: 'pk_snd_test',
        customLogUrl: 'https://logs.example.com',
      };
      const result = nativeJsonToRecord(json, 1);
      expect(result.customLogUrl).toBe('https://logs.example.com');
    });

    it('parses from field', () => {
      const json = {
        publishableKey: 'pk_snd_test',
        from: 'flutter',
      };
      const result = nativeJsonToRecord(json, 1);
      expect(result.from).toBe('flutter');
    });

    it('parses type=payment as PaymentSheet', () => {
      const json = { publishableKey: 'pk_snd_test', type: 'payment' };
      const result = nativeJsonToRecord(json, 1);
      expect(result.sdkState).toBe('PaymentSheet');
    });

    it('parses type=buttonSheet as ButtonSheet', () => {
      const json = { publishableKey: 'pk_snd_test', type: 'buttonSheet' };
      const result = nativeJsonToRecord(json, 1);
      expect(result.sdkState).toBe('ButtonSheet');
    });

    it('parses type=tabSheet as TabSheet', () => {
      const json = { publishableKey: 'pk_snd_test', type: 'tabSheet' };
      const result = nativeJsonToRecord(json, 1);
      expect(result.sdkState).toBe('TabSheet');
    });

    it('parses type=google_pay as CustomWidget GOOGLE_PAY', () => {
      const json = { publishableKey: 'pk_snd_test', type: 'google_pay' };
      const result = nativeJsonToRecord(json, 1);
      expect(result.sdkState).toEqual({ TAG: 'CustomWidget', _0: 'GOOGLE_PAY' });
    });

    it('parses type=paypal as CustomWidget PAYPAL', () => {
      const json = { publishableKey: 'pk_snd_test', type: 'paypal' };
      const result = nativeJsonToRecord(json, 1);
      expect(result.sdkState).toEqual({ TAG: 'CustomWidget', _0: 'PAYPAL' });
    });

    it('parses type=headless as Headless', () => {
      const json = { publishableKey: 'pk_snd_test', type: 'headless' };
      const result = nativeJsonToRecord(json, 1);
      expect(result.sdkState).toBe('Headless');
    });

    it('parses type=card as CardWidget', () => {
      const json = { publishableKey: 'pk_snd_test', type: 'card' };
      const result = nativeJsonToRecord(json, 1);
      expect(result.sdkState).toBe('CardWidget');
    });

    it('parses type=hostedCheckout as HostedCheckout', () => {
      const json = { publishableKey: 'pk_snd_test', type: 'hostedCheckout' };
      const result = nativeJsonToRecord(json, 1);
      expect(result.sdkState).toBe('HostedCheckout');
    });

    it('parses type=expressCheckout as ExpressCheckoutWidget', () => {
      const json = { publishableKey: 'pk_snd_test', type: 'expressCheckout' };
      const result = nativeJsonToRecord(json, 1);
      expect(result.sdkState).toBe('ExpressCheckoutWidget');
    });

    it('parses type=paymentMethodsManagement', () => {
      const json = { publishableKey: 'pk_snd_test', type: 'paymentMethodsManagement' };
      const result = nativeJsonToRecord(json, 1);
      expect(result.sdkState).toBe('PaymentMethodsManagement');
    });

    it('parses type=widgetPaymentSheet', () => {
      const json = { publishableKey: 'pk_snd_test', type: 'widgetPaymentSheet' };
      const result = nativeJsonToRecord(json, 1);
      expect(result.sdkState).toBe('WidgetPaymentSheet');
    });

    it('parses type=widgetButtonSheet', () => {
      const json = { publishableKey: 'pk_snd_test', type: 'widgetButtonSheet' };
      const result = nativeJsonToRecord(json, 1);
      expect(result.sdkState).toBe('WidgetButtonSheet');
    });

    it('parses type=widgetTabSheet', () => {
      const json = { publishableKey: 'pk_snd_test', type: 'widgetTabSheet' };
      const result = nativeJsonToRecord(json, 1);
      expect(result.sdkState).toBe('WidgetTabSheet');
    });

    it('parses unknown type as NoView', () => {
      const json = { publishableKey: 'pk_snd_test', type: 'unknown' };
      const result = nativeJsonToRecord(json, 1);
      expect(result.sdkState).toBe('NoView');
    });

    it('parses hyperParams', () => {
      const json = {
        publishableKey: 'pk_snd_test',
        hyperParams: {
          confirm: true,
          appId: 'test.app',
          country: 'US',
          userAgent: 'Mozilla/5.0',
          launchTime: 1234567890,
          sdkVersion: '1.0.0',
          device_model: 'iPhone',
          os_type: 'iOS',
          os_version: '15.0',
          deviceBrand: 'Apple',
          bottomInset: 34,
          topInset: 44,
          leftInset: 0,
          rightInset: 0,
        },
      };
      const result = nativeJsonToRecord(json, 1);
      expect(result.hyperParams.confirm).toBe(true);
      expect(result.hyperParams.appId).toBe('test.app');
      expect(result.hyperParams.country).toBe('US');
    });

    it('uses defaultCountry when country is empty', () => {
      const json = {
        publishableKey: 'pk_snd_test',
        hyperParams: { country: '' },
      };
      const result = nativeJsonToRecord(json, 1);
      expect(result.hyperParams.country).toBe(defaultCountry);
    });

    it('uses defaultCountry when country is undefined', () => {
      const json = {
        publishableKey: 'pk_snd_test',
        hyperParams: {},
      };
      const result = nativeJsonToRecord(json, 1);
      expect(result.hyperParams.country).toBe(defaultCountry);
    });

    it('parses rootTag', () => {
      const json = { publishableKey: 'pk_snd_test' };
      const result = nativeJsonToRecord(json, 42);
      expect(result.rootTag).toBe(42);
    });

    it('parses customParams', () => {
      const json = {
        publishableKey: 'pk_snd_test',
        customParams: { foo: 'bar', baz: 123 },
      };
      const result = nativeJsonToRecord(json, 1);
      expect(result.customParams).toEqual({ foo: 'bar', baz: 123 });
    });

    it('parses configuration', () => {
      const json = {
        publishableKey: 'pk_snd_test',
        configuration: {
          merchantDisplayName: 'Test Merchant',
          allowsDelayedPaymentMethods: true,
        },
      };
      const result = nativeJsonToRecord(json, 1);
      expect(result.configuration.merchantDisplayName).toBe('Test Merchant');
      expect(result.configuration.allowsDelayedPaymentMethods).toBe(true);
    });

    it('ignores empty customBackendUrl', () => {
      const json = {
        publishableKey: 'pk_snd_test',
        customBackendUrl: '',
      };
      const result = nativeJsonToRecord(json, 1);
      expect(result.customBackendUrl).toBeUndefined();
    });

    it('ignores empty customLogUrl', () => {
      const json = {
        publishableKey: 'pk_snd_test',
        customLogUrl: '',
      };
      const result = nativeJsonToRecord(json, 1);
      expect(result.customLogUrl).toBeUndefined();
    });
  });

  describe('defaultCountry', () => {
    it('is US', () => {
      expect(defaultCountry).toBe('US');
    });
  });
});
