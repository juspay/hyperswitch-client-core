open ReactNative
open Style
open Validation
external toPlatform: ReactNative.Platform.os => string = "%identity"
external toInputRef: React.ref<Nullable.t<'a>> => TextInput.ref = "%identity"
@send external focus: Dom.element => unit = "focus"
@send external blur: Dom.element => unit = "blur"
// Module contents

@react.component
let make = (
  ~cardNumber,
  ~cvv,
  ~expireDate,
  ~onChangeCardNumber,
  ~onChangeCardExpire,
  ~onChangeCvv,
  ~isCardNumberValid,
  ~isExpireDataValid,
  ~isCvvValid,
  ~onScanCard,
  ~keyToTrigerButtonClickError,
) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let isCardNumberValid = isCardNumberValid->Option.getOr(true)
  let isExpireDateValid = isExpireDataValid->Option.getOr(true)
  let isCvvValid = isCvvValid->Option.getOr(true)
  let isMaxCardLength =
    cardNumber->clearSpaces->String.length == maxCardLength(getCardBrand(cardNumber))
  let (cardNumberIsFocus, setCardNumberIsFocus) = React.useState(_ => false)
  let (expireDateIsFocus, setExpireDateIsFocus) = React.useState(_ => false)
  let (cvvIsFocus, setCvvIsFocus) = React.useState(_ => false)
  let isCardNumberValid = {
    cardNumberIsFocus ? isCardNumberValid || !isMaxCardLength : isCardNumberValid
  }
  let isExpireDateValid = {
    expireDateIsFocus ? isExpireDateValid || expireDate->String.length < 7 : isExpireDateValid
  }
  let isCvvValid = {
    cvvIsFocus ? isCvvValid || !cvcNumberInRange(cvv, getCardBrand(cardNumber)) : isCvvValid
  }

  let {
    primaryColor,
    component,
    dangerColor,
    borderRadius,
    borderWidth,
  } = ThemebasedStyle.useThemeBasedStyle()
  let localeObject = GetLocale.useGetLocalObj()
  let cardRef = React.useRef(Nullable.null)
  let expireRef = React.useRef(Nullable.null)
  let cvvRef = React.useRef(Nullable.null)
  let cardBrand = getCardBrand(cardNumber)
  let showAlert = AlertHook.useAlerts()
  let logger = LoggerHook.useLoggerHook()
  let nullRef = React.useRef(Nullable.null)

  let errorMsgText = if !isCardNumberValid {
    Some(localeObject.inValidCardErrorText)
  } else if !isExpireDateValid {
    Some(localeObject.inCompleteExpiryErrorText)
  } else if !isCvvValid {
    Some(localeObject.inCompleteCVCErrorText)
  } else {
    None
  }

  let scanCardCallback = (scanCardReturnType: ScanCardModule.scanCardReturnStatus) => {
    switch scanCardReturnType {
    | Succeeded(data) => {
        onScanCard(data.pan, `${data.expiryMonth} / ${data.expiryYear}`, expireRef, cvvRef)
        logger(~logType=INFO, ~value="Succeeded", ~category=USER_EVENT, ~eventName=SCAN_CARD, ())
      }
    | Cancelled =>
      logger(~logType=WARNING, ~value="Cancelled", ~category=USER_EVENT, ~eventName=SCAN_CARD, ())
    | Failed => {
        showAlert(~errorType="warning", ~message="Failed to scan card")
        logger(~logType=ERROR, ~value="Failed", ~category=USER_EVENT, ~eventName=SCAN_CARD, ())
      }
    | _ => showAlert(~errorType="warning", ~message="Failed to scan card")
    }
  }
  React.useEffect1(() => {
    keyToTrigerButtonClickError != 0
      ? {
          onChangeCardNumber(cardNumber, nullRef)
          onChangeCardExpire(expireDate, nullRef)
          onChangeCvv(cvv, nullRef)
        }
      : ()
    None
  }, [keyToTrigerButtonClickError])

  let getScanCardComponent = (isScanCardAvailable, cardBrand, cardNumber) => {
    CustomInput.CustomIcon(
      <View style={array([viewStyle(~flexDirection=#row, ~alignItems=#center, ())])}>
        <Icon name={cardBrand === "" ? "waitcard" : cardBrand} height=30. width=30. fill="black" />
        <UIUtils.RenderIf condition={isScanCardAvailable && cardNumber === ""}>
          {<>
            <View
              style={viewStyle(
                ~backgroundColor=component.borderColor,
                ~marginLeft=10.->dp,
                ~marginRight=10.->dp,
                ~height=80.->pct,
                ~width=1.->dp,
                (),
              )}
            />
            <CustomTouchableOpacity
              style={viewStyle(
                ~height=100.->pct,
                ~width=27.5->dp,
                ~display=#flex,
                ~alignItems=#"flex-start",
                ~justifyContent=#center,
                (),
              )}
              onPress={_pressEvent => {
                ScanCardModule.launchScanCard(scanCardCallback)
                logger(
                  ~logType=INFO,
                  ~value="Launch",
                  ~category=USER_EVENT,
                  ~eventName=SCAN_CARD,
                  (),
                )
              }}>
              <Icon name={"CAMERA"} height=25. width=25. fill=primaryColor />
            </CustomTouchableOpacity>
          </>}
        </UIUtils.RenderIf>
      </View>,
    )
  }

  <ErrorBoundary level=FallBackScreen.Screen rootTag=nativeProp.rootTag>
    <View style={viewStyle(~width=100.->pct, ~borderRadius, ())}>
      <View style={viewStyle(~width=100.->pct, ())}>
        <CustomInput
          reference={None} // previously Some(cardRef->toInputRef)
          state=cardNumber
          setState={text => onChangeCardNumber(text, expireRef)}
          placeholder=nativeProp.configuration.placeholder.cardNumber
          keyboardType=#"number-pad"
          isValid=isCardNumberValid
          maxLength=Some(23)
          borderTopLeftRadius=borderRadius
          borderTopRightRadius=borderRadius
          borderBottomWidth=borderWidth
          borderLeftWidth=borderWidth
          borderRightWidth=borderWidth
          borderTopWidth=borderWidth
          borderBottomLeftRadius=0.
          borderBottomRightRadius=0.
          textColor={isCardNumberValid ? component.color : dangerColor}
          enableCrossIcon=false
          iconRight={getScanCardComponent(ScanCardModule.isAvailable, cardBrand, cardNumber)}
          onFocus={() => {
            setCardNumberIsFocus(_ => true)
            onChangeCardNumber(cardNumber, nullRef)
          }}
          onBlur={() => {
            setCardNumberIsFocus(_ => false)
          }}
          onKeyPress={(ev: TextInput.KeyPressEvent.t) => {
            if ev.nativeEvent.key == "Backspace" && cardNumber == "" {
              switch cardRef.current->Nullable.toOption {
              | None => ()
              | Some(ref) => ref->Nullable.toOption->Option.forEach(input => input->blur)
              }
            }
          }}
          animateLabel=localeObject.cardNumberLabel
        />
      </View>
      <View
        style={viewStyle(
          ~width=100.->pct,
          ~flexDirection=localeObject.localeDirection === "rtl" ? #"row-reverse" : #row,
          (),
        )}>
        <View style={viewStyle(~width=50.->pct, ())}>
          <CustomInput
            reference={Some(expireRef->toInputRef)}
            state=expireDate
            setState={text => onChangeCardExpire(text, cvvRef)}
            placeholder=nativeProp.configuration.placeholder.expiryDate
            keyboardType=#"number-pad"
            enableCrossIcon=false
            isValid=isExpireDateValid
            borderTopWidth=0.25
            borderRightWidth=borderWidth
            borderTopLeftRadius=0.
            borderTopRightRadius=0.
            borderBottomRightRadius=0.
            borderBottomLeftRadius=borderRadius
            borderBottomWidth=borderWidth
            borderLeftWidth=borderWidth
            textColor={isExpireDateValid ? component.color : dangerColor}
            onFocus={() => {
              setExpireDateIsFocus(_ => true)
              onChangeCardExpire(expireDate, nullRef)
            }}
            onBlur={() => {
              setExpireDateIsFocus(_ => false)
            }}
            onKeyPress={(ev: TextInput.KeyPressEvent.t) => {
              if ev.nativeEvent.key == "Backspace" && expireDate == "" {
                switch cardRef.current->Nullable.toOption {
                | None => ()
                | Some(ref) => ref->Nullable.toOption->Option.forEach(input => input->focus)
                }
              }
            }}
            animateLabel=localeObject.validThruText
          />
        </View>
        <View style={viewStyle(~width=50.->pct, ())}>
          <CustomInput
            reference={Some(cvvRef->toInputRef)}
            borderTopWidth=0.25
            borderLeftWidth=0.5
            borderTopLeftRadius=0.
            borderTopRightRadius=0.
            borderBottomLeftRadius=0.
            borderBottomRightRadius=borderRadius
            borderBottomWidth=borderWidth
            borderRightWidth=borderWidth
            secureTextEntry=true
            state=cvv
            isValid=isCvvValid
            setState={text => onChangeCvv(text, cvvRef)}
            placeholder=nativeProp.configuration.placeholder.cvv
            keyboardType=#"number-pad"
            enableCrossIcon=false
            onFocus={() => {
              setCvvIsFocus(_ => true)
              onChangeCvv(cvv, nullRef)
            }}
            onBlur={() => {
              setCvvIsFocus(_ => false)
            }}
            textColor={isCvvValid ? component.color : dangerColor}
            iconRight=CustomIcon({
              checkCardCVC(cvv, cardBrand)
                ? <Icon name="cvvfilled" height=35. width=35. fill="black" />
                : <Icon name="cvvempty" height=35. width=35. fill="black" />
            })
            onKeyPress={(ev: TextInput.KeyPressEvent.t) => {
              if ev.nativeEvent.key == "Backspace" && cvv == "" {
                switch expireRef.current->Nullable.toOption {
                | None => ()
                | Some(ref) => ref->Nullable.toOption->Option.forEach(input => input->focus)
                }
              }
            }}
            animateLabel=localeObject.cvcTextLabel
          />
        </View>
      </View>
    </View>
    {errorMsgText->Option.isSome ? <ErrorText text=errorMsgText /> : React.null}
  </ErrorBoundary>
}
