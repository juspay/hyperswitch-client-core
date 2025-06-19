@react.component
let make = (~requiredFields) => {
  let (paymentScreenType, _) = React.useContext(PaymentScreenContext.paymentScreenTypeContext)

  <DynamicFields
    requiredFields={switch paymentScreenType {
    | WALLET_MISSING_FIELDS(requiredFields) => requiredFields
    | _ => requiredFields
    }}
    setIsAllDynamicFieldValid=DynamicFieldsTypes.defaultDynamicFieldsState.setIsAllDynamicFieldValid
    setDynamicFieldsJson=DynamicFieldsTypes.defaultDynamicFieldsState.setDynamicFieldsJson
    isSaveCardsFlow=DynamicFieldsTypes.defaultDynamicFieldsState.isSaveCardsFlow
    savedCardsData=DynamicFieldsTypes.defaultDynamicFieldsState.savedCardsData
    keyToTrigerButtonClickError=DynamicFieldsTypes.defaultDynamicFieldsState.keyToTrigerButtonClickError
    displayPreValueFields=DynamicFieldsTypes.defaultDynamicFieldsState.displayPreValueFields
    paymentMethodType=?DynamicFieldsTypes.defaultDynamicFieldsState.paymentMethodType
  />

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
