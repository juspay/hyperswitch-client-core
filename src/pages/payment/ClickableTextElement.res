open ReactNative
open Style

@react.component
let make = (
  ~initialIconName,
  ~updateIconName=None,
  ~text,
  ~isSelected,
  ~setIsSelected,
  ~textType,
  ~fillIcon=true,
  ~disabled=false,
  ~disableScreenSwitch=false,
) => {
  let (isSavedCardScreen, setSaveCardScreen) = React.useContext(
    PaymentScreenContext.paymentScreenTypeContext,
  )
  <CustomTouchableOpacity
    disabled
    activeOpacity=1.
    style={viewStyle(~flexDirection=#row, ~alignItems=#center, ())}
    onPress={_ => {
      !disableScreenSwitch
        ? {
            let newSheetType = switch isSavedCardScreen {
            | PAYMENTSHEET => PaymentScreenContext.SAVEDCARDSCREEN
            | SAVEDCARDSCREEN => PaymentScreenContext.PAYMENTSHEET
            }
            setSaveCardScreen(newSheetType)
          }
        : setIsSelected(_ => !isSelected)
    }}>
    <CustomSelectBox initialIconName updateIconName isSelected fillIcon />
    <Space width=6. height=0. />
    <TextWrapper text textType />
  </CustomTouchableOpacity>
}
