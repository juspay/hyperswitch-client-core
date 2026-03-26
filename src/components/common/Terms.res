open ReactNative
open Style

type showTerms = Auto | Always | Never

@react.component
let make = (~paymentMethod, ~paymentMethodType) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let localeObj = GetLocale.useGetLocalObj()
  let (accountPaymentMethodData, _, _) = React.useContext(AllApiDataContextNew.allApiDataContext)
  let paymentType =
    accountPaymentMethodData
    ->Option.map(accountPaymentMethods => accountPaymentMethods.payment_type)
    ->Option.getOr(NORMAL)
  let merchantName =
    accountPaymentMethodData
    ->Option.map(data => data.merchant_name)
    ->Option.getOr(nativeProp.configuration.merchantDisplayName)
  let customConfig = CustomPaymentMethodsConfig.useCustomPaymentMethodConfigs(
    ~paymentMethod,
    ~paymentMethodType,
  )
  let {component} = ThemebasedStyle.useThemeBasedStyle()

  let customMessageConfig =
    customConfig
    ->Option.map(config => config.message)
    ->Option.getOr(SdkTypes.defaultPaymentMethodMessage)

  let cardTermsValue = localeObj.cardTermsPart1 ++ merchantName ++ localeObj.cardTermsPart2

  let paymentMethodTermsDefaults = switch paymentMethod {
  | "bank_debit" =>
    switch paymentMethodType {
    | "sepa" => (localeObj.sepaDebitTermsPart1 ++ localeObj.sepaDebitTermsPart2 ++ localeObj.sepaDebitTermsPart3, Auto)
    | "becs" => (localeObj.becsDebitTerms, Auto)
    | "ach" => (localeObj.achBankDebitTermsPart1 ++ merchantName ++ localeObj.achBankDebitTermsPart2, Auto)
    | _ => ("", Never)
    }
  | "card" =>
    switch paymentType {
    | NEW_MANDATE | SETUP_MANDATE => (cardTermsValue, Auto)
    | _ => ("", Never)
    }
  | _ => ("", Never)
  }

  let (termsText, showTerm) = switch customMessageConfig.displayMode {
  | DefaultSdkMessage => paymentMethodTermsDefaults
  | CustomMessage => {
      let customMessage = customMessageConfig.value->Option.getOr("")->String.trim
      (customMessage, customMessage->String.length > 0 ? Always : Never)
    }
  | Hidden => ("", Never)
  }

  <UIUtils.RenderIf condition={showTerm == Auto || showTerm == Always}>
    <Text
      style={s({
        color: component.color,
        fontSize: 12.,
        marginVertical: 8.->dp,
      })}>
      {React.string(termsText)}
    </Text>
  </UIUtils.RenderIf>
}
