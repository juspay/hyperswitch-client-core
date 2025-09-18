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
let make = (~loading=true, ~elementArr, ~showDisclaimer=false) => {
  <>
    {switch elementArr->Array.length {
    | 0 =>
      loading
        ? <>
            <Space />
            <CustomLoader />
          </>
        : React.null
    | _ =>
      <>
        <Space />
        {elementArr->React.array}
        {showDisclaimer ? <WalletDisclaimer /> : React.null}
      </>
    }}
  </>
}
