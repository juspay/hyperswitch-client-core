open ReactNative
open Style

module WalletDisclaimer = {
  @react.component
  let make = () => {
    let localeObject = GetLocale.useGetLocalObj()
    <>
      <Space height=10. />
      <View
        style={s({
          display: #flex,
          justifyContent: #center,
          alignContent: #center,
          flexDirection: #row,
          alignItems: #center,
        })}>
        <Icon name="lock" fill="#767676" style={s({marginEnd: 5.->dp})} />
        <TextWrapper text={localeObject.walletDisclaimer} textType={ModalText} />
      </View>
    </>
  }
}

@react.component
let make = (~isLoading=true, ~elementArr, ~showDisclaimer=false, ~hideDivider=false) => {
  let localeObject = GetLocale.useGetLocalObj()
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  <>
    {switch elementArr->Array.length {
    | 0 => React.null
    | _ =>
      <>
        <Space />
        {elementArr->React.array}
        /* The wallet message replaces the disclaimer, or hides it. */
        <UIUtils.RenderIf condition={showDisclaimer}>
          {switch PaymentMessageUtils.resolve(
            nativeProp.configuration.paymentMethodsConfig,
            ~paymentMethod="wallet",
            ~paymentMethodType="",
          ) {
          | Some((message, _)) =>
            switch PaymentMessageUtils.displayModeOf(message) {
            | #hidden => React.null
            | #custom_message =>
              /* An empty custom message still hides the disclaimer, without leaving a gap. */
              <UIUtils.RenderIf
                condition={PaymentMethodMessage.customContent(
                  nativeProp.configuration.paymentMethodsConfig,
                  ~paymentMethod="wallet",
                  ~paymentMethodType="",
                )->Option.isSome}>
                <Space height=10. />
                <PaymentMethodMessage paymentMethod="wallet" paymentMethodType="" />
              </UIUtils.RenderIf>
            | #default_sdk_message => <WalletDisclaimer />
            }
          | None => <WalletDisclaimer />
          }}
        </UIUtils.RenderIf>
        <UIUtils.RenderIf condition={!hideDivider}>
          <Space height=15. />
          <TextWithLine
            text={nativeProp.configuration.paymentMethodLayout.separatorText->Option.getOr(
              localeObject.orPayUsing,
            )}
            isLoading
          />
          <Space height=5. />
        </UIUtils.RenderIf>
      </>
    }}
  </>
}
