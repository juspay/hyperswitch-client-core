open ReactNative
open Style

module WalletDisclaimer = {
  @react.component
  let make = () => {
    <>
      <Space height=10. />
      <View
        style={viewStyle(
          ~display=#flex,
          ~justifyContent=#center,
          ~alignContent=#center,
          ~flexDirection=#row,
          ~alignItems=#center,
          (),
        )}>
        <Icon name="lock" />
        <TextWrapper text="Wallet details will be saved upon selection" textType={ModalText} />
      </View>
    </>
  }
}

@react.component
let make = (~loading=true, ~elementArr, ~showDisclaimer=false) => {
  let localeObject = GetLocale.useGetLocalObj()
  <View style={viewStyle(~marginHorizontal=18.->dp, ())}>
    {switch elementArr->Array.length {
    | 0 =>
      loading
        ? <>
            <Space />
            <CustomLoader />
            <Space height=20. />
            <TextWithLine text=localeObject.orPayUsing />
          </>
        : React.null
    | _ =>
      <>
        <Space />
        {elementArr->React.array}
        {showDisclaimer ? <WalletDisclaimer /> : React.null}
        <Space height=20. />
        <TextWithLine text=localeObject.orPayUsing />
      </>
    }}
  </View>
}
