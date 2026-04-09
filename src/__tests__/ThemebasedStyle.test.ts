import {
  getStrProp,
  getStyleProp,
  some,
  itemToObj,
  status_color,
  maxTextSize,
} from '../hooks/ThemebasedStyle.bs.js';

describe('ThemebasedStyle', () => {
  describe('getStrProp', () => {
    it('returns override prop when defined', () => {
      expect(getStrProp('override-value', 'default-value')).toBe('override-value');
    });

    it('returns default prop when override is undefined', () => {
      expect(getStrProp(undefined, 'default-value')).toBe('default-value');
    });

    it('handles empty string override', () => {
      expect(getStrProp('', 'default-value')).toBe('');
    });

    it('returns default for various falsy overrides', () => {
      expect(getStrProp(undefined, 'default')).toBe('default');
    });
  });

  describe('getStyleProp', () => {
    it('applies function to override when defined', () => {
      const fn = (val: string) => ({ color: val });
      const result = getStyleProp('red', fn, { color: 'blue' });
      expect(result).toEqual({ color: 'red' });
    });

    it('returns default when override is undefined', () => {
      const fn = (val: string) => ({ color: val });
      const result = getStyleProp(undefined, fn, { color: 'blue' });
      expect(result).toEqual({ color: 'blue' });
    });

    it('handles complex transform function', () => {
      const fn = (val: string) => ({ backgroundColor: val, padding: 10 });
      const result = getStyleProp('#ffffff', fn, { backgroundColor: '#000000', padding: 5 });
      expect(result).toEqual({ backgroundColor: '#ffffff', padding: 10 });
    });

    it('returns function result for empty string override', () => {
      const fn = (val: string) => ({ color: val });
      const result = getStyleProp('', fn, { color: 'blue' });
      expect(result).toEqual({ color: '' });
    });
  });

  describe('some', () => {
    it('applies function to override when defined', () => {
      const fn = (val: string) => val.toUpperCase();
      const result = some('hello', fn, 'default');
      expect(result).toBe('HELLO');
    });

    it('returns default when override is undefined', () => {
      const fn = (val: string) => val.toUpperCase();
      const result = some(undefined, fn, 'default');
      expect(result).toBe('default');
    });

    it('handles numeric transform', () => {
      const fn = (val: number) => val * 2;
      const result = some(5, fn, 0);
      expect(result).toBe(10);
    });

    it('returns function result for zero override', () => {
      const fn = (val: number) => val * 2;
      const result = some(0, fn, 100);
      expect(result).toBe(0);
    });
  });

  describe('status_color constant', () => {
    it('has green status color', () => {
      expect(status_color.green).toBeDefined();
      expect(status_color.green.textColor).toBe('#36AF47');
      expect(status_color.green.backgroundColor).toBe('rgba(54, 175, 71, 0.12)');
    });

    it('has orange status color', () => {
      expect(status_color.orange).toBeDefined();
      expect(status_color.orange.textColor).toBe('#CA8601');
      expect(status_color.orange.backgroundColor).toBe('rgba(202, 134, 1, 0.12)');
    });

    it('has red status color', () => {
      expect(status_color.red).toBeDefined();
      expect(status_color.red.textColor).toBe('#EF6969');
      expect(status_color.red.backgroundColor).toBe('rgba(239, 105, 105, 0.12)');
    });

    it('has blue status color', () => {
      expect(status_color.blue).toBeDefined();
      expect(status_color.blue.textColor).toBe('#0099FF');
      expect(status_color.blue.backgroundColor).toBe('rgba(0, 153, 255, 0.12)');
    });
  });

  describe('maxTextSize constant', () => {
    it('has correct max heading text size', () => {
      expect(maxTextSize.maxHeadingTextSize).toBe(10);
    });

    it('has correct max subheading text size', () => {
      expect(maxTextSize.maxSubHeadingTextSize).toBe(10);
    });

    it('has correct max placeholder text size', () => {
      expect(maxTextSize.maxPlaceholderTextSize).toBe(5);
    });

    it('has correct max button text size', () => {
      expect(maxTextSize.maxButtonTextSize).toBe(15);
    });

    it('has correct max error text size', () => {
      expect(maxTextSize.maxErrorTextSize).toBe(15);
    });

    it('has correct max link text size', () => {
      expect(maxTextSize.maxLinkTextSize).toBe(7);
    });

    it('has correct max modal text size', () => {
      expect(maxTextSize.maxModalTextSize).toBe(6);
    });

    it('has correct max card text size', () => {
      expect(maxTextSize.maxCardTextSize).toBe(7);
    });
  });

  describe('itemToObj', () => {
    // googlePay and applePay are accessed unconditionally in ThemebasedStyle.bs.js
    // (appearance.googlePay.buttonStyle / appearance.applePay.buttonStyle),
    // so every appearance object must include them.
    const requiredAppearanceDefaults = {
      googlePay: { buttonStyle: undefined },
      applePay: { buttonStyle: undefined },
    };

    const mockThemeObj = {
      platform: 'android',
      bgColor: { backgroundColor: '#ffffff' },
      paymentSheetOverlay: '#00000070',
      loadingBgColor: 'rgb(220,220,220)',
      loadingFgColor: 'rgb(250,250,250)',
      bgTransparentColor: { backgroundColor: 'rgba(0,0,0,0.2)' },
      textPrimary: { color: '#0570de' },
      textSecondary: { color: '#767676' },
      textSecondaryBold: { color: '#000000' },
      placeholderColor: '#00000070',
      textInputBg: { backgroundColor: '#ffffff' },
      iconColor: 'rgba(53, 64, 82, 0.25)',
      lineBorderColor: '#CCD2E250',
      linkColor: '#006DF9',
      disableBgColor: '#ECECEC',
      filterHeaderColor: '#666666',
      filterOptionTextColor: ['#354052', 'rgba(53, 64, 82, 0.8)'],
      tooltipTextColor: '#F6F8F975',
      tooltipBackgroundColor: '#191A1A',
      boxColor: { backgroundColor: '#FFFFFF' },
      boxBorderColor: { borderColor: '#e4e4e5' },
      dropDownSelectAll: [['#E7EAF1', '#E7EAF1', '#E7EAF1'], ['#F1F5FA', '#FDFEFF', '#F1F5FA']],
      fadedColor: ['#CCCFD450', 'rgba(53, 64, 82, 0.5)'],
      status_color: status_color,
      detailViewToolTipText: 'rgba(246, 248, 249, 0.75)',
      summarisedViewSingleStatHeading: '#354052',
      switchThumbColor: 'white',
      shimmerColor: ['#EAEBEE', '#FFFFFF'],
      lastOffset: '#FFFFFF',
      dangerColor: '#FF3434',
      orderDisableButton: '#354052',
      toastColorConfig: { textColor: '#F5F7FC', backgroundColor: '#2C2D2F' },
      primaryColor: '#006DF9',
      borderRadius: '7.0',
      borderWidth: '1',
      buttonBorderRadius: '8.0',
      buttonBorderWidth: '0.0',
      component: { background: '#FFFFFF', borderColor: 'rgb(226,226,228)', dividerColor: '#e6e6e6', color: '#000000' },
      locale: 'En',
      fontFamily: 'DefaultWeb',
      fontScale: 1,
      headingTextSizeAdjust: 0,
      subHeadingTextSizeAdjust: 0,
      placeholderTextSizeAdjust: 0,
      buttonTextSizeAdjust: 0,
      errorTextSizeAdjust: 0,
      linkTextSizeAdjust: 0,
      modalTextSizeAdjust: 0,
      cardTextSizeAdjust: 0,
      paypalButonColor: '#F6C657',
      samsungPayButtonColor: '#000000',
      applePayButtonColor: 'black',
      googlePayButtonColor: 'dark',
      payNowButtonColor: '#006DF9',
      payNowButtonTextColor: '#FFFFFF',
      payNowButtonBorderColor: '#ffffff',
      payNowButtonShadowColor: 'black',
      payNowButtonShadowIntensity: '2',
      focusedTextInputBoderColor: '#006DF9',
      errorTextInputColor: 'rgba(0, 153, 255, 1)',
      normalTextInputBoderColor: 'rgba(204, 210, 226, 0.75)',
      shadowColor: 'black',
      shadowIntensity: '2',
      primaryButtonHeight: 45,
      disclaimerBackgroundColor: '#FDF3E0',
      disclaimerTextColor: '#D57F0C',
      instructionalTextColor: '#999999',
      poweredByTextColor: '#111111',
      detailsViewTextKeyColor: '#999999',
      detailsViewTextValueColor: '#333333',
      silverBorderColor: '#CCCCCC',
      sheetContentPadding: 20,
      errorMessageSpacing: 4,
    };

    it('returns themeObj defaults for empty appearance', () => {
      const appearance = { ...requiredAppearanceDefaults };
      const result = itemToObj(mockThemeObj, appearance, false);
      expect(result.platform).toBe('android');
      expect(result.locale).toBe('En');
    });

    it('applies light mode colors from appearance', () => {
      const appearance = {
        ...requiredAppearanceDefaults,
        colors: {
          TAG: 'Colors',
          _0: {
            primary: '#123456',
            background: '#ffffff',
            primaryText: '#000000',
            secondaryText: '#666666',
          },
        },
      };
      const result = itemToObj(mockThemeObj, appearance, false);
      expect(result.primaryColor).toBe('#123456');
    });

    it('applies dark mode colors from appearance', () => {
      const appearance = {
        ...requiredAppearanceDefaults,
        colors: {
          TAG: 'AppearanceModeColors',
          _0: {
            light: { primary: '#lightcolor' },
            dark: { primary: '#darkcolor' },
          },
        },
      };
      const result = itemToObj(mockThemeObj, appearance, true);
      expect(result.primaryColor).toBe('#darkcolor');
    });

    it('applies light mode colors when isDarkMode is false', () => {
      const appearance = {
        ...requiredAppearanceDefaults,
        colors: {
          TAG: 'AppearanceModeColors',
          _0: {
            light: { primary: '#lightcolor' },
            dark: { primary: '#darkcolor' },
          },
        },
      };
      const result = itemToObj(mockThemeObj, appearance, false);
      expect(result.primaryColor).toBe('#lightcolor');
    });

    it('applies font settings from appearance', () => {
      const appearance = {
        ...requiredAppearanceDefaults,
        font: {
          family: 'CustomFont',
          scale: 1.5,
          headingTextSizeAdjust: 5,
          buttonTextSizeAdjust: 10,
        },
      };
      const result = itemToObj(mockThemeObj, appearance, false);
      expect(result.fontFamily).toBe('CustomFont');
      expect(result.fontScale).toBe(1.5);
      expect(result.headingTextSizeAdjust).toBe(5);
      expect(result.buttonTextSizeAdjust).toBe(10);
    });

    it('caps headingTextSizeAdjust at 10', () => {
      const appearance = {
        ...requiredAppearanceDefaults,
        font: {
          headingTextSizeAdjust: 15,
        },
      };
      const result = itemToObj(mockThemeObj, appearance, false);
      expect(result.headingTextSizeAdjust).toBe(10);
    });

    it('caps placeholderTextSizeAdjust at 5', () => {
      const appearance = {
        ...requiredAppearanceDefaults,
        font: {
          placeholderTextSizeAdjust: 10,
        },
      };
      const result = itemToObj(mockThemeObj, appearance, false);
      expect(result.placeholderTextSizeAdjust).toBe(5);
    });

    it('caps buttonTextSizeAdjust at 15', () => {
      const appearance = {
        ...requiredAppearanceDefaults,
        font: {
          buttonTextSizeAdjust: 20,
        },
      };
      const result = itemToObj(mockThemeObj, appearance, false);
      expect(result.buttonTextSizeAdjust).toBe(15);
    });

    it('applies primaryButton color from appearance', () => {
      const appearance = {
        ...requiredAppearanceDefaults,
        primaryButton: {
          primaryButtonColor: {
            TAG: 'PrimaryButtonColor',
            _0: {
              background: '#btnbg',
              text: '#btntext',
              border: '#btnborder',
            },
          },
        },
      };
      const result = itemToObj(mockThemeObj, appearance, false);
      expect(result.payNowButtonColor).toBe('#btnbg');
      expect(result.payNowButtonTextColor).toBe('#btntext');
      expect(result.payNowButtonBorderColor).toBe('#btnborder');
    });

    it('applies primaryButton color with dark mode', () => {
      const appearance = {
        ...requiredAppearanceDefaults,
        primaryButton: {
          primaryButtonColor: {
            TAG: 'PrimaryButtonColorMode',
            light: { background: '#lightbg' },
            dark: { background: '#darkbg' },
          },
        },
      };
      const result = itemToObj(mockThemeObj, appearance, true);
      expect(result.payNowButtonColor).toBe('#darkbg');
    });

    it('applies googlePay buttonStyle from appearance for dark mode', () => {
      const appearance = {
        applePay: { buttonStyle: undefined },
        googlePay: {
          buttonStyle: {
            dark: 'black',
            light: 'white',
          },
        },
      };
      const result = itemToObj(mockThemeObj, appearance, true);
      expect(result.googlePayButtonColor).toBe('black');
    });

    it('applies googlePay buttonStyle from appearance for light mode', () => {
      const appearance = {
        applePay: { buttonStyle: undefined },
        googlePay: {
          buttonStyle: {
            dark: 'black',
            light: 'white',
          },
        },
      };
      const result = itemToObj(mockThemeObj, appearance, false);
      expect(result.googlePayButtonColor).toBe('white');
    });

    it('applies applePay buttonStyle from appearance', () => {
      const appearance = {
        googlePay: { buttonStyle: undefined },
        applePay: {
          buttonStyle: {
            dark: 'black',
            light: 'white',
          },
        },
      };
      const result = itemToObj(mockThemeObj, appearance, true);
      expect(result.applePayButtonColor).toBe('black');
    });

    it('applies locale from appearance', () => {
      const appearance = {
        ...requiredAppearanceDefaults,
        locale: 'fr',
      };
      const result = itemToObj(mockThemeObj, appearance, false);
      expect(result.locale).toBe('fr');
    });

    it('applies shapes borderRadius from appearance', () => {
      const appearance = {
        ...requiredAppearanceDefaults,
        shapes: {
          borderRadius: '12',
          borderWidth: '2',
          shadow: {
            color: '#shadowcolor',
            intensity: '5',
          },
        },
      };
      const result = itemToObj(mockThemeObj, appearance, false);
      expect(result.borderRadius).toBe('12');
      expect(result.borderWidth).toBe('2');
      expect(result.shadowColor).toBe('#shadowcolor');
      expect(result.shadowIntensity).toBe('5');
    });

    it('applies component colors from appearance', () => {
      const appearance = {
        ...requiredAppearanceDefaults,
        colors: {
          TAG: 'Colors',
          _0: {
            componentBackground: '#compbg',
            componentBorder: '#compborder',
            componentDivider: '#compdivider',
            componentText: '#comptext',
          },
        },
      };
      const result = itemToObj(mockThemeObj, appearance, false);
      expect(result.component.background).toBe('#compbg');
      expect(result.component.borderColor).toBe('#compborder');
      expect(result.component.dividerColor).toBe('#compdivider');
      expect(result.component.color).toBe('#comptext');
    });

    it('applies error color from appearance', () => {
      const appearance = {
        ...requiredAppearanceDefaults,
        colors: {
          TAG: 'Colors',
          _0: {
            error: '#ff0000',
          },
        },
      };
      const result = itemToObj(mockThemeObj, appearance, false);
      expect(result.dangerColor).toBe('#ff0000');
    });
  });
});
