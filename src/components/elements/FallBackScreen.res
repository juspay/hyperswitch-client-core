open ReactNative
open Style

type level = Top | Screen | Widget

@react.component
let make = (~error: Sentry.fallbackArg, ~level: level, ~rootTag) => {
  let {simplyExit} = HyperModule.useExitPaymentsheet()

  switch level {
  | Top =>
    <SafeAreaView
      style={s({
        flex: 1.,
        alignItems: #center,
        justifyContent: #"flex-end",
        backgroundColor: "#00000040",
      })}>
      <View
        style={s({
          width: 100.->pct,
          alignItems: #center,
          backgroundColor: "white",
          padding: 20.->dp,
          borderTopLeftRadius: 20.,
          borderTopRightRadius: 20.,
        })}>
        <View style={s({alignItems: #"flex-end", width: 100.->pct})}>
          <CustomPressable
            onPress={_ => simplyExit(PaymentConfirmTypes.defaultCancelError, rootTag, false)}>
            <Icon name="close" fill="black" height=20. width=20. />
          </CustomPressable>
        </View>
        <View
          style={s({
            flex: 1.,
            alignItems: #center,
            justifyContent: #center,
            paddingVertical: 48.->dp,
          })}>
          <Icon name="brokenrobot" fill="black" height=60. width=60. />
          <Space />
          <TextWrapper text="Oops, Something went wrong!" textType=HeadingBold />
          <Space height=10. />
          <TextWrapper text="We'll be back with you shortly :)" textType=SubheadingBold />
        </View>
        <Space />
        <CustomButton
          borderRadius=20.
          buttonState=Normal
          backgroundColor="#006DF9"
          text="Retry"
          leftIcon=CustomIcon(<Icon name="reload" fill="white" height=24. width=24. />)
          onPress={_ => {
            error.resetError()
          }}
        />
        <Space />
      </View>
    </SafeAreaView>
  | Screen =>
    <View
      style={s({
        alignItems: #center,
        justifyContent: #center,
        width: 100.->pct,
        padding: 20.->dp,
      })}>
      <View
        style={s({
          flex: 1.,
          alignItems: #center,
          justifyContent: #center,
          paddingVertical: 8.->dp,
        })}>
        <Icon name="brokenrobot" fill="black" height=60. width=60. />
        <Space />
        <TextWrapper text="Oops, Something went wrong!" textType=HeadingBold />
        <Space height=10. />
        <TextWrapper text="We'll be back with you shortly :)" textType=SubheadingBold />
      </View>
    </View>
  | Widget =>
    <View
      style={s({
        flex: 1.,
        backgroundColor: "white",
        alignItems: #center,
        justifyContent: #center,
        paddingHorizontal: 40.->dp,
      })}>
      <View
        style={s({
          flexDirection: #row,
          alignItems: #center,
          justifyContent: #center,
        })}>
        <Icon name="connectionlost" fill="black" height=32. width=32. />
        <Space width=5. />
        <TextWrapper text="Oops, something went wrong!" textType=ErrorTextBold />
      </View>
    </View>
  }
}
