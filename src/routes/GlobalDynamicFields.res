// open ReactNative
// open Style

@react.component
let make = (~dynamicFieldsDataRef: DynamicFieldsTypes.dynamicFieldsDataRef) => {
  let (paymentScreenType, _) = React.useContext(PaymentScreenContext.paymentScreenTypeContext)

  // dynamicFieldsDataRef.isVisible
  //   ?
  <DynamicFields
    requiredFields={switch paymentScreenType {
    | WALLET_MISSING_FIELDS(requiredFields) => requiredFields
    | _ => dynamicFieldsDataRef.requiredFields
    }}
    setIsAllDynamicFieldValid=dynamicFieldsDataRef.setIsAllDynamicFieldValid
    setDynamicFieldsJson=dynamicFieldsDataRef.setDynamicFieldsJson
    isSaveCardsFlow=dynamicFieldsDataRef.isSaveCardsFlow
    savedCardsData=dynamicFieldsDataRef.savedCardsData
    keyToTrigerButtonClickError=dynamicFieldsDataRef.keyToTrigerButtonClickError
    displayPreValueFields=dynamicFieldsDataRef.displayPreValueFields
    paymentMethodType=?dynamicFieldsDataRef.paymentMethodType
  />
  // : React.null

  // let {primaryColor, borderRadius} = ThemebasedStyle.useThemeBasedStyle()

  // <CustomTouchableOpacity
  //   activeOpacity=1.
  //   style={viewStyle(
  //     ~width=100.->pct,
  //     ~flexDirection=#row,
  //     ~alignItems=#center,
  //     ~alignSelf=#"flex-start",
  //     ~padding=12.->dp,
  //     ~marginTop=10.->dp,
  //     ~borderRadius,
  //     ~backgroundColor="white",
  //     ~gap=10.,
  //     (),
  //   )}>
  //   <Icon name="add" height=24. width=24. fill=primaryColor />
  //   <TextWrapper text="Add a new address" textType={CardText} />
  // </CustomTouchableOpacity>
}
