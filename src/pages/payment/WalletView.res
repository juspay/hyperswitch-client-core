open ReactNative
open Style

module WalletDisclaimer = {
  @react.component
  let make = () => {
    let localeObject = GetLocale.useGetLocalObj()
    <View>
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
    </View>
  }
}

@react.component
let make = (~loading=true, ~elementArr, ~showDisclaimer=false) => {
  let localeObject = GetLocale.useGetLocalObj()
  <View>
    {switch elementArr->Array.length {
    | 0 =>
      loading
        ? <View>
            <Space />
            <CustomLoader />
            <Space height=15. />
            <TextWithLine text=localeObject.orPayUsing />
          </View>
        : React.null
    | _ =>
      <View>
        <Space />
        {elementArr->React.array}
        {showDisclaimer ? <WalletDisclaimer /> : React.null}
        <Space height=15. />
        <TextWithLine text=localeObject.orPayUsing />
      </View>
    }}
  </View>
}
