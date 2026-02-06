open ReactNative
open Style

module CVVComponent = {
  @react.component
  let make = (~savedCardCvv, ~setSavedCardCvv, ~cardScheme) => {
    let {component, dangerColor} = ThemebasedStyle.useThemeBasedStyle()

    let (isCvcFocus, setIsCvcFocus) = React.useState(_ => false)

    let isCvcValid =
      isCvcFocus || savedCardCvv->Option.isNone
        ? true
        : savedCardCvv->Option.getOr("")->String.length > 0 &&
            Validation.cvcNumberInRange(savedCardCvv->Option.getOr(""), cardScheme)

    let localeObject = GetLocale.useGetLocalObj()
    let errorMsgText = !isCvcValid ? Some(localeObject.inCompleteCVCErrorText) : None
    let onCvvChange = cvv => setSavedCardCvv(_ => Some(Validation.formatCVCNumber(cvv, cardScheme)))

    <>
      <View
        style={s({
          display: #flex,
          flexDirection: #row,
          alignItems: #center,
          paddingHorizontal: 47.5->dp,
          marginTop: 10.->dp,
        })}
      >
        <View style={s({width: {50.->dp}})}>
          <TextWrapper text="CVC:" textType={ModalText} />
        </View>
        <CustomInput
          state={savedCardCvv->Option.getOr("")}
          setState={onCvvChange}
          placeholder="123"
          animateLabel="CVC"
          fontSize=12.
          keyboardType=#"number-pad"
          enableCrossIcon=false
          width={100.->dp}
          height=40.
          isValid={isCvcValid}
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
      {errorMsgText->Option.isSome
        ? <View
            style={s({
              display: #flex,
              flexDirection: #row,
              alignItems: #center,
              paddingLeft: 100.->dp,
            })}
          >
            <ErrorText text=errorMsgText />
          </View>
        : React.null}
    </>
  }
}
module PMWithNickNameComponent = {
  @react.component
  let make = (~savedPaymentMethod: CustomerPaymentMethodType.customer_payment_method_type) => {
    let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
    let nickName = switch savedPaymentMethod.card {
    | Some(card) => card.nick_name
    | _ => None
    }
    let isDefaultPm = savedPaymentMethod.default_payment_method_set

    <View style={s({display: #flex, flexDirection: #column})}>
      {switch nickName {
      | Some(val) =>
        val != ""
          ? <View style={s({display: #flex, flexDirection: #row, alignItems: #center})}>
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
      <View style={s({display: #flex, flexDirection: #row, alignItems: #center})}>
        <Icon
          name={switch savedPaymentMethod.card {
          | Some(card) => card.card_network
          | None => savedPaymentMethod.payment_method_type->CommonUtils.getDisplayName
          }}
          height=26.
          width=26.
        />
        <Space width=8. />
        <TextWrapper
          text={switch savedPaymentMethod.card {
          | Some(card) => "●●●● "->String.concat(card.last4_digits)
          | None => savedPaymentMethod.payment_method_type->CommonUtils.getDisplayName
          }}
          textType={switch savedPaymentMethod.card {
          | Some(_) => CardText
          | None => CardTextBold
          }}
        />
      </View>
    </View>
  }
}

module MoreButton = {
  @react.component
  let make = (~handleMoreToggle) => {
    let {component, borderRadius, linkColor} = ThemebasedStyle.useThemeBasedStyle()

    <View style={s({flex: 1., alignItems: #center, justifyContent: #center})}>
      <CustomPressable
        onPress={_ => handleMoreToggle()}
        style={array([
          s({
            width: 100.->pct,
            flexDirection: #row,
            alignItems: #center,
            justifyContent: #"flex-start",
            borderColor: component.borderColor,
            minWidth: 115.->dp,
            paddingHorizontal: 14.->dp,
            paddingVertical: 20.->dp,
            borderRadius,
          }),
        ])}
      >
        <ChevronIcon width=12. height=12. fill=linkColor />
        <Space height=5. />
        <TextWrapper text="Show More" textType=LinkText />
      </CustomPressable>
    </View>
  }
}

module PaymentMethodListView = {
  @react.component
  let make = (
    ~savedPaymentMethod: CustomerPaymentMethodType.customer_payment_method_type,
    ~isButtomBorder=true,
    ~savedCardCvv,
    ~setSavedCardCvv,
    ~isPaymentMethodSelected,
    ~setSelectedToken,
  ) => {
    let localeObj = GetLocale.useGetLocalObj()
    let {primaryColor, component} = ThemebasedStyle.useThemeBasedStyle()

    <CustomPressable
      onPress={_ => {
        if !isPaymentMethodSelected {
          setSavedCardCvv(_ => None)
        }
        setSelectedToken(Some(savedPaymentMethod))
      }}
      style={s({
        minHeight: 60.->dp,
        paddingVertical: 16.->dp,
        borderBottomWidth: {isButtomBorder ? 1.0 : 0.},
        borderBottomColor: component.borderColor,
        justifyContent: #center,
      })}
    >
      <View
        style={s({
          flexDirection: #row,
          flexWrap: #wrap,
          alignItems: #center,
          justifyContent: #"space-between",
          paddingHorizontal: 12.->dp,
          gap: 8.->dp,
        })}
      >
        <View style={s({flexDirection: #row, alignItems: #center, maxWidth: 60.->pct})}>
          <CustomRadioButton size=20.5 selected=isPaymentMethodSelected color=primaryColor />
          <Space />
          <PMWithNickNameComponent savedPaymentMethod />
        </View>
        {switch savedPaymentMethod.card {
        | Some(card) =>
          <TextWrapper
            text={`${localeObj.cardExpiresText} ${card.expiry_month}/${card.expiry_year->String.sliceToEnd(
                ~start=-2,
              )}`}
            textType={ModalTextLight}
            overrideStyle={Some(s({marginLeft: auto}))}
          />
        | None => React.null
        }}
      </View>
      {isPaymentMethodSelected &&
      savedPaymentMethod.payment_method === CARD &&
      savedPaymentMethod.requires_cvv
        ? <CVVComponent
            savedCardCvv
            setSavedCardCvv
            cardScheme={savedPaymentMethod.card
            ->Option.map(card => card.card_network)
            ->Option.getOr("")}
          />
        : React.null}
    </CustomPressable>
  }
}

@react.component
let make = (
  ~customerPaymentMethods,
  ~selectedToken: option<CustomerPaymentMethodType.customer_payment_method_type>,
  ~setSelectedToken,
  ~savedCardCvv,
  ~setSavedCardCvv,
  ~isScreenFocus as _,
  ~animated,
  ~maxVisibleItems: int=3,
) => {
  let (showMore, setShowMore) = React.useState(_ => true)

  let visiblePaymentMethods = if (
    customerPaymentMethods->Array.length > maxVisibleItems && showMore
  ) {
    customerPaymentMethods->Array.slice(~start=0, ~end=maxVisibleItems)
  } else {
    customerPaymentMethods
  }

  let savedPaymentMethods =
    visiblePaymentMethods
    ->Array.mapWithIndex((savedPaymentMethod, i) => {
      <PaymentMethodListView
        key={savedPaymentMethod.payment_method_id}
        savedPaymentMethod
        isButtomBorder={visiblePaymentMethods->Array.length - 1 === i
          ? customerPaymentMethods->Array.length > maxVisibleItems && showMore
          : true}
        savedCardCvv
        setSavedCardCvv
        isPaymentMethodSelected={selectedToken
        ->Option.map(token => token.payment_method_id === savedPaymentMethod.payment_method_id)
        ->Option.getOr(i === 0)}
        setSelectedToken
      />
    })
    ->React.array

  let content =
    <>
      {savedPaymentMethods}
      <UIUtils.RenderIf
        condition={customerPaymentMethods->Array.length > maxVisibleItems && showMore}
      >
        <MoreButton
          handleMoreToggle={() => {
            setShowMore(_ => false)
          }}
        />
      </UIUtils.RenderIf>
    </>

  animated
    ? <ScrollView keyboardShouldPersistTaps=#handled showsVerticalScrollIndicator=false>
        {content}
      </ScrollView>
    : content
}
