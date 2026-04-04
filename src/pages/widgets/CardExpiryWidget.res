open ReactNative
open Style
open Validation

// Card Expiry Widget
// A standalone widget for collecting card expiry date in "MM / YY" format

// Named constants for magic numbers
let maxExpiryLength = 7
let widgetBaseHeight = 120
let minMonth = 1
let maxMonth = 12
let singleDigitMonthMax = 9
let doubleDigitPrefixThreshold = 2
let yearPrefix = "20"

// Type for expiry response
type expiryResponse = {
  isValid: bool,
  expiryMonth: string,
  expiryYear: string,
}

// Convert expiry response to JSON
let responseToJson = (response: expiryResponse) => {
  [
    ("isValid", response.isValid->Js.Json.boolean),
    ("expiryMonth", response.expiryMonth->Js.Json.string),
    ("expiryYear", response.expiryYear->Js.Json.string),
  ]
  ->Dict.fromArray
  ->JSON.Encode.object
}

// Extract and send expiry data to native with validation
let validateAndSendExpiry = (
  ~expiry: string,
  ~setExpiryError: string => unit,
  ~setIsValid: bool => unit,
  ~localeObject: LocaleDataType.localeStrings,
) => {
  if expiry == "" {
    setExpiryError(localeObject.cardExpiryDateEmptyText)
    setIsValid(false)
    let response = {
      isValid: false,
      expiryMonth: "",
      expiryYear: "",
    }
    HyperModule.sendMessageToNative(response->responseToJson->Js.Json.stringify)
    false
  } else if !checkCardExpiry(expiry) {
    setExpiryError(localeObject.inValidExpiryErrorText)
    setIsValid(false)
    let response = {
      isValid: false,
      expiryMonth: "",
      expiryYear: "",
    }
    HyperModule.sendMessageToNative(response->responseToJson->Js.Json.stringify)
    false
  } else {
    let (month, year) = splitExpiryDates(expiry)
    let yearWithPrefix = yearPrefix ++ year
    setExpiryError("")
    setIsValid(true)
    let response = {
      isValid: true,
      expiryMonth: month,
      expiryYear: yearWithPrefix,
    }
    HyperModule.sendMessageToNative(response->responseToJson->Js.Json.stringify)
    true
  }
}

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
    let localeObject = GetLocale.useGetLocalObj()
    let {component, dangerColor, borderRadius, borderWidth} = ThemebasedStyle.useThemeBasedStyle()
    let expiryRef = React.useRef(Nullable.null)

    // Format expiry as "MM / YY" during input
    let formatExpiryInput = val => {
      let clearValue = val->clearSpaces
      let expiryVal = clearValue->toInt
      let formatted = if (
        expiryVal >= doubleDigitPrefixThreshold &&
        expiryVal <= singleDigitMonthMax &&
        clearValue->String.length == 1
      ) {
        `0${clearValue} / `
      } else if clearValue->String.length == 2 && expiryVal > maxMonth {
        let val = clearValue->String.split("")
        `0${val->Array.get(0)->Option.getOr("")} / ${val->Array.get(1)->Option.getOr("")}`
      } else {
        clearValue
      }

      if clearValue->String.length >= 3 {
        `${formatted->String.slice(~start=0, ~end=2)} / ${formatted->String.slice(
            ~start=2,
            ~end=4,
          )}`
      } else {
        formatted
      }
    }

    // Handle input change with auto-formatting
    let handleExpiryChange = text => {
      let formatted = formatExpiryInput(text)

      // Only allow max maxExpiryLength characters ("MM / YY")
      let limited = if formatted->String.length > maxExpiryLength {
        formatted->String.substring(~start=0, ~end=maxExpiryLength)
      } else {
        formatted
      }

      setCardExpiry(limited)

      // Clear error when user starts typing
      if expiryError != "" {
        setExpiryError("")
      }
    }

    // Validate expiry on blur and send data to native
    let handleExpiryBlur = _ => {
      ignore(
        validateAndSendExpiry(
          ~expiry=cardExpiry->String.trim,
          ~setExpiryError,
          ~setIsValid,
          ~localeObject,
        ),
      )
      onBlur()
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
        maxLength=Some(maxExpiryLength)
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
  let (cardExpiry, setCardExpiry) = React.useState(_ => "")
  let (isValid, setIsValid) = React.useState(_ => false)
  let (expiryError, setExpiryError) = React.useState(_ => "")
  let (isReady, setIsReady) = React.useState(_ => false)
  let (confirm, setConfirm) = React.useState(_ => false)
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
      ignore(
        validateAndSendExpiry(
          ~expiry=cardExpiry,
          ~setExpiryError=err => setExpiryError(_ => err),
          ~setIsValid=valid => setIsValid(_ => valid),
          ~localeObject,
        ),
      )
      setConfirm(_ => false)
    }
    None
  }, [confirm])

  // Update widget height based on content
  React.useEffect1(() => {
    HyperModule.updateWidgetHeight(widgetBaseHeight)
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
