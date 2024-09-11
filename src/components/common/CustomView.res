open ReactNative
open Style
type modalPosition = [#center | #top | #bottom]
@react.component
let make = (
  ~onDismiss=() => (),
  ~children,
  ~closeOnClickOutSide=true,
  ~modalPosition: modalPosition=#bottom,
  ~bottomModalWidth=100.->pct,
  (),
) => {
  let modalPosStyle = array([
    viewStyle(~flex=1., ~width=100.->pct, ~height=100.->pct, ~alignItems=#center, ()),
    switch modalPosition {
    | #center => viewStyle(~alignItems=#center, ~justifyContent=#center, ())
    | #top => viewStyle(~alignItems=#center, ~justifyContent=#"flex-start", ())
    | #bottom => viewStyle(~alignItems=#center, ~justifyContent=#"flex-end", ())
    },
  ])

  let (loading, _) = React.useContext(LoadingContext.loadingContext)
  let disableClickOutside = switch loading {
  | FillingDetails => !closeOnClickOutSide
  | _ => true
  }

  //  let (locationY, setLocationY) = React.useState(_ => 0.)

  <View style=modalPosStyle>
    <CustomTouchableOpacity
      style={viewStyle(~flex=1., ~width=100.->pct, ~flexGrow=1., ())}
      disabled=disableClickOutside
      onPress={_ => {
        if closeOnClickOutSide {
          onDismiss()
        }
      }}
    />
    // <TouchableWithoutFeedback
    //   onPressIn={e => setLocationY(_ => e.nativeEvent.locationY)}
    //   onPressOut={e => {
    //     if e.nativeEvent.locationY->Float.toInt - locationY->Float.toInt > 20 {
    //       onDismiss()
    //     }
    //   }}>
    <View
      style={viewStyle(
        ~width=bottomModalWidth,
        ~borderRadius=15.,
        ~borderBottomLeftRadius=0.,
        ~borderBottomRightRadius=0.,
        ~overflow=#hidden,
        ~maxHeight=95.->pct,
        ~alignItems=#center,
        ~justifyContent=#center,
        (),
      )}>
      <SafeAreaView />
      {children}
    </View>
    // </TouchableWithoutFeedback>
  </View>
}

module Wrapper = {
  @react.component
  let make = (~onModalClose, ~width=100.->pct, ~children=React.null) => {
    let {bgColor} = ThemebasedStyle.useThemeBasedStyle()

    let (viewHeight, setViewHeight) = React.useState(_ => 0.)
    let (modalViewHeight, setModalViewHeight) = React.useState(_ => 0.)

    let updateScrollViewHeight = (event: Event.layoutEvent) => {
      let nativeEvent = Event.LayoutEvent.nativeEvent(event)
      let vheight =
        nativeEvent
        ->JSON.Decode.object
        ->Option.getOr(Dict.make())
        ->Dict.get("layout")
        ->Option.getOr(JSON.Encode.null)
        ->JSON.Decode.object
        ->Option.getOr(Dict.make())
        ->Dict.get("height")

      switch vheight {
      | Some(height) => {
          let height = height->JSON.Decode.float->Option.getOr(0.)
          setViewHeight(_ => height)
        }
      | None => ()
      }
    }

    let updateModalViewHeight = (event: Event.layoutEvent) => {
      let nativeEvent = Event.LayoutEvent.nativeEvent(event)
      let vheight =
        nativeEvent
        ->JSON.Decode.object
        ->Option.getOr(Dict.make())
        ->Dict.get("layout")
        ->Option.getOr(JSON.Encode.null)
        ->JSON.Decode.object
        ->Option.getOr(Dict.make())
        ->Dict.get("height")

      switch vheight {
      | Some(height) => {
          let height = height->JSON.Decode.float->Option.getOr(0.)
          setModalViewHeight(_ => height)
        }
      | None => ()
      }
    }

    let (heightPosition, _) = React.useState(_ => Animated.Value.create(0.))
    let setAnimation = _ => {
      Animated.timing(
        heightPosition,
        {
          toValue: {
            (viewHeight +. modalViewHeight)->Animated.Value.Timing.fromRawValue
          },
          isInteraction: true,
          useNativeDriver: false,
          delay: 0.,
          duration: 150.,
          easing: Easing.linear,
        },
      )->Animated.start()
    }

    React.useEffect2(() => {
      setAnimation()
      None
    }, (viewHeight, modalViewHeight))

    <Animated.ScrollView
      style={array([
        viewStyle(
          ~height=heightPosition->Animated.StyleProp.size,
          ~width,
          ~minHeight=250.->dp,
          ~padding=20.->dp,
          (),
        ),
        bgColor,
      ])}>
      <ModalHeader onModalClose updateModalViewHeight />
      <View onLayout=updateScrollViewHeight> {children} </View>
    </Animated.ScrollView>
  }
}
