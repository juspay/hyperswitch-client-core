open ReactNative
open Style

@react.component
let make = () => {
  let (confirmButtonDataRef, setConfirmButtonDataRef) = React.useState(_ => React.null)
  let setConfirmButtonDataRef = React.useCallback1(confirmButtonDataRef => {
    setConfirmButtonDataRef(_ => confirmButtonDataRef)
  }, [setConfirmButtonDataRef])

  let (allApiData, _) = React.useContext(AllApiDataContext.allApiDataContext)
  let (tabArr, elementArr) = PMListModifier.useSheetListModifier()

  <View style={s({maxWidth: 450.->dp, alignSelf: #center, width: 100.->pct})}>
    <Space height=20. />
    <WalletView elementArr />
    <CustomTabView
      hocComponentArr=tabArr loading={allApiData.sessions == Loading} setConfirmButtonDataRef
    />
    <Space />
    {confirmButtonDataRef}
  </View>
}
