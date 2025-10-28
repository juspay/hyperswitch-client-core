open ReactNative
open Style

@react.component
let make = () => {
  let (confirmButtonData, setConfirmButtonData) = React.useState(_ =>
    GlobalConfirmButton.defaultConfirmButtonData
  )
  let setConfirmButtonData = React.useCallback1(confirmButtonData => {
    setConfirmButtonData(_ => confirmButtonData)
  }, [setConfirmButtonData])

  let (tabArr, elementArr) = AllApiDataModifier.useAccountPaymentMethodModifier(
    ~isClickToPayNewUser=false,
  )

  <View style={s({maxWidth: 450.->dp, alignSelf: #center, width: 100.->pct})}>
    <Space height=20. />
    <WalletView elementArr hideDivider={tabArr->Array.length === 0} />
    <CustomTabView hocComponentArr=tabArr isLoading={false} setConfirmButtonData />
    <Space />
    <GlobalConfirmButton confirmButtonData />
  </View>
}
