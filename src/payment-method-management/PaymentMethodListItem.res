open ReactNative
open Style

module AddPaymentMethodButton = {
  @react.component
  let make = (~onPress: unit => unit) => {
    let localeObject = GetLocale.useGetLocalObj()

    // Payments parity (SavedCardToggleTab + ClickableTextElement): the
    // link-coloured "addwithcircle" icon + LinkTextBold label the payment sheet
    // uses right under its saved-cards box — borderless, no separators.
    <View style={s({paddingTop: 12.->dp, paddingBottom: 4.->dp, paddingHorizontal: 24.->dp})}>
      <ClickableTextElement
        initialIconName="addwithcircle"
        text=localeObject.addPaymentMethodLabel
        isSelected=false
        setIsSelected={_ => onPress()}
        textType={TextWrapper.LinkTextBold}
        size=24.
      />
    </View>
  }
}

module PaymentMethodTitle = {
  @react.component
  let make = (
    ~pmDetails: PaymentMethodSessionTypes.customerPaymentMethod,
    ~isManageModeActive: bool,
  ) => {
    let nickName = pmDetails.card->Option.flatMap(card => card.nick_name)->Option.getOr("")

    <View style={s({flex: 1.})}>
      {nickName != ""
        ? <>
            <TextWrapper
              text={nickName} textType={CardTextBold} ellipsizeMode=#tail numberOfLines={1}
            />
            <Space height=5. />
          </>
        : React.null}
      {isManageModeActive
        ? React.null
        : <>
            <TextWrapper
              text={pmDetails.card
              ->Option.map(card => "●●●● "->String.concat(card.last4_digits))
              ->Option.getOr("")}
              textType=CardText
            />
            {switch pmDetails.card {
            | Some(card) =>
              card.expiry_month != ""
                ? <TextWrapper
                    text={`Expiry ${card.expiry_month} / ${card.expiry_year->CommonUtils.twoDigitYear}`}
                    textType=CardText
                  />
                : React.null
            | None => React.null
            }}
          </>}
    </View>
  }
}

@react.component
let make = (
  ~pmDetails: PaymentMethodSessionTypes.customerPaymentMethod,
  ~isActive: bool,
  ~isManageModeActive: bool,
  ~onSelect: string => unit,
  ~onManage: string => unit,
  ~onUpdated: (string, string, string) => unit,
  ~onDeleted: string => unit,
  ~cvcNumber: string,
  ~setCvcNumber: (string => string) => unit,
  ~cvcError=None,
  ~setCvcError=_ => (),
  ~onCvcBlur=() => (),
  ~isLast: bool=false,
) => {
  let {component, primaryColor, dangerColor, inputHeight} = ThemebasedStyle.useThemeBasedStyle()
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let localeObject = GetLocale.useGetLocalObj()
  let deletePaymentMethod = PaymentMethodSessionHooks.useDeletePaymentMethodSession()
  let updateSavedPaymentMethod = PaymentMethodSessionHooks.useUpdateSavedPaymentMethod()

  let (isUpdating, setIsUpdating) = React.useState(_ => false)
  let (cardHolderName, setCardHolderName) = React.useState(_ =>
    pmDetails.card->Option.flatMap(card => card.card_holder_name)->Option.getOr("")
  )
  let (nickName, setNickName) = React.useState(_ =>
    pmDetails.card->Option.flatMap(card => card.nick_name)->Option.getOr("")
  )

  let cardBrand = pmDetails.card->Option.map(card => card.card_network)->Option.getOr("")
  let showCvcField = isActive && pmDetails.requires_cvv && !isManageModeActive

  let isCardExpired = switch pmDetails.card {
  | Some(card) =>
    card.expiry_year != "" &&
    card.expiry_month != "" && {
      let expiryDate = Date.fromString(`${card.expiry_year}-${card.expiry_month}`)
      // A saved card stays usable through its whole expiry month, so compare
      // against the start of the following month (same as payments saved cards).
      expiryDate->Date.setMonth(expiryDate->Date.getMonth + 1)
      expiryDate->Date.getTime < Date.make()->Date.getTime
    }
  | None => false
  }

  let handleDelete = _ => {
    deletePaymentMethod(~paymentMethodToken=pmDetails.payment_method_token)
    ->Promise.then(res => {
      if res->ErrorUtils.isError || res == JSON.Encode.null {
        ()
      } else {
        onDeleted(pmDetails.payment_method_token)
      }
      Promise.resolve()
    })
    ->ignore
  }

  let handleUpdate = _ => {
    setIsUpdating(_ => true)
    let cardDetails =
      [
        ("card_holder_name", cardHolderName->JSON.Encode.string),
        ("nick_name", nickName->JSON.Encode.string),
      ]
      ->Dict.fromArray
      ->JSON.Encode.object
    updateSavedPaymentMethod(~paymentMethodToken=pmDetails.payment_method_token, ~cardDetails)
    ->Promise.then(res => {
      setIsUpdating(_ => false)
      if res->ErrorUtils.isError || res == JSON.Encode.null {
        ()
      } else {
        onUpdated(pmDetails.payment_method_token, cardHolderName, nickName)
      }
      Promise.resolve()
    })
    ->ignore
  }

  <View
    style={s({
      padding: 16.->dp,
      // Rows sit inside a bordered container; only separators between rows.
      borderBottomWidth: isLast ? 0. : 0.8,
      borderBottomColor: component.borderColor,
    })}>
    <CustomPressable onPress={_ => onSelect(pmDetails.payment_method_token)}>
      <View style={s({flexDirection: #row, flexWrap: #nowrap, alignItems: #center})}>
        <View style={s({opacity: isCardExpired ? 0.7 : 1.})}>
          <CustomRadioButton selected=isActive color=primaryColor />
        </View>
        <Space width=12. />
        <Icon name=cardBrand height=36. width=36. style={s({marginEnd: 5.->dp})} />
        <View style={s({flex: 1., opacity: isCardExpired ? 0.7 : 1.})}>
          <PaymentMethodTitle pmDetails isManageModeActive />
        </View>
        {isManageModeActive
          ? isActive
              ? <>
                  <CustomPressable onPress=handleUpdate disabled=isUpdating>
                    <TextWrapper text={isUpdating ? "Saving ..." : "Save"} textType=LinkText />
                  </CustomPressable>
                  <CustomPressable onPress=handleDelete style={s({marginStart: 16.->dp})}>
                    <Icon name={"delete-hollow"} height=18. width=18. />
                  </CustomPressable>
                </>
              : React.null
          : <CustomPressable onPress={_ => onManage(pmDetails.payment_method_token)}>
              <Icon name={"manage"} height=18. width=18. />
            </CustomPressable>}
      </View>
    </CustomPressable>
    {showCvcField
      ? {
          let hideCvcIcon =
            nativeProp.configuration.paymentMethodLayout.savedMethodCustomization.cvcIcon === Hidden
          <View
            style={s({
              display: #flex,
              flexDirection: #column,
              alignItems: #"flex-start",
              marginTop: 12.->dp,
              marginStart: 32.->dp,
            })}>
            <View
              style={s({display: #flex, flexDirection: #row, alignItems: #center, flex: 1.})}>
              <View style={s({width: 50.->dp})}>
                <TextWrapper text="CVC:" textType={ModalText} />
              </View>
              <CustomInput
                state=cvcNumber
                setState={val => {
                  setCvcError(_ => None)
                  setCvcNumber(_ => val->Validation.formatCVCNumber(cardBrand))
                }}
                placeholder="123"
                animateLabel="CVC"
                keyboardType=#"number-pad"
                enableCrossIcon=false
                maxLength={Some(4)}
                isValid={cvcError->Option.isNone}
                secureTextEntry=true
                textColor={cvcError->Option.isNone ? component.color : dangerColor}
                width={(hideCvcIcon ? 72. : 100.)->dp}
                height={inputHeight *. 0.9}
                onFocus={_ => setCvcError(_ => None)}
                onBlur={_ => onCvcBlur()}
                iconRight=?{hideCvcIcon
                  ? None
                  : Some(
                      CustomInput.CustomIcon(
                        Validation.checkCardCVC(cvcNumber, cardBrand)
                          ? <Icon name="cvvfilled" height=35. width=35. fill="black" />
                          : <Icon name="cvvempty" height=35. width=35. fill="black" />,
                      ),
                    )}
              />
            </View>
            <ErrorText text=cvcError />
          </View>
        }
      : React.null}
    {isCardExpired
      ? <>
          <Space height=6. />
          <TextWrapper
            text={`*${localeObject.cardExpiredText}`}
            textType={CardText}
            overrideStyle={Some(s({fontStyle: #italic, opacity: 0.7}))}
          />
        </>
      : React.null}
    {isManageModeActive && isActive
      ? <View style={s({marginTop: 12.->dp})}>
          <View style={s({flexDirection: #row, flexWrap: #nowrap})}>
            <View style={s({flex: 1.})}>
              <CustomInput
                state={pmDetails.card
                ->Option.map(card => `**** **** **** ${card.last4_digits}`)
                ->Option.getOr("")}
                setState={_ => ()}
                placeholder=localeObject.cardNumberLabel
                editable=false
                enableCrossIcon=false
              />
            </View>
            <Space width=10. />
            <View style={s({flex: 1.})}>
              <CustomInput
                state={pmDetails.card
                ->Option.map(card => `${card.expiry_month} / ${card.expiry_year->CommonUtils.twoDigitYear}`)
                ->Option.getOr("")}
                setState={_ => ()}
                placeholder=localeObject.validThruText
                editable=false
                enableCrossIcon=false
              />
            </View>
          </View>
          <Space height=10. />
          <CustomInput
            state=cardHolderName
            setState={val => setCardHolderName(_ => val)}
            placeholder=localeObject.cardHolderName
            enableCrossIcon=false
          />
          <Space height=10. />
          <CustomInput
            state=nickName
            setState={val => setNickName(_ => val)}
            placeholder=localeObject.nicknamePlaceholder
            maxLength={Some(12)}
            enableCrossIcon=false
          />
        </View>
      : React.null}
  </View>
}
