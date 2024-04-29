open ReactNative
open Style

type level = Top | Screen | Widget

@react.component
let make = (~error: Sentry.fallbackArg, ~level, ~rootTag) => {
  let {simplyExit} = HyperModule.useExitPaymentsheet()

  switch level {
  | Top =>
    <SafeAreaView style={viewStyle(~flex=1., ~alignItems=#center, ~justifyContent=#"flex-end", ())}>
      <View
        style={viewStyle(
          ~width=100.->pct,
          ~alignItems=#center,
          ~backgroundColor="white",
          ~padding=20.->dp,
          (),
        )}>
        <View style={viewStyle(~alignItems=#"flex-end", ~width=100.->pct, ())}>
          <TouchableOpacity
            onPress={_ => simplyExit(PaymentConfirmTypes.defaultCancelError, rootTag, false)}>
            <Icon name="close" fill="black" height=20. width=20. />
          </TouchableOpacity>
        </View>
        <View style={viewStyle(~flexDirection=#row, ~padding=20.->dp, ())}>
          <Icon name="errorIcon" fill="black" height=60. width=60. />
          <View style={viewStyle(~flex=1., ~alignItems=#center, ~justifyContent=#center, ())}>
            <Text style={textStyle(~fontWeight=FontWeight._500, ~fontSize=16., ~color="black", ())}>
              {"Oops, something went wrong!"->React.string}
            </Text>
            <Text style={textStyle(~color="black", ())}>
              {"We'll be back with you shortly :)"->React.string}
            </Text>
          </View>
        </View>
        <Space />
        <TouchableOpacity onPress={_ => error.resetError()}>
          <Icon name="refresh" fill="black" height=32. width=32. />
        </TouchableOpacity>
        <Space />
      </View>
    </SafeAreaView>
  | Screen =>
    <View
      style={viewStyle(
        ~alignItems=#center,
        ~justifyContent=#center,
        ~width=100.->pct,
        ~padding=20.->dp,
        (),
      )}>
      <View style={viewStyle(~flexDirection=#row, ~backgroundColor="white", ())}>
        <Icon name="errorIcon" fill="black" height=60. width=60. />
        <View style={viewStyle(~flex=1., ~alignItems=#center, ~justifyContent=#center, ())}>
          <Text style={textStyle(~fontWeight=FontWeight._500, ~fontSize=16., ~color="black", ())}>
            {"Oops, something went wrong!"->React.string}
          </Text>
          <Text style={textStyle(~color="black", ())}>
            {"Try another payment method :)"->React.string}
          </Text>
        </View>
      </View>
    </View>
  | Widget =>
    <View
      style={viewStyle(
        ~flex=1.,
        ~backgroundColor="white",
        ~alignItems=#center,
        ~justifyContent=#center,
        ~paddingHorizontal=40.->dp,
        (),
      )}>
      <View style={viewStyle(~flexDirection=#row, ~backgroundColor="white", ())}>
        <Icon name="errorIcon" fill="black" height=32. width=32. />
        <View style={viewStyle(~flex=1., ~alignItems=#center, ~justifyContent=#center, ())}>
          <Text style={textStyle(~fontWeight=FontWeight._500, ~fontSize=16., ~color="black", ())}>
            {"Oops, something went wrong!"->React.string}
          </Text>
        </View>
      </View>
    </View>
  }
}
