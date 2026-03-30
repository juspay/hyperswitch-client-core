open ReactNative
open Style
open Validation

// Card Expiry Widget
// A standalone widget for collecting card expiry date in "MM / YY" format

module CardExpiryInput = {
  @react.component
  let make = (
    ~cardExpiry: string,
    ~setCardExpiry: string => unit,
    ~isValid: bool,
    ~setIsValid: bool => unit,
    ~expiryError: string,
    ~setExpiryError: string => unit,
    ~onFocus=() => (),
    ~onBlur=() => (),
  ) => {
    let (_, _) = React.useContext(NativePropContext.nativePropContext)
    let localeObject = GetLocale.useGetLocalObj()
    let {
      component,
      dangerColor,
      borderRadius,
      borderWidth,
    } = ThemebasedStyle.useThemeBasedStyle()
    let expiryRef = React.useRef(Nullable.null)

    // Format expiry as "MM / YY" during input
    let formatExpiryInput = val => {
      let clearValue = val->clearSpaces
      let expiryVal = clearValue->toInt
      let formatted = if expiryVal >= 2 && expiryVal <= 9 && clearValue->String.length == 1 {
        `0${clearValue} / `
      } else if clearValue->String.length == 2 && expiryVal > 12 {
        let val = clearValue->String.split("")
        `0${val->Array.get(0)->Option.getOr("")} / ${val->Array.get(1)->Option.getOr("")}`
      } else {
        clearValue
      }

      if clearValue->String.length >= 3 {
        `${formatted->String.slice(~start=0, ~end=2)} / ${formatted->String.slice(~start=2, ~end=4)}`
      } else {
        formatted
      }
    }

    // Validate expiry on blur and send data to native
    let handleExpiryBlur = _ => {
      let expiry = cardExpiry->String.trim

      if expiry == "" {
        setExpiryError(localeObject.cardExpiryDateEmptyText)
        setIsValid(false)
        HyperModule.sendMessageToNative(
          `{"isValid": "false", "expiryMonth": "", "expiryYear": ""}`
        )
      } else if expiry->String.length < 7 {
        // "MM / YY" = 7 chars
        setExpiryError(localeObject.inValidExpiryErrorText)
        setIsValid(false)
        HyperModule.sendMessageToNative(
          `{"isValid": "false", "expiryMonth": "", "expiryYear": ""}`
        )
      } else if !checkCardExpiry(expiry) {
        setExpiryError(localeObject.inValidExpiryErrorText)
        setIsValid(false)
        HyperModule.sendMessageToNative(
          `{"isValid": "false", "expiryMonth": "", "expiryYear": ""}`
        )
      } else {
        setExpiryError("")
        setIsValid(true)
        // Extract month and year, send to native
        let (month, year) = splitExpiryDates(expiry)
        let yearWithPrefix = "20" ++ year
        HyperModule.sendMessageToNative(
          `{"isValid": "true", "expiryMonth": "${month}", "expiryYear": "${yearWithPrefix}"}`
        )
      }
      onBlur()
    }

    // Handle input change with auto-formatting
    let handleExpiryChange = text => {
      let formatted = formatExpiryInput(text)

      // Only allow max 7 characters ("MM / YY")
      let limited = if formatted->String.length > 7 {
        formatted->String.substring(~start=0, ~end=7)
      } else {
        formatted
      }

      setCardExpiry(limited)

      // Clear error when user starts typing
      if expiryError != "" {
        setExpiryError("")
      }
    }

    // Handle key press for backspace navigation
    let onKeyPress = (ev: TextInput.KeyPressEvent.t) => {
      if ev.nativeEvent.key == "Backspace" && cardExpiry == "" {
        // Optional: handle backspace when empty (e.g., focus previous field)
        ()
      }
    }

    <View style={s({width: 100.->pct})}>
      <CustomInput
        name={TestUtils.expiryInputTestId}
        reference={Some(expiryRef)}
        state=cardExpiry
        setState={handleExpiryChange}
        placeholder=localeObject.expiryPlaceholder
        keyboardType=#"number-pad"
        enableCrossIcon=false
        isValid={isValid || cardExpiry->String.length == 0}
        maxLength=Some(7)
        borderTopLeftRadius=borderRadius
        borderTopRightRadius=borderRadius
        borderBottomLeftRadius=borderRadius
        borderBottomRightRadius=borderRadius
        borderTopWidth=borderWidth
        borderBottomWidth=borderWidth
        borderLeftWidth=borderWidth
        borderRightWidth=borderWidth
        textColor={isValid || cardExpiry->String.length == 0 ? component.color : dangerColor}
        onFocus={() => {
          onFocus()
        }}
        onBlur={handleExpiryBlur}
        onKeyPress
        animateLabel=localeObject.validThruText
      />
      <UIUtils.RenderIf condition={expiryError != ""}>
        <ErrorText text={Some(expiryError)} />
      </UIUtils.RenderIf>
    </View>
  }
}

// Main CardExpiryWidget Component
@react.component
let make = () => {
  let (nativeProp, setNativeProp) = React.useContext(NativePropContext.nativePropContext)
  let (cardExpiry, setCardExpiry) = React.useState(() => "")
  let (isValid, setIsValid) = React.useState(() => false)
  let (expiryError, setExpiryError) = React.useState(() => "")
  let (isReady, setIsReady) = React.useState(() => false)
  let (confirm, setConfirm) = React.useState(() => false)
  let localeObject = GetLocale.useGetLocalObj()

  // Send widget ready message to native
  React.useEffect1(() => {
    if !isReady {
      NativeEventListener.sendReadyMessage("cardExpiry")
      setIsReady(_ => true)
    }
    None
  }, [isReady])

  // Setup widget event listener for confirm/validate events
  React.useEffect1(() => {
    let handleWidgetEvent = (response: NativeEventListener.widgetResponse) => {
      setNativeProp({
        ...nativeProp,
        publishableKey: response.publishableKey,
        clientSecret: response.clientSecret,
        hyperParams: {
          ...nativeProp.hyperParams,
          confirm: response.confirm,
        },
      })

      if response.confirm {
        setConfirm(_ => true)
      }
    }

    let cleanup = NativeEventListener.setupWidgetEventListener(
      ~onWidgetEvent=handleWidgetEvent,
      ~walletType=NONE,
    )

    Some(cleanup)
  }, [])

  // Handle confirm action - send collected data to native
  React.useEffect1(() => {
    if confirm {
      // Validate expiry
      if cardExpiry == "" {
        setExpiryError(_ => localeObject.cardExpiryDateEmptyText)
        setIsValid(_ => false)
        HyperModule.sendMessageToNative(
          `{"isValid": "false", "expiryMonth": "", "expiryYear": ""}`
        )
      } else if !checkCardExpiry(cardExpiry) {
        setExpiryError(_ => localeObject.inValidExpiryErrorText)
        setIsValid(_ => false)
        HyperModule.sendMessageToNative(
          `{"isValid": "false", "expiryMonth": "", "expiryYear": ""}`
        )
      } else {
        // Valid expiry - send data to native
        setIsValid(_ => true)
        
        // Extract month and year
        let (month, year) = splitExpiryDates(cardExpiry)
        let yearWithPrefix = "20" ++ year

        // Send collected data to native for processing
        HyperModule.sendMessageToNative(
          `{"isValid": "true", "expiryMonth": "${month}", "expiryYear": "${yearWithPrefix}"}`
        )
      }
      setConfirm(_ => false)
    }
    None
  }, [confirm])

  // Update widget height based on content
  React.useEffect1(() => {
    let widgetHeight = 120 // Base height for single input
    HyperModule.updateWidgetHeight(widgetHeight)
    None
  }, [])

  <View
    style={s({
      flex: 1.,
      width: 100.->pct,
      paddingHorizontal: 16.->dp,
      paddingVertical: 12.->dp,
      backgroundColor: "transparent",
      justifyContent: #center,
      alignItems: #center,
    })}>
    <CardExpiryInput
      cardExpiry={cardExpiry}
      setCardExpiry={text => setCardExpiry(_ => text)}
      isValid={isValid}
      setIsValid={valid => setIsValid(_ => valid)}
      expiryError={expiryError}
      setExpiryError={err => setExpiryError(_ => err)}
    />
  </View>
}
