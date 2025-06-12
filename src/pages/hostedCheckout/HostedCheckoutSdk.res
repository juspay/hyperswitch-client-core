open ReactNative
open Style

@react.component
let make = () => {
  let (confirmButtonDataRef, setConfirmButtonDataRef) = React.useState(_ => React.null)
  let setConfirmButtonDataRef = React.useCallback1(confirmButtonDataRef => {
    setConfirmButtonDataRef(_ => confirmButtonDataRef)
  }, [setConfirmButtonDataRef])
  
  let (dynamicFieldsState, setDynamicFieldsState) = React.useState(_ => DynamicFieldsTypes.defaultDynamicFieldsState) 
  let (allApiData, _) = React.useContext(AllApiDataContext.allApiDataContext)
  let {tabArr, elementArr} = PMListModifier.useListModifier()
  let (indexInFocus, setIndexInFocus) = React.useState(_ => 0)

  <View style={viewStyle(~maxWidth=450.->dp, ~alignSelf=#center, ~width=100.->pct, ())}>
    <Space height=20. />
    <WalletView elementArr />
    <CustomTabView
      hocComponentArr=tabArr loading={allApiData.sessions == Loading} setConfirmButtonDataRef setDynamicFieldsState
      indexInFocus setIndexInFocus
    />
    <Space />
    <GlobalDynamicFields dynamicFieldsState />
    {confirmButtonDataRef}
  </View>
}
