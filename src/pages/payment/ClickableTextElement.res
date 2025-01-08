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
    style={viewStyle(~flexDirection=#row, ~alignItems=#center, ~alignSelf=#"flex-start", ())}
    onPress={_ => {
      !disableScreenSwitch
        ? {
            let newSheetType = switch isSavedCardScreen {
            | PAYMENTSHEET => PaymentScreenContext.SAVEDCARDSCREEN
            | SAVEDCARDSCREEN => PaymentScreenContext.PAYMENTSHEET
            | _ => PaymentScreenContext.PAYMENTSHEET
            }
            setSaveCardScreen(newSheetType)
          }
        : setIsSelected(_ => !isSelected)
    }}>
    <CustomSelectBox initialIconName updateIconName isSelected fillIcon />
    <TextWrapper text textType overrideStyle=Some(viewStyle(~paddingHorizontal=6.->dp, ())) />
  </CustomTouchableOpacity>
}
