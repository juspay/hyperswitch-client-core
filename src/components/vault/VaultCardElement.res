open ReactNative
open Style

external colorToString: Color.t => string = "%identity"

@react.component
let make = (
  ~session: option<JSON.t>,
  ~formRef: React.ref<Nullable.t<VaultCardForm.vaultFormHandle>>,
  ~enabledCardSchemes: array<string>=[],
  ~accessible=?,
  ~cardholderNameMode: VaultCardForm.cardholderNameMode=#omit,
) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let (clientData, _, _) = React.useContext(AllApiDataContextNew.allApiDataContext)
  let eligibilityRequired = VaultActivation.eligibilityRequired(clientData)
  let baseUrl = GlobalHooks.useGetBaseUrl()()
  let {
    component,
    dangerColor,
    placeholderColor,
    borderRadius,
    borderWidth,
    primaryColor,
    gap,
    fontScale,
    placeholderTextSizeAdjust,
    errorTextSizeAdjust,
    errorMessageSpacing,
    inputHeight,
  } = ThemebasedStyle.useThemeBasedStyle()
  let localeObject = GetLocale.useGetLocalObj()
  let fontFamily = FontFamily.useCustomFontFamily()

  let splitCardFields = nativeProp.configuration.splitCardFields

  let appearance: VaultCardForm.appearance = {
    primaryColor: primaryColor->colorToString,
    textColor: component.color->colorToString,
    errorColor: dangerColor,
    placeholderColor,
    backgroundColor: component.background->colorToString,
    borderColor: component.borderColor->colorToString,
    borderRadius,
    borderWidth,
    fontFamily,
    inputHeight,
    gap,
    fontScale,
    placeholderTextSizeAdjust,
    errorTextSizeAdjust,
    errorMessageSpacing,
  }

  let localisation: VaultCardForm.localisation = {
    validationMessages: {
      cardNumberRequired: localeObject.cardNumberEmptyText,
      cardNumberInvalid: localeObject.inValidCardErrorText,
      expiryRequired: localeObject.cardExpiryDateEmptyText,
      expiryInvalid: localeObject.inValidExpiryErrorText,
      cvcRequired: localeObject.cvcNumberEmptyText,
      cvcInvalid: localeObject.inValidCVCErrorText,
      unsupportedCard: localeObject.unsupportedCardErrorText,
      cardNotEligible: localeObject.cardNotEligibleText,
    },
    labels: {
      selectCardBrandLabel: localeObject.selectCardBrand,
    },
    isRtl: localeObject.localeDirection === "rtl",
  }

  let brandIconMode: VaultCardForm.brandIconMode = switch nativeProp.configuration.paymentMethodLayout.cardBrandIcon {
  | Hidden => #hidden
  | Animated => #animated
  | Standard => #standard
  | HideGeneric => #hideGeneric
  }

  let cvcIcon: VaultCardForm.cvcIconDisplay = switch nativeProp.configuration.paymentMethodLayout.cvcIcon {
  | Shown => #default
  | Hidden => #none
  }

  let fieldOptions: VaultCardForm.formFieldOptions = {
    cardNumber: {
      placeholder: nativeProp.configuration.placeholder.cardNumber->Option.getOr(
        localeObject.cardNumberLabel,
      ),
      label: localeObject.cardNumberLabel,
      labelBehavior: #floating,
      errorDisplay: #inline,
      testID: TestUtils.cardNumberInputTestId,
      brandIconMode,
    },
    expiry: {
      placeholder: nativeProp.configuration.placeholder.expiryDate->Option.getOr(
        localeObject.validThruText,
      ),
      label: localeObject.validThruText,
      labelBehavior: #floating,
      errorDisplay: #inline,
      testID: TestUtils.expiryInputTestId,
    },
    cvc: {
      placeholder: nativeProp.configuration.placeholder.cvv->Option.getOr(localeObject.cvcTextLabel),
      label: localeObject.cvcTextLabel,
      labelBehavior: #floating,
      errorDisplay: #inline,
      testID: TestUtils.cvcInputTestId,
      cvcIcon,
    },
  }

  let eligibility: option<VaultCardForm.eligibilityConfig> =
    eligibilityRequired
      ? Some({
          paymentId: nativeProp.paymentSessionConfig.paymentId,
          sdkAuthorization: nativeProp.paymentSessionConfig.sdkAuthorization->Option.getOr(""),
          appId: ?nativeProp.sdkParams.appId,
          endpoint: {baseUrl: baseUrl},
        })
      : None

  <View style={s({marginBottom: gap->dp})}>
    {React.createElement(
      VaultCardForm.make,
      {
        ref_: formRef,
        session: ?session,
        environment: switch nativeProp.hyperswitchConfig.environment {
        | SANDBOX => #sandbox
        | INTEG => #integration
        | PROD => #production
        },
        appearance,
        localisation,
        layout: #inline,
        fieldArrangement: splitCardFields ? #separate : #fused,
        fieldOptions,
        enabledCardSchemes,
        eligibility: ?eligibility,
        accessible: ?accessible,
        cardholderName: cardholderNameMode,
      },
    )}
  </View>
}
