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
let make = (~loading=true, ~elementArr, ~showDisclaimer=false, ~hideDivider=false) => {
  let localeObject = GetLocale.useGetLocalObj()
  <>
    {switch elementArr->Array.length {
    | 0 =>
      loading
        ? <>
            <Space />
            <CustomLoader />
            <Space height=15. />
            <TextWithLine text=localeObject.orPayUsing />
          </>
        : React.null
    | _ =>
      <>
        <Space />
        {elementArr->React.array}
        <UIUtils.RenderIf condition={showDisclaimer}>
          <WalletDisclaimer />
        </UIUtils.RenderIf>
        <UIUtils.RenderIf condition={!hideDivider}>
          <Space height=15. />
          <TextWithLine text=localeObject.orPayUsing />
        </UIUtils.RenderIf>
      </>
    }}
  </>
}
