open ReactNative
open Style

@react.component
let make = () => {
  let (confirmButtonDataRef, setConfirmButtonDataRef) = React.useState(_ => React.null)
  let setConfirmButtonDataRef = React.useCallback1(confirmButtonDataRef => {
    setConfirmButtonDataRef(_ => confirmButtonDataRef)
  }, [setConfirmButtonDataRef])
  let {tabArr, elementArr} = PMListModifier.useListModifier()

  <View style={viewStyle(~maxWidth=450.->dp, ~alignSelf=#center, ~width=100.->pct, ())}>
    <Space height=20. />
    <WalletView elementArr />
    <CustomTabView hocComponentArr=tabArr setConfirmButtonDataRef />
    <Space />
    {confirmButtonDataRef}
  </View>
}
