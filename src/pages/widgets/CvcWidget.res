open ReactNative
open Style

@react.component
let make = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let {component, dangerColor} = ThemebasedStyle.useThemeBasedStyle()
  let localeObj = GetLocale.useGetLocalObj()
  let logger = LoggerHook.useLoggerHook()

  let (cvcNumber, setCvcNumber) = React.useState(_ => "")
  let (cardNetwork, setCardNetwork) = React.useState(_ => "")
  let (isCvcFocus, setIsCvcFocus) = React.useState(_ => false)
  let (cvcError, setCvcError) = React.useState(_ => None)

  let isCvcValid =
    isCvcFocus || cvcNumber == ""
      ? true
      : cvcNumber->String.length > 0 && Validation.cvcNumberInRange(cvcNumber, cardNetwork)

  let onCvcChange = cvc => setCvcNumber(_ => Validation.formatCVCNumber(cvc, cardNetwork))

  let handleCvcConfirmRequest = (request: NativeEventListener.cvcConfirmRequest) => {
    setCardNetwork(_ => request.cardNetwork)

    let isCvcComplete = Validation.checkCardCVC(cvcNumber, request.cardNetwork)

    if request.requiresCvv && isCvcComplete {
      setCvcError(_ => None)
      logger(
        ~logType=INFO,
        ~value="CVC Widget - CVC validated successfully",
        ~category=USER_EVENT,
        ~eventName=PAYMENT_DATA_FILLED,
        ~paymentMethod="cvc",
        (),
      )
      HyperModule.sendCvcResponse(~cvc=cvcNumber, ~isValid=true)
    } else if request.requiresCvv {
      let isEmptyCvc = cvcNumber->String.length == 0
      let errorMsg = if isEmptyCvc {
        localeObj.cvcNumberEmptyText
      } else {
        localeObj.inCompleteCVCErrorText
      }
      setCvcError(_ => Some(errorMsg))
      logger(
        ~logType=INFO,
        ~value="CVC Widget - CVC validation failed",
        ~category=USER_EVENT,
        ~eventName=PAYMENT_FAILED,
        ~paymentMethod="cvc",
        (),
      )
      HyperModule.sendCvcResponse(~cvc="", ~isValid=false, ~errorMessage=errorMsg)
    } else {
      // CVV not required, send success
      HyperModule.sendCvcResponse(~cvc="", ~isValid=true)
    }
  }

  React.useEffect1(() => {
    logger(
      ~logType=INFO,
      ~value="CVC Widget Rendered",
      ~category=USER_EVENT,
      ~eventName=APP_RENDERED,
      ~paymentMethod="cvc",
      (),
    )

    let cleanup = NativeEventListener.setupCvcWidgetListener(
      ~onCvcConfirmRequest=handleCvcConfirmRequest,
    )

    Some(cleanup)
  }, [cvcNumber])

  // Dynamic height based on error state
  React.useEffect1(_ => {
    let widgetHeight = cvcError->Option.isSome ? 100 : 70
    HyperModule.updateWidgetHeight(widgetHeight)
    None
  }, [cvcError])

  <ErrorBoundary level={FallBackScreen.Widget} rootTag=nativeProp.rootTag>
    <View
      style={s({
        flex: 1.,
        backgroundColor: "transparent",
        flexDirection: #column,
        justifyContent: #center,
        alignItems: #center,
        paddingHorizontal: 5.->dp,
        paddingVertical: 3.->dp,
      })}>
      <View
        style={s({
          width: 100.->pct,
          flexDirection: #row,
          alignItems: #center,
          paddingHorizontal: 10.->dp,
        })}>
        <View style={s({flex: 1.})}>
          <CustomInput
            state={cvcNumber}
            setState={onCvcChange}
            placeholder={nativeProp.configuration.placeholder.cvv}
            animateLabel="CVC"
            fontSize=14.
            keyboardType=#"number-pad"
            enableCrossIcon=false
            height=44.
            isValid={isCvcValid && cvcError->Option.isNone}
            onFocus={() => {
              setCvcError(_ => None)
              setIsCvcFocus(_ => true)
            }}
            onBlur={() => {
              setIsCvcFocus(_ => false)
            }}
            secureTextEntry=true
            textColor={isCvcValid && cvcError->Option.isNone ? component.color : dangerColor}
            iconRight=CustomIcon({
              Validation.checkCardCVC(cvcNumber, cardNetwork)
                ? <Icon name="cvvfilled" height=35. width=35. fill="black" />
                : <Icon name="cvvempty" height=35. width=35. fill="black" />
            })
            autoFocus=true
          />
        </View>
      </View>
      {switch cvcError {
      | Some(_errorMsg) =>
        <View
          style={s({
            width: 100.->pct,
            paddingHorizontal: 10.->dp,
            paddingTop: 4.->dp,
          })}>
          <ErrorText text=cvcError />
        </View>
      | None => React.null
      }}
    </View>
  </ErrorBoundary>
}
