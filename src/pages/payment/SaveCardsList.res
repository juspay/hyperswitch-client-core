open ReactNative
open Style
// @send external focus: ReactNative.CustomTouchableOpacity.ref => unit = "focus"

module CVVComponent = {
  @react.component
  let make = (~savedCardCvv, ~setSavedCardCvv, ~isPaymentMethodSelected, ~cardScheme) => {
    let {component, dangerColor} = ThemebasedStyle.useThemeBasedStyle()

    React.useEffect1(() => {
      setSavedCardCvv(_ => None)
      None
    }, [isPaymentMethodSelected])

    let (isCvcFocus, setIsCvcFocus) = React.useState(_ => false)

    let isCvcValid =
      isCvcFocus || savedCardCvv->Option.isNone
        ? true
        : savedCardCvv->Option.getOr("")->String.length > 0 &&
            Validation.cvcNumberInRange(savedCardCvv->Option.getOr(""), cardScheme)

    let localeObject = GetLocale.useGetLocalObj()

    let errorMsgText = !isCvcValid ? Some(localeObject.inCompleteCVCErrorText) : None

    let onCvvChange = cvv => setSavedCardCvv(_ => Some(Validation.formatCVCNumber(cvv, cardScheme)))

    {
      isPaymentMethodSelected
        ? <>
            <View
              style={viewStyle(
                ~display=#flex,
                ~flexDirection=#row,
                ~alignItems=#center,
                ~paddingHorizontal=40.->dp,
                ~marginTop=10.->dp,
                (),
              )}>
              <View style={viewStyle(~width={50.->dp}, ())}>
                <TextWrapper text="CVC:" textType={ModalText} />
              </View>
              <CustomInput
                state={isPaymentMethodSelected ? savedCardCvv->Option.getOr("") : ""}
                setState={isPaymentMethodSelected ? onCvvChange : _ => ()}
                placeholder="123"
                fontSize=12.
                keyboardType=#"number-pad"
                enableCrossIcon=false
                width={100.->dp}
                height=40.
                isValid={isPaymentMethodSelected ? isCvcValid : true}
                onFocus={() => {
                  setIsCvcFocus(_ => true)
                }}
                onBlur={() => {
                  setIsCvcFocus(_ => false)
                }}
                secureTextEntry=true
                textColor={isCvcValid ? component.color : dangerColor}
                iconRight=CustomIcon({
                  Validation.checkCardCVC(savedCardCvv->Option.getOr(""), cardScheme)
                    ? <Icon name="cvvfilled" height=35. width=35. fill="black" />
                    : <Icon name="cvvempty" height=35. width=35. fill="black" />
                })
              />
            </View>
            {errorMsgText->Option.isSome && isPaymentMethodSelected
              ? <ErrorText text=errorMsgText />
              : React.null}
          </>
        : React.null
    }
  }
}
module PMWithNickNameComponent = {
  @react.component
  let make = (~pmDetails: SdkTypes.savedDataType) => {
    let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
    let nickName = switch pmDetails {
    | SAVEDLISTCARD(obj) => obj.nick_name
    | _ => None
    }
    let isDefaultPm = switch pmDetails {
    | SAVEDLISTCARD(obj) => obj.isDefaultPaymentMethod
    | SAVEDLISTWALLET(obj) => obj.isDefaultPaymentMethod
    | NONE => Some(false)
    }->Option.getOr(false)

    <View style={viewStyle(~display=#flex, ~flexDirection=#column, ())}>
      {switch nickName {
      | Some(val) =>
        val != ""
          ? <View style={viewStyle(~display=#flex, ~flexDirection=#row, ~alignItems=#center, ())}>
              <TextWrapper
                text={val->String.length > 15
                  ? val->String.slice(~start=0, ~end=13)->String.concat("..")
                  : val}
                textType={CardTextBold}
              />
              <Space height=5. />
              {nativeProp.configuration.displayDefaultSavedPaymentIcon && isDefaultPm
                ? <Icon name="defaultTick" height=14. width=14. fill="black" />
                : React.null}
            </View>
          : React.null
      | None => React.null
      }}
      <View style={viewStyle(~display=#flex, ~flexDirection=#row, ~alignItems=#center, ())}>
        <Icon
          name={switch pmDetails {
          | SAVEDLISTCARD(obj) => obj.cardScheme
          | SAVEDLISTWALLET(obj) => obj.walletType
          | NONE => None
          }->Option.getOr("")}
          height=24.
          width=24.
          style={viewStyle(~marginEnd=5.->dp, ())}
        />
        <TextWrapper
          text={switch pmDetails {
          | SAVEDLISTWALLET(obj) => obj.walletType
          | SAVEDLISTCARD(obj) => obj.cardNumber
          | NONE => None
          }
          ->Option.getOr("")
          ->String.replaceAll("*", "●")}
          textType={switch pmDetails {
          | SAVEDLISTWALLET(_) => CardTextBold
          | _ => CardText
          }}
        />
      </View>
    </View>
  }
}

module PaymentMethodListView = {
  @react.component
  let make = (
    ~pmObject: SdkTypes.savedDataType,
    ~isButtomBorder=true,
    ~savedCardCvv,
    ~setSavedCardCvv,
    ~setIsCvcValid,
  ) => {
    //~hashedCardNumber, ~expDate, ~selectedx
    let localeObj = GetLocale.useGetLocalObj()
    let (allApiData, setAllApiData) = React.useContext(AllApiDataContext.allApiDataContext)
    let savedPaymentMethordContextObj = switch allApiData.savedPaymentMethods {
    | Some(data) => data
    | _ => AllApiDataContext.dafaultsavePMObj
    }

    let checkAndProcessIfWallet = (~newToken) => {
      switch newToken {
      | None =>
        setAllApiData({
          ...allApiData,
          savedPaymentMethods: Some({
            ...savedPaymentMethordContextObj,
            selectedPaymentMethod: None,
          }),
        })
      | Some(_) =>
        switch pmObject {
        | SdkTypes.SAVEDLISTCARD(_) =>
          setAllApiData({
            ...allApiData,
            savedPaymentMethods: Some({
              ...savedPaymentMethordContextObj,
              selectedPaymentMethod: Some({
                walletName: NONE,
                token: newToken,
              }),
            }),
          })
        | SdkTypes.SAVEDLISTWALLET(obj) => {
            let walletType = obj.walletType->Option.getOr("")->SdkTypes.walletNameToTypeMapper
            setAllApiData({
              ...allApiData,
              savedPaymentMethods: Some({
                ...savedPaymentMethordContextObj,
                selectedPaymentMethod: Some({
                  walletName: walletType,
                  token: newToken,
                }),
              }),
            })
          }
        | _ => ()
        }
      }
    }

    let {primaryColor, component} = ThemebasedStyle.useThemeBasedStyle()

    let pmToken = switch pmObject {
    | SdkTypes.SAVEDLISTCARD(obj) =>
      obj.mandate_id->Option.isSome
        ? obj.mandate_id->Option.getOr("")
        : obj.payment_token->Option.getOr("")
    | SdkTypes.SAVEDLISTWALLET(obj) => obj.payment_token->Option.getOr("")
    | NONE => ""
    }

    let onPress = () => {
      checkAndProcessIfWallet(~newToken={Some(pmToken)})
    }

    let preSelectedObj = savedPaymentMethordContextObj.selectedPaymentMethod->Option.getOr({
      walletName: NONE,
      token: None,
    })

    let isPaymentMethodSelected = switch preSelectedObj.token {
    | Some(val) => val == pmToken
    | None => false
    }

    let cardScheme = switch pmObject {
    | SdkTypes.SAVEDLISTCARD(card) => card.cardScheme->Option.getOr("")
    | _ => "NotCard"
    }

    React.useEffect2(() => {
      if isPaymentMethodSelected {
        setIsCvcValid(_ =>
          switch cardScheme {
          | "NotCard" => true
          | _ =>
            switch savedCardCvv {
            | Some(cvv) => cvv->String.length > 0 && Validation.cvcNumberInRange(cvv, cardScheme)
            | None => !(pmObject->PaymentUtils.checkIsCVCRequired)
            }
          }
        )
      }
      None
    }, (isPaymentMethodSelected, savedCardCvv))

    <CustomTouchableOpacity
      onPress={_ => {
        onPress()
      }}
      style={viewStyle(
        ~minHeight=60.->dp,
        ~paddingVertical=16.->dp,
        ~borderBottomWidth={isButtomBorder ? 0.8 : 0.},
        ~borderBottomColor=component.borderColor,
        ~justifyContent=#center,
        (),
      )}
      activeOpacity=0.7>
      <View
        style={viewStyle(
          ~flexDirection=#row,
          ~flexWrap=#wrap,
          ~alignItems=#center,
          ~justifyContent=#"space-between",
          (),
        )}>
        <View style={viewStyle(~flexDirection=#row, ~alignItems=#center, ~maxWidth=60.->pct, ())}>
          <CustomRadioButton
            size=20.5
            selected=isPaymentMethodSelected
            color=primaryColor
            // selected={selectedToken->Option.isSome
            //   ? selectedToken->Option.getOr("") == cardToken
            //   : false}
          />
          <Space />
          <PMWithNickNameComponent pmDetails=pmObject />
        </View>
        {switch pmObject {
        | SAVEDLISTCARD(obj) =>
          <TextWrapper
            text={localeObj.cardExpiresText ++ " " ++ obj.expiry_date->Option.getOr("")}
            textType={ModalTextLight}
          />
        | SAVEDLISTWALLET(_) | NONE => React.null
        }}
      </View>
      {pmObject->PaymentUtils.checkIsCVCRequired
        ? <CVVComponent savedCardCvv setSavedCardCvv isPaymentMethodSelected cardScheme />
        : React.null}
    </CustomTouchableOpacity>
  }
}
