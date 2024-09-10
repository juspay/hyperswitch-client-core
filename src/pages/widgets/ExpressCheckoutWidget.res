open ReactNative
open Style

@react.component
let make = () => {
  let handleSuccessFailure = AllPaymentHooks.useHandleSuccessFailure()

  React.useEffect0(() => {
    let nee = NativeEventEmitter.make(
      Dict.get(ReactNative.NativeModules.nativeModules, "HyperModule"),
    )
    let event = NativeEventEmitter.addListener(nee, "confirmEC", var => {
      let _responseFromJava = var->PaymentConfirmTypes.itemToObjMapperJava
      handleSuccessFailure(
        ~apiResStatus={
          message: "",
          code: "",
          type_: "",
          status: "succeeded",
        },
        ~closeSDK=false,
        (),
      )
    })
    HyperModule.sendMessageToNative(`{"isReady": "true", "paymentMethodType": "expressCheckout"}`)
    Some(
      () => {
        event->EventSubscription.remove
      },
    )
  })

  <View
    style={viewStyle(
      ~flex=1.,
      ~backgroundColor="white",
      ~flexDirection=#row,
      ~justifyContent=#"space-between",
      ~alignItems=#center,
      ~borderRadius=5.,
      ~paddingHorizontal=5.->dp,
      (),
    )}>
    <View style={viewStyle(~alignItems=#center, ~flexDirection=#row, ())}>
      <Icon name="visa" height=32. width=32. />
      <Space />
      <TextWrapper textType={PlaceholderText}> {"**** 4242"->React.string} </TextWrapper>
    </View>
    <CustomTouchableOpacity onPress={_ => HyperModule.launchWidgetPaymentSheet("", _ => {()})}>
      <TextWrapper textType={LinkText}> {"Change"->React.string} </TextWrapper>
    </CustomTouchableOpacity>
  </View>
}
