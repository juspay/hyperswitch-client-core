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
  ~isZipAvailable=false,
  ~zip,
  ~onChangeCardNumber,
  ~onChangeCardExpire,
  ~onChangeCvv,
  ~onChangeZip,
  ~isCardNumberValid,
  ~isExpireDataValid,
  ~isCvvValid,
  ~isZipValid,
) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let (buttomFlex, _) = React.useState(_ => Animated.Value.create(1.))
  let isCardNumberValid = isCardNumberValid->Option.getOr(true)
  let isExpireDataValid = isExpireDataValid->Option.getOr(true)
  let isCvvValid = isCvvValid->Option.getOr(true)
  let isZipValid = isZipValid->Option.getOr(true)
  let isMaxCardLength =
    cardNumber->clearSpaces->String.length == maxCardLength(getCardBrand(cardNumber))
  let (cardNumberIsFocus, setCardNumberIsFocus) = React.useState(_ => false)
  let isCardNumberValid = {
    cardNumberIsFocus ? isCardNumberValid || !isMaxCardLength : isCardNumberValid
  }

  let localeObject = GetLocale.useGetLocalObj()
  let {bgColor, component, dangerColor} = ThemebasedStyle.useThemeBasedStyle()
  let (cardNumInputFlex, _) = React.useState(_ => Animated.Value.create(1.))
  let (expireInputFlex, _) = React.useState(_ => Animated.Value.create(1.))
  let (cvvInputFlex, _) = React.useState(_ => Animated.Value.create(1.))
  let (zipInputFlex, _) = React.useState(_ => Animated.Value.create(1.))
  let cardRef = React.useRef(Nullable.null)
  let expireRef = React.useRef(Nullable.null)
  let cvvRef = React.useRef(Nullable.null)
  let zipRef = React.useRef(Nullable.null)
  let cardBrand = getCardBrand(cardNumber)
  let (loading, _) = React.useContext(LoadingContext.loadingContext)

  let animateFlex = (~flexval, ~value) => {
    Animated.timing(
      flexval,
      {
        toValue: {value->Animated.Value.Timing.fromRawValue},
        isInteraction: true,
        useNativeDriver: false,
        delay: 0.,
      },
    )->Animated.start()
  }
  <ErrorBoundary level=FallBackScreen.Widget rootTag=nativeProp.rootTag>
    <View
      style={viewStyle(
        ~flex=1.,
        ~alignItems=#center,
        ~justifyContent=#center,
        ~flexDirection=localeObject.localeDirection === "rtl" ? #"row-reverse" : #row,
        (),
      )}>
      <View
        style={array([
          viewStyle(
            ~borderRadius=5.,
            ~overflow=#hidden,
            ~paddingHorizontal=5.->dp,
            ~flex=1.,
            ~alignItems=#center,
            ~justifyContent=#center,
            ~flexDirection=localeObject.localeDirection === "rtl" ? #"row-reverse" : #row,
            (),
          ),
          bgColor,
        ])}>
        {String.length(cardNumber) !== 0
          ? String.length(cvv) == 0
              ? <Icon
                  name={cardBrand === "" ? "waitcard" : cardBrand} height=35. width=35. fill="black"
                />
              : checkCardCVC(cvv, cardBrand)
              ? <Icon name="cvvfilled" height=35. width=35. fill="black" />
              : <Icon name="cvvempty" height=35. width=35. fill="black" />
          : <Icon name={"waitcard"} height=35. width=35. fill="black" />}
        // <Icon name={isCardNumberValid ? "cvvimage" : "error-card"} height=45. width=45. />
        <Animated.View style={viewStyle(~flex={cardNumInputFlex->Animated.StyleProp.float}, ())}>
          <CustomInput
            fontSize=13.
            enableShadow=false
            reference={Some(cardRef->toInputRef)}
            state={cardNumberIsFocus ? cardNumber : cardNumber->String.sliceToEnd(~start=-4)}
            setState={text => onChangeCardNumber(text, expireRef)}
            placeholder={cardNumberIsFocus
              ? "1234 1234 1234 1234"
              : "1234 1234 1234 1234"->String.sliceToEnd(~start=-4) ++ "..."}
            keyboardType=#"number-pad"
            enableCrossIcon=false
            textColor={isCardNumberValid ? component.color : dangerColor}
            borderTopWidth=0.
            borderBottomWidth=0.
            borderRightWidth=0.
            borderLeftWidth=0.
            borderTopLeftRadius=0.
            borderTopRightRadius=0.
            borderBottomRightRadius=0.
            borderBottomLeftRadius=0.
            onFocus={() => {
              setCardNumberIsFocus(_ => true)
              animateFlex(~flexval=cvvInputFlex, ~value=0.1)
              animateFlex(~flexval=zipInputFlex, ~value=0.1)
              animateFlex(~flexval=expireInputFlex, ~value=0.5)
            }}
            onBlur={() => {
              setCardNumberIsFocus(_ => false)
              animateFlex(~flexval=cvvInputFlex, ~value=1.0)
              animateFlex(~flexval=expireInputFlex, ~value=1.0)
              animateFlex(~flexval=zipInputFlex, ~value=1.0)
            }}
            onKeyPress={(ev: TextInput.KeyPressEvent.t) => {
              if ev.nativeEvent.key == "Backspace" && cardNumber == "" {
                switch cardRef.current->Nullable.toOption {
                | None => ()
                | Some(ref) => {
                    ref->Nullable.toOption->Option.forEach(input => input->blur)
                    animateFlex(~flexval=cvvInputFlex, ~value=1.0)
                    animateFlex(~flexval=expireInputFlex, ~value=1.0)
                    animateFlex(~flexval=zipInputFlex, ~value=1.0)
                  }
                }
              }
            }}
          />
        </Animated.View>
        <Animated.View style={viewStyle(~flex={expireInputFlex->Animated.StyleProp.float}, ())}>
          <CustomInput
            enableShadow=false
            fontSize=12.
            reference={Some(expireRef->toInputRef)}
            state=expireDate
            setState={text => onChangeCardExpire(text, cvvRef)}
            placeholder="MM / YY"
            keyboardType=#"number-pad"
            enableCrossIcon=false
            borderTopWidth=0.
            borderBottomWidth=0.
            textColor={isExpireDataValid ? component.color : dangerColor}
            borderRightWidth=0.
            borderLeftWidth=0.
            borderTopLeftRadius=0.
            borderTopRightRadius=0.
            borderBottomRightRadius=0.
            borderBottomLeftRadius=0.
            onFocus={() => {
              animateFlex(~flexval=cvvInputFlex, ~value=1.0)
              animateFlex(~flexval=expireInputFlex, ~value=1.0)
              animateFlex(~flexval=zipInputFlex, ~value=1.0)
            }}
            onBlur={() => {()}}
            onKeyPress={(ev: TextInput.KeyPressEvent.t) => {
              if ev.nativeEvent.key == "Backspace" && expireDate == "" {
                switch cardRef.current->Nullable.toOption {
                | None => ()
                | Some(ref) => ref->Nullable.toOption->Option.forEach(input => input->focus)
                }
              }
            }}
          />
        </Animated.View>
        <Animated.View style={viewStyle(~flex={cvvInputFlex->Animated.StyleProp.float}, ())}>
          <CustomInput
            fontSize=13.
            enableShadow=false
            reference={Some(cvvRef->toInputRef)}
            state=cvv
            setState={text =>
              isZipAvailable ? onChangeCvv(text, zipRef) : onChangeCvv(text, cvvRef)}
            borderTopWidth=0.
            borderBottomWidth=0.
            borderRightWidth=0.
            borderLeftWidth=0.
            borderTopLeftRadius=0.
            borderTopRightRadius=0.
            textColor={isCvvValid ? component.color : dangerColor}
            borderBottomRightRadius=0.
            borderBottomLeftRadius=0.
            secureTextEntry=true
            placeholder="CVV"
            keyboardType=#"number-pad"
            enableCrossIcon=false
            onFocus={() => {
              animateFlex(~flexval=cvvInputFlex, ~value=1.0)
              animateFlex(~flexval=expireInputFlex, ~value=1.0)
              animateFlex(~flexval=zipInputFlex, ~value=1.0)
            }}
            onBlur={() => {()}}
            onKeyPress={(ev: TextInput.KeyPressEvent.t) => {
              if ev.nativeEvent.key == "Backspace" && cvv == "" {
                switch expireRef.current->Nullable.toOption {
                | None => ()
                | Some(ref) => ref->Nullable.toOption->Option.forEach(input => input->focus)
                }
              }
            }}
          />
        </Animated.View>
        {isZipAvailable
          ? <Animated.View style={viewStyle(~flex={zipInputFlex->Animated.StyleProp.float}, ())}>
              <CustomInput
                enableShadow=false
                fontSize=13.
                reference={Some(zipRef->toInputRef)}
                state=zip
                setState={text => onChangeZip(text, zipRef)}
                textColor={isZipValid ? component.color : dangerColor}
                keyboardType=#"number-pad"
                borderTopWidth=0.
                borderBottomWidth=0.
                borderRightWidth=0.
                borderLeftWidth=0.
                borderTopLeftRadius=0.
                borderTopRightRadius=0.
                borderBottomRightRadius=0.
                borderBottomLeftRadius=0.
                placeholder="ZIP"
                enableCrossIcon=false
                onFocus={() => {
                  animateFlex(~flexval=cvvInputFlex, ~value=1.0)
                  animateFlex(~flexval=expireInputFlex, ~value=1.0)
                  animateFlex(~flexval=zipInputFlex, ~value=1.0)
                }}
                onBlur={() => {()}}
                onKeyPress={(ev: TextInput.KeyPressEvent.t) => {
                  if ev.nativeEvent.key == "Backspace" && zip == "" {
                    switch cvvRef.current->Nullable.toOption {
                    | None => ()
                    | Some(ref) => ref->Nullable.toOption->Option.forEach(input => input->focus)
                    }
                  }
                }}
              />
            </Animated.View>
          : React.null}
        <LoadingOverlay />
        {switch loading {
        | PaymentSuccess =>
          <View style={viewStyle(~width=100.->pct, ~position=#absolute, ~opacity=0.7, ())}>
            <Animated.View
              style={viewStyle(
                ~backgroundColor="mediumseagreen",
                ~flex=1.,
                ~alignItems=#center,
                ~justifyContent=#center,
                ~flexDirection=#row,
                ~height=100.->pct,
                (),
              )}>
              <Animated.View
                style={viewStyle(
                  ~flex={buttomFlex->Animated.StyleProp.float},
                  ~height=100.->dp,
                  (),
                )}
              />
              <Icon name="completepayment" width=40. height=20. />
            </Animated.View>
          </View>
        | _ => React.null
        }}
      </View>
    </View>
  </ErrorBoundary>
}
