open ReactNative
open Style
module TermsView = {
  @react.component
  let make = () => {
    <View style={s({flexDirection: #row, width: 100.->pct})}>
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
        s({
          flexDirection: #row,
          alignItems: #center,
          padding: 16.->dp,
          justifyContent: #"space-between",
        }),
        bgColor,
      ])}>
      <View style={s({flexDirection: #row, alignItems: #center})}>
        // <CustomPressable style={s(~padding=16.->dp, ())}>
        //   <Icon name="back" height=24. width=20. fill="black" />
        // </CustomPressable>
        // <ReImage uri="" />
        <Space width=10. />
        <TextWrapper text="Powdur" textType={CardText} />
        <Space width=10. />
        <View
          style={s({
            backgroundColor: "#ffdd93",
            paddingHorizontal: 5.->dp,
            paddingVertical: 2.->dp,
            borderRadius: 3.,
          })}>
          <TextWrapper textType={ModalTextBold}> {"TEST MODE"->React.string} </TextWrapper>
        </View>
      </View>
      {useMediaView == Mobile
        ? <View style={s({flexDirection: #row, alignItems: #center})}>
            <CustomPressable
              onPress={_ => toggleModal()} style={s({flexDirection: #row, alignItems: #center})}>
              <TextWrapper text="Details" textType={ModalText} />
              <Space width=10. />
              <ChevronIcon width=15. height=15. fill="hsla(0,0%, 10% , 0.5 )" />
            </CustomPressable>
          </View>
        : React.null}
    </View>
  }
}

module Cart = {
  @react.component
  let make = () => {
    <View
      style={s({
        flexDirection: #row,
        paddingHorizontal: 18.->dp,
        justifyContent: #"space-between",
      })}>
      <View style={s({flexDirection: #row})}>
        // <ReImage
        //   style={s({width: 50.->dp, height: 50.->dp, borderRadius: 8.})}
        //   uri=""
        // />
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
      ? s({transform: Animated.ValueXY.getTranslateTransform(slideAnimation)})
      : empty
    let {bgColor} = ThemebasedStyle.useThemeBasedStyle()

    <Animated.View style={array([style, bgColor, s({elevation: 10.})])}>
      <Space />
      <Cart />
      <Space />
      <Cart />
      <Space />
      <View
        style={s({
          flexDirection: #row,
          justifyContent: #"space-between",
          paddingHorizontal: 20.->dp,
        })}>
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
      ->Animated.start(~endCallback=_ => setModalKey(_ => false))
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
      ->Animated.start
      ->ignore
    }
  }

  <View style={s({width: 100.->pct})}>
    <CheckoutHeader toggleModal />
    <Space height=30. />
    <View style={isMobileView ? empty : empty}>
      <CheckoutDetails toggleModal />
      {isMobileView
        ? <Modal
            visible=modalKey
            animationType={#none}
            presentationStyle={#overFullScreen}
            transparent=true
            supportedOrientations=[#"portrait-upside-down"]>
            <View style={s({backgroundColor: "rgba(0,0,0,0.2)", flex: 1.})}>
              <CartView slideAnimation />
              <CustomPressable style={s({flex: 1.})} onPress={_ => toggleModal()} />
            </View>
          </Modal>
        : <CartView slideAnimation />}
    </View>
  </View>
}
