open ReactNative
open Style

module BlinkingNfcIcon = {
  @react.component
  let make = (~isListening: bool, ~size: float, ~color: string, ~activeColor: string) => {
    let blinkOpacity = AnimatedValue.useAnimatedValue(1.0)

    React.useEffect1(() => {
      if isListening {
        let anim = Animated.loop(
          Animated.sequence([
            Animated.timing(blinkOpacity, {
              toValue: 0.3->Animated.Value.Timing.fromRawValue,
              isInteraction: false,
              useNativeDriver: true,
              delay: 0.,
              duration: 500.,
              easing: Easing.inOut(Easing.ease),
            }),
            Animated.timing(blinkOpacity, {
              toValue: 1.0->Animated.Value.Timing.fromRawValue,
              isInteraction: false,
              useNativeDriver: true,
              delay: 0.,
              duration: 500.,
              easing: Easing.inOut(Easing.ease),
            }),
          ]),
        )

        anim->Animated.start

        Some(
          () => {
            anim->Animated.stop
            blinkOpacity->Animated.Value.setValue(1.0)
          },
        )
      } else {
        blinkOpacity->Animated.Value.setValue(1.0)
        None
      }
    }, [isListening])

    let opacity = blinkOpacity->Animated.StyleProp.float

    {isListening
      ? <Animated.View style={s({opacity: opacity})}>
          <Icon name="nfc" height=size width=size fill=activeColor />
        </Animated.View>
      : <Icon name="nfc" height=size width=size fill=color />}
  }
}

@react.component
let make = (~onNfcCardRead, ~expireRef, ~cvvRef) => {
  let {primaryColor, component} = ThemebasedStyle.useThemeBasedStyle()
  let logger = LoggerHook.useLoggerHook()
  let showAlert = AlertHook.useAlerts()
  let (isListening, setIsListening) = React.useState(() => false)
  let (isNfcAvailable, setIsNfcAvailable) = React.useState(() => false)
  let unsubscribeResultRef = React.useRef(None)
  let unsubscribeErrorRef = React.useRef(None)
  let startListeningRef = React.useRef(None)

  // Check NFC availability on mount
  React.useEffect0(() => {
    NfcEmvModule.isAvailableFn()
    ->Promise.then(available => {
      setIsNfcAvailable(_ => available)
      Promise.resolve()
    })
    ->ignore

    None
  })

  let cleanup = () => {
    switch unsubscribeResultRef.current {
    | Some(unsub) => unsub()
    | None => ()
    }
    switch unsubscribeErrorRef.current {
    | Some(unsub) => unsub()
    | None => ()
    }
    unsubscribeResultRef.current = None
    unsubscribeErrorRef.current = None
  }

  let rec stopNfcListening = () => {
    setIsListening(_ => false)
    cleanup()
    NfcEmvModule.stopListening()->ignore
  }

  and startNfcListening = () => {
    setIsListening(_ => true)
    logger(~logType=INFO, ~value="NFC Listening Started", ~category=USER_EVENT, ~eventName=NFC_CARD_READ, ())

    // Set up listeners before starting
    let unsubscribeResult = NfcEmvModule.onResult((data: NfcEmvModule.cardData) => {
      onNfcCardRead(data.cardNumber, data.expiryDate, expireRef, cvvRef)
      logger(~logType=INFO, ~value="NFC Card Read Success", ~category=USER_EVENT, ~eventName=NFC_CARD_READ, ())
      stopNfcListening()
    })
    unsubscribeResultRef.current = Some(unsubscribeResult)

    let unsubscribeError = NfcEmvModule.onError((error: NfcEmvModule.nfcEmvError) => {
      logger(~logType=ERROR, ~value=`NFC Error: ${error.message}`, ~category=USER_EVENT, ~eventName=NFC_CARD_READ, ())
      // Auto-retry on error unless user cancelled
      if error.code !== "USER_CANCELLED" {
        cleanup()
        // Small delay before retry to avoid rapid retries
        let _ = setTimeout(() => {
          switch startListeningRef.current {
          | Some(fn) => fn()
          | None => ()
          }
        }, 500)
      } else {
        stopNfcListening()
        showAlert(~errorType="warning", ~message="NFC card read cancelled.")
      }
    })
    unsubscribeErrorRef.current = Some(unsubscribeError)

    // Now start listening
    NfcEmvModule.startListening()
    ->Promise.catch(_ => {
      logger(~logType=ERROR, ~value="NFC Start Failed", ~category=USER_EVENT, ~eventName=NFC_CARD_READ, ())
      stopNfcListening()
      showAlert(~errorType="warning", ~message="Failed to start NFC. Please check NFC settings.")
      Promise.resolve()
    })
    ->ignore
  }

  // Store reference to startNfcListening for retry logic
  React.useEffect1(() => {
    startListeningRef.current = Some(startNfcListening)
    None
  }, [])

  // Cleanup on unmount
  React.useEffect0(() => {
    Some(() => {
      cleanup()
      NfcEmvModule.stopListening()->ignore
    })
  })

  let handleNfcPress = () => {
    if isListening {
      stopNfcListening()
    } else {
      // Check permissions first
      NfcEmvModule.checkPermissions()
      ->Promise.then(hasPermission => {
        if hasPermission {
          startNfcListening()
        } else {
          NfcEmvModule.requestPermissions()
          ->Promise.then(granted => {
            if granted {
              startNfcListening()
            } else {
              showAlert(~errorType="warning", ~message="NFC permission is required to scan cards.")
            }
            Promise.resolve()
          })
          ->ignore
        }
        Promise.resolve()
      })
      ->ignore
    }
  }

  // Don't render if NFC is not available
  !isNfcAvailable
    ? React.null
    : <>
        <View
          style={s({
            backgroundColor: component.borderColor,
            marginLeft: 10.->dp,
            marginRight: 10.->dp,
            height: 80.->pct,
            width: 1.->dp,
          })}
        />
        <CustomPressable
          style={s({
            height: 100.->pct,
            width: 32.->dp,
            display: #flex,
            alignItems: #"flex-start",
            justifyContent: #center,
          })}
          onPress={_ => handleNfcPress()}>
          <BlinkingNfcIcon
            isListening={isListening}
            size=28.
            color={component.color}
            activeColor={primaryColor}
          />
        </CustomPressable>
      </>
}
