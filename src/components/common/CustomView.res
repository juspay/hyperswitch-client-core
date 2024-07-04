open ReactNative
open Style
type modalPosition = [#center | #top | #bottom]
@react.component
let make = (
  ~onDismiss=() => (),
  ~children,
  ~closeOnClickOutSide=false,
  ~modalPosition: modalPosition=#center,
  ~bottomModalWidth=100.->pct,
  (),
) => {
  let modalPosStyle = switch modalPosition {
  | #center => viewStyle(~alignItems=#center, ~justifyContent=#center, ())
  | #top => viewStyle(~alignItems=#center, ~justifyContent=#"flex-start", ())
  | #bottom => viewStyle(~alignItems=#center, ~justifyContent=#"flex-end", ())
  }
  let (loading, _) = React.useContext(LoadingContext.loadingContext)
  let disableClickOutside = switch loading {
  | FillingDetails => !closeOnClickOutSide
  | _ => true
  }

  //  let (locationY, setLocationY) = React.useState(_ => 0.)

  <View
    style={array([
      viewStyle(~flex=1., ~width=100.->pct, ~height=100.->pct, ~alignItems=#center, ()),
      modalPosStyle,
    ])}>
    <TouchableOpacity
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
          setViewHeight(_ => height +. 90.)
        }
      | None => ()
      }
    }

    let (heightPosition, _) = React.useState(_ => Animated.Value.create(0.))
    let setAnimation = _ => {
      Animated.timing(
        heightPosition,
        Animated.Value.Timing.config(
          ~toValue={
            viewHeight->Animated.Value.Timing.fromRawValue
          },
          ~isInteraction=true,
          ~useNativeDriver=false,
          ~delay=0.,
          ~duration=150.,
          ~easing=Easing.linear,
          (),
        ),
      )->Animated.start()
    }

    React.useEffect(() => {
      setAnimation()
      None
    }, [viewHeight])

    <Animated.ScrollView
      style={array([
        viewStyle(
          ~height=heightPosition->Animated.StyleProp.size,
          ~width,
          //    ~overflow=#hidden,
          ~minHeight=250.->dp,
          ~borderRadius=15.,
          ~borderBottomLeftRadius=0.,
          ~borderBottomRightRadius=0.,
          (),
        ),
        bgColor,
      ])}>
      <ModalHeader onModalClose />
      <View onLayout=updateScrollViewHeight> {children} </View>
      <Space height={Platform.os == #ios ? 48. : 24.} />
      <LoadingOverlay />
    </Animated.ScrollView>
  }
}
