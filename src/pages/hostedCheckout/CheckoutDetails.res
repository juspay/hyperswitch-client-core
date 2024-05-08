open ReactNative
open Style
@react.component
let make = (~toggleModal) => {
  let isMobileView = WindowDimension.useIsMobileView()

  <View style={viewStyle(~alignItems={isMobileView ? #center : #"flex-start"}, ())}>
    {isMobileView
      ? <ReImage
          style={viewStyle(~width=120.->dp, ~height=120.->dp, ~borderRadius=8., ())}
          uri="https://stripe-camo.global.ssl.fastly.net/c25a949b6f1ffabee9af1a5696d7f152325bdce2d1b926456d42994c3d91ad78/68747470733a2f2f66696c65732e7374726970652e636f6d2f6c696e6b732f666c5f746573745f67625631776635726a4c64725a635858647032346d643649"
        />
      : <Space height=25. />}
    <Space />
    <TextWrapper text="Pay Powdur" textType=TextWrapper.ModalTextBold />
    <Space />
    <TextWrapper text="US$129.00" textType=TextWrapper.SubheadingBold />
    <Space />
    {isMobileView
      ? <TouchableOpacity
          onPress={_ => {toggleModal()}}
          style={viewStyle(
            ~backgroundColor="hsla(0,0%, 10% , 0.05 )",
            ~padding=13.->dp,
            ~flexDirection=#row,
            ~alignItems=#center,
            ~justifyContent=#center,
            ~borderRadius=5.,
            (),
          )}>
          <TextWrapper text="View Details" textType=TextWrapper.LinkText />
          <Space width=8. />
          <Icon
            style={viewStyle(~transform=[rotate(~rotate=270.->deg)], ())}
            name="back"
            height=14.
            width=14.
            fill="black"
          />
        </TouchableOpacity>
      : React.null}
  </View>
}
