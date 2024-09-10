open ReactNative
open Style
module TermsView = {
  @react.component
  let make = () => {
    <View style={viewStyle(~flexDirection=#row, ~width=100.->pct, ())}>
      <TextWrapper text="Powerd by Hyperswitch" textType={ModalText} />
      <Space />
      <TextWrapper text="|" textType={ModalText} />
      <Space />
      <TextWrapper text="Terms" textType={ModalText} />
      <Space />
      <TextWrapper text="Privacy" textType={ModalText} />
    </View>
  }
}

module CheckoutHeader = {
  @react.component
  let make = (~toggleModal) => {
    let {bgColor} = ThemebasedStyle.useThemeBasedStyle()
    let useMediaView = WindowDimension.useMediaView()()

    <View
      style={array([
        viewStyle(
          ~flexDirection=#row,
          ~alignItems=#center,
          ~padding=16.->dp,
          ~justifyContent=#"space-between",
          (),
        ),
        bgColor,
      ])}>
      <View style={viewStyle(~flexDirection=#row, ~alignItems=#center, ())}>
        // <CustomTouchableOpacity style={viewStyle(~padding=16.->dp, ())}>
        //   <Icon name="back" height=24. width=20. fill="black" />
        // </CustomTouchableOpacity>
        <ReImage
          uri="https://stripe-camo.global.ssl.fastly.net/63f4ec8cbe3d41be42a10161d3a86d3a3bda2d541052dc077e4d5e164c3386e1/68747470733a2f2f66696c65732e7374726970652e636f6d2f66696c65732f4d44423859574e6a64463878534559775a317044536c4978626d7470597a4a5866475a666447567a6446394263456c304f453952576e5a7652454a555330566f4d47564d62464e34546b38303063713345486f6c71"
        />
        <Space width=10. />
        <TextWrapper text="Powdur" textType={CardText} />
        <Space width=10. />
        <View
          style={viewStyle(
            ~backgroundColor="#ffdd93",
            ~paddingHorizontal=5.->dp,
            ~paddingVertical=2.->dp,
            ~borderRadius=3.,
            (),
          )}>
          <TextWrapper textType={ModalTextBold}> {"TEST MODE"->React.string} </TextWrapper>
        </View>
      </View>
      {useMediaView == Mobile
        ? <View style={viewStyle(~flexDirection=#row, ~alignItems=#center, ())}>
            <CustomTouchableOpacity
              onPress={_ => toggleModal()}
              style={viewStyle(~flexDirection=#row, ~alignItems=#center, ())}>
              <TextWrapper text="Details" textType={ModalText} />
              <Space width=10. />
              <Icon
                style={viewStyle(~transform=[rotate(~rotate=270.->deg)], ())}
                name="back"
                height=15.
                width=15.
                fill="hsla(0,0%, 10% , 0.5 )"
              />
            </CustomTouchableOpacity>
          </View>
        : React.null}
    </View>
  }
}

module Cart = {
  @react.component
  let make = () => {
    <View
      style={viewStyle(
        ~flexDirection=#row,
        ~paddingHorizontal=18.->dp,
        ~justifyContent=#"space-between",
        (),
      )}>
      <View style={viewStyle(~flexDirection=#row, ())}>
        <ReImage
          style={viewStyle(~width=50.->dp, ~height=50.->dp, ~borderRadius=8., ())}
          uri="https://stripe-camo.global.ssl.fastly.net/c25a949b6f1ffabee9af1a5696d7f152325bdce2d1b926456d42994c3d91ad78/68747470733a2f2f66696c65732e7374726970652e636f6d2f6c696e6b732f666c5f746573745f67625631776635726a4c64725a635858647032346d643649"
        />
        <Space />
        <View>
          <TextWrapper text="The Pure Set" textType={ModalText} />
          <TextWrapper text="Qty 1" textType={ModalText} />
        </View>
      </View>
      <TextWrapper text="US$65.00" textType={CardText} />
    </View>
  }
}
module CartView = {
  @react.component
  let make = (~slideAnimation) => {
    let isMobileView = WindowDimension.useIsMobileView()
    let style = isMobileView
      ? viewStyle(~transform=Animated.ValueXY.getTranslateTransform(slideAnimation), ())
      : viewStyle()
    let {bgColor} = ThemebasedStyle.useThemeBasedStyle()

    <Animated.View style={array([style, bgColor, viewStyle(~elevation=10., ())])}>
      <Space />
      <Cart />
      <Space />
      <Cart />
      <Space />
      <View
        style={viewStyle(
          ~flexDirection=#row,
          ~justifyContent=#"space-between",
          ~paddingHorizontal=20.->dp,
          (),
        )}>
        <TextWrapper text="Total" textType={ModalText} />
        <TextWrapper text="US$129.00" textType={CardText} />
      </View>
      <Space height=20. />
    </Animated.View>
  }
}

@react.component
let make = () => {
  let (modalKey, setModalKey) = React.useState(_ => false)
  let (slideAnimation, _) = React.useState(_ => Animated.ValueXY.create({"x": 0., "y": -200.}))
  let isMobileView = WindowDimension.useIsMobileView()

  let toggleModal = () => {
    if modalKey {
      Animated.timing(
        slideAnimation["y"],
        {
          toValue: -200.->Animated.Value.Timing.fromRawValue,
          duration: 300.,
          useNativeDriver: false,
        },
      )
      ->Animated.start(~endCallback=_ => setModalKey(_ => false), ())
      ->ignore
    } else {
      setModalKey(_ => true)
      Animated.timing(
        slideAnimation["y"],
        {
          toValue: 1.->Animated.Value.Timing.fromRawValue,
          duration: 300.,
          useNativeDriver: false,
        },
      )
      ->Animated.start()
      ->ignore
    }
  }

  <View style={viewStyle(~width=100.->pct, ())}>
    <CheckoutHeader toggleModal />
    <Space height=30. />
    <View style={isMobileView ? viewStyle() : viewStyle()}>
      <CheckoutDetails toggleModal />
      {isMobileView
        ? <Modal
            visible=modalKey
            animationType={#none}
            presentationStyle={#overFullScreen}
            transparent=true
            supportedOrientations=[#"portrait-upside-down"]>
            <View style={viewStyle(~backgroundColor="rgba(0,0,0,0.2)", ~flex=1., ())}>
              <CartView slideAnimation />
              <CustomTouchableOpacity
                style={viewStyle(~flex=1., ())} onPress={_ => toggleModal()}
              />
            </View>
          </Modal>
        : <CartView slideAnimation />}
    </View>
  </View>
}
