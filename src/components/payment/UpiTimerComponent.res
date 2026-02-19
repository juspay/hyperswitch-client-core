open ReactNative
open Style

@react.component
let make = (~displayFromTimestamp: float, ~displayToTimestamp: float) => {
  // ~pollConfig: PaymentConfirmTypes.waitScreenPollConfig,
  // ~onStartPolling: (
  //   ~pollConfig: PaymentConfirmTypes.waitScreenPollConfig,
  //   ~pollCount: int,
  //   ~displayToTimestamp: float,
  // ) => unit,

  let totalDuration = {
    let startTime = displayFromTimestamp /. 1_000_000.
    let endTime = displayToTimestamp /. 1_000_000.
    let duration = (endTime -. startTime) /. 1000.
    duration
  }

  let (timeRemaining, setTimeRemaining) = React.useState(_ => {
    totalDuration
  })

  React.useEffect1(() => {
    let intervalId = setInterval(() => {
      setTimeRemaining(prev => max(0., prev -. 1.))
    }, 1000)

    Some(
      () => {
        clearInterval(intervalId)
      },
    )
  }, [])

  let formatTime = (seconds: float) => {
    let mins = (seconds /. 60.)->Float.toInt
    let secs = mod(seconds->Float.toInt, 60)
    `${mins->Int.toString->String.padStart(2, "0")}:${secs->Int.toString->String.padStart(2, "0")}`
  }

  let progressPercentage = totalDuration > 0. ? timeRemaining /. totalDuration : 0.

  let {
    primaryColor,
    disableBgColor,
    textSecondaryBold,
    filterHeaderColor,
  } = ThemebasedStyle.useThemeBasedStyle()

  <View style={s({justifyContent: #center, alignItems: #center})}>
    <View
      style={s({
        height: 8.->dp,
        width: 200.->dp,
        backgroundColor: disableBgColor,
        borderRadius: 4.,
      })}>
      <View
        style={s({
          height: 6.->dp,
          width: (200. *. progressPercentage)->dp,
          backgroundColor: primaryColor,
          borderRadius: 4.,
        })}
      />

      // <View
      //   style={s({
      //     height: 6.->dp,
      //     backgroundColor: primaryColor,
      //     width: (progressPercentage *. 100.)->pct,
      //     borderRadius: 4.,
      //   })}
      // />
    </View>
    <Space height=10. />
    <View style={s({flexDirection: #row, justifyContent: #center, alignItems: #center})}>
      <TextWrapper
        text="Complete payment within "
        textType={ModalText}
        overrideStyle={Some(Style.s({color: filterHeaderColor}))}
      />
      <TextWrapper
        text={formatTime(timeRemaining)}
        textType={SubheadingBold}
        overrideStyle={Some(textSecondaryBold)}
      />
      <TextWrapper
        text=" min" textType={ModalText} overrideStyle={Some(Style.s({color: filterHeaderColor}))}
      />
    </View>
  </View>
}
