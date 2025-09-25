open ReactNative
open Style
@react.component
let make = (~toggleModal) => {
  let isMobileView = WindowDimension.useIsMobileView()

  <View style={s({alignItems: isMobileView ? #center : #"flex-start"})}>
    {isMobileView
      ? <ReImage style={s({width: 120.->dp, height: 120.->dp, borderRadius: 8.})} uri="" />
      : <Space height=25. />}
    <Space />
    <TextWrapper text="Pay Powdur" textType=TextWrapper.ModalTextBold />
    <Space />
    <TextWrapper text="US$129.00" textType=TextWrapper.SubheadingBold />
    <Space />
    {isMobileView
      ? <CustomPressable
          onPress={_ => {toggleModal()}}
          style={s({
            backgroundColor: "hsla(0,0%, 10% , 0.05 )",
            padding: 13.->dp,
            flexDirection: #row,
            alignItems: #center,
            justifyContent: #center,
            borderRadius: 5.,
          })}>
          <TextWrapper text="View Details" textType={LinkText} />
          <Space width=8. />
          <ChevronIcon width=14. height=14. fill="black" />
        </CustomPressable>
      : React.null}
  </View>
}
