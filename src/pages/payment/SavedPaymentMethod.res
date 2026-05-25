open ReactNative
open Style
open PaymentEvents

module CVVComponent = {
  @react.component
  let make = (
    ~savedCardCvv,
    ~setSavedCardCvv,
    ~cardScheme,
    ~hideCardExpiry,
    ~hideCVCError,
    ~hideCvcIcon,
    ~placeholderCVC,
  ) => {
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

    <View
      style={s({
        display: #flex,
        flexDirection: #column,
        alignItems: hideCardExpiry ? #"flex-end" : #"flex-start",
        marginHorizontal: hideCardExpiry ? 7.5->dp : 47.5->dp,
      })}>
      <View
        style={s({
          flex: 1.,
          display: #flex,
          flexDirection: #row,
          alignItems: #center,
          width: ?(hideCardExpiry ? None : Some(100.->pct)),
          marginTop: hideCardExpiry
            ? (errorMsgText->Option.isSome && !hideCVCError ? 2. : 0.)->dp
            : 10.->dp,
        })}>
        {hideCardExpiry
          ? React.null
          : <View style={s({width: {50.->dp}})}>
              <TextWrapper text="CVC:" textType={ModalText} />
            </View>}
        <CustomInput
          state={savedCardCvv->Option.getOr("")}
          setState={onCvvChange}
          placeholder={hideCardExpiry
            ? placeholderCVC->Option.getOr(localeObject.cvcTextLabel)
            : "123"}
          animateLabel="CVC"
          keyboardType=#"number-pad"
          enableCrossIcon=false
          width={(hideCvcIcon ? 72. : 100.)->dp}
          isValid={isCvcValid}
          onFocus={() => {
            setIsCvcFocus(_ => true)
          }}
          onBlur={() => {
            setIsCvcFocus(_ => false)
          }}
          secureTextEntry=true
          textColor={isCvcValid ? component.color : dangerColor}
          iconRight=?{hideCvcIcon
            ? None
            : Some(
                CustomIcon({
                  Validation.checkCardCVC(savedCardCvv->Option.getOr(""), cardScheme)
                    ? <Icon name="cvvfilled" height=35. width=35. fill="black" />
                    : <Icon name="cvvempty" height=35. width=35. fill="black" />
                }),
              )}
        />
      </View>
      {errorMsgText->Option.isSome && !hideCVCError ? <ErrorText text=errorMsgText /> : React.null}
    </View>
  }
}
module PMWithNickNameComponent = {
  @react.component
  let make = (
    ~savedPaymentMethod: CustomerPaymentMethodType.customer_payment_method_type,
    ~isPaymentMethodSelected,
  ) => {
    let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
    let {component, iconColor, primaryColor, logoConfig} = ThemebasedStyle.useThemeBasedStyle()
    let logoConfig = nativeProp.configuration.paymentMethodLayout.savedMethodCustomization.groupingBehavior.displayInSeparateSection
      ? logoConfig
      : None

    let nickName = switch savedPaymentMethod.card {
    | Some(card) => card.nick_name
    | _ => None
    }
    let isDefaultPm = savedPaymentMethod.default_payment_method_set

    <View style={s({display: #flex, flexDirection: #column})}>
      {switch (nickName, logoConfig->Option.isNone) {
      | (Some(val), true) =>
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
      | _ => React.null
      }}
      <View style={s({display: #flex, flexDirection: #row, alignItems: #center})}>
        {switch logoConfig {
        | Some(config) =>
          <View
            style={s({
              backgroundColor: config.colors.backgroundColor,
              padding: 10.->dp,
              borderRadius: config.borderRadius,
              position: #relative,
            })}>
            <Icon
              name={switch savedPaymentMethod.card {
              | Some(card) =>
                switch card.card_network {
                | "" =>
                  card.scheme === ""
                    ? savedPaymentMethod.payment_method_type->CommonUtils.getDisplayName
                    : card.scheme
                | card_network => card_network
                }
              | None => savedPaymentMethod.payment_method_type->CommonUtils.getDisplayName
              }}
              height=18.
              width=18.
              fill={isPaymentMethodSelected ? primaryColor : iconColor}
            />
            {switch (
              isPaymentMethodSelected &&
              nativeProp.configuration.paymentMethodLayout.showCheckedIconForSelection,
              config.checkedIconForSelection->Option.getOr(
                ThemebasedStyle.defaultCheckedIconForSelection,
              ),
            ) {
            | (true, checkedIconConfig) =>
              <Icon
                name="selected"
                width=checkedIconConfig.size
                height=checkedIconConfig.size
                fill=checkedIconConfig.color
                stroke={checkedIconConfig.stroke->Option.getOr(component.background)}
                style={s({
                  position: #absolute,
                  bottom: checkedIconConfig.bottom->dp,
                  right: checkedIconConfig.right->dp,
                })}
              />
            | _ => React.null
            }}
          </View>
        | None =>
          <Icon
            name={switch savedPaymentMethod.card {
            | Some(card) =>
              switch card.card_network {
              | "" =>
                card.scheme === ""
                  ? savedPaymentMethod.payment_method_type->CommonUtils.getDisplayName
                  : card.scheme
              | card_network => card_network
              }
            | None => savedPaymentMethod.payment_method_type->CommonUtils.getDisplayName
            }}
            height=26.
            width=26.
            fill={isPaymentMethodSelected ? primaryColor : iconColor}
          />
        }}
        <Space width=8. />
        <View style={s({flexDirection: #column})}>
          {switch (nickName, logoConfig->Option.isNone) {
          | (Some(val), false) =>
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
          | _ => React.null
          }}
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
        ])}>
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
    ~setIsScreenFocus,
  ) => {
    let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
    let hideCardExpiry = nativeProp.configuration.paymentMethodLayout.savedMethodCustomization.hideCardExpiry
    let localeObj = GetLocale.useGetLocalObj()
    let {primaryColor, component, logoConfig} = ThemebasedStyle.useThemeBasedStyle()
    let logoConfig = nativeProp.configuration.paymentMethodLayout.savedMethodCustomization.groupingBehavior.displayInSeparateSection
      ? logoConfig
      : None
    let emitter = PaymentEvents.usePaymentEventEmitter()

    <CustomPressable
      onPress={_ => {
        if !isPaymentMethodSelected {
          setSavedCardCvv(_ => None)
        }
        setSelectedToken(Some(savedPaymentMethod))
        setIsScreenFocus(true)
        let event = PaymentEvents.buildPaymentMethodStatusEvent(
          ~paymentMethod=savedPaymentMethod.payment_method_str,
          ~paymentMethodType=savedPaymentMethod.payment_method_type,
          ~isSavedPaymentMethod=true,
        )
        emitter.emitPaymentMethodStatus(~event)
      }}
      style={s({
        minHeight: 60.->dp,
        paddingVertical: (hideCardExpiry ? 5. : 16.)->dp,
        // borderBottomWidth: {
        //   isButtomBorder ? 1.0 : 0.
        // },
        borderBottomColor: component.borderColor,
        justifyContent: #center,
      })}>
      <View
        style={s({
          flex: 1.,
          flexDirection: #row,
          flexWrap: #wrap,
          alignItems: #center,
          justifyContent: #"space-between",
          paddingLeft: 12.->dp,
          gap: 8.->dp,
        })}>
        <View style={s({flexDirection: #row, alignItems: #center, flex: 1., height: 100.->pct})}>
          {logoConfig->Option.isNone
            ? <CustomRadioButton size=20.5 selected=isPaymentMethodSelected color=primaryColor />
            : React.null}
          {logoConfig->Option.isNone ? <Space /> : React.null}
          <PMWithNickNameComponent savedPaymentMethod isPaymentMethodSelected />
        </View>
        {switch (hideCardExpiry, savedPaymentMethod.card) {
        | (true, _) =>
          isPaymentMethodSelected &&
          savedPaymentMethod.payment_method === CARD &&
          savedPaymentMethod.requires_cvv
            ? <CVVComponent
                savedCardCvv
                setSavedCardCvv
                cardScheme={savedPaymentMethod.card
                ->Option.map(card => card.card_network)
                ->Option.getOr("")}
                hideCardExpiry
                hideCVCError=nativeProp.configuration.paymentMethodLayout.savedMethodCustomization.hideCVCError
                hideCvcIcon={nativeProp.configuration.paymentMethodLayout.savedMethodCustomization.cvcIcon ===
                  Hidden}
                placeholderCVC={nativeProp.configuration.placeholder.cvv}
              />
            : React.null
        | (false, Some(card)) =>
          <TextWrapper
            text={`${localeObj.cardExpiresText} ${card.expiry_month}/${card.expiry_year->String.sliceToEnd(
                ~start=-2,
              )}`}
            textType={ModalTextLight}
            overrideStyle={Some(
              s({
                marginLeft: auto,
                // alignSelf: #center,
              }),
            )}
          />
        | _ => React.null
        }}
      </View>
      {isPaymentMethodSelected &&
      savedPaymentMethod.payment_method === CARD &&
      savedPaymentMethod.requires_cvv &&
      !hideCardExpiry
        ? <CVVComponent
            savedCardCvv
            setSavedCardCvv
            cardScheme={savedPaymentMethod.card
            ->Option.map(card => card.card_network)
            ->Option.getOr("")}
            hideCardExpiry
            hideCVCError=nativeProp.configuration.paymentMethodLayout.savedMethodCustomization.hideCVCError
            hideCvcIcon={nativeProp.configuration.paymentMethodLayout.savedMethodCustomization.cvcIcon ===
              Hidden}
            placeholderCVC={nativeProp.configuration.placeholder.cvv}
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
  ~setIsScreenFocus,
) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let (showMore, setShowMore) = React.useState(_ => !animated)

  let displayInSeparateScreen = nativeProp.configuration.paymentMethodLayout.savedMethodCustomization.groupingBehavior.displayInSeparateScreen

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
        setIsScreenFocus
      />
    })
    ->React.array

  let content =
    <>
      {savedPaymentMethods}
      <UIUtils.RenderIf
        condition={customerPaymentMethods->Array.length > maxVisibleItems && showMore}>
        <MoreButton
          handleMoreToggle={() => {
            setIsScreenFocus(true)
            setShowMore(_ => false)
          }}
        />
      </UIUtils.RenderIf>
    </>

  let fadeAnim = React.useRef(Animated.Value.create(1.0))
  let bounceAnim = React.useRef(Animated.Value.create(0.0))
  let (isScrollable, setIsScrollable) = React.useState(() => false)

  React.useEffect1(() => {
    if isScrollable {
      let bounce = Animated.loop(
        Animated.sequence([
          Animated.timing(
            bounceAnim.current,
            {
              toValue: 6.0->Animated.Value.Timing.fromRawValue,
              duration: 1000.,
              useNativeDriver: true,
              easing: Easing.ease,
            },
          ),
          Animated.timing(
            bounceAnim.current,
            {
              toValue: 0.0->Animated.Value.Timing.fromRawValue,
              duration: 1000.,
              useNativeDriver: true,
            },
          ),
        ]),
      )
      bounce->Animated.start(~endCallback=_ => ())

      Some(() => bounce->Animated.stop)
    } else {
      None
    }
  }, [isScrollable])

  let handleScroll = (event: Event.scrollEvent) => {
    let contentOffsetY = event.nativeEvent.contentOffset.y
    let contentHeight = event.nativeEvent.contentSize.height
    let layoutHeight = event.nativeEvent.layoutMeasurement.height

    let atBottom = layoutHeight +. contentOffsetY >= contentHeight -. 20.0

    if contentOffsetY > 50.0 || atBottom {
      Animated.timing(
        fadeAnim.current,
        {
          toValue: 0.0->Animated.Value.Timing.fromRawValue,
          duration: 300.,
          useNativeDriver: true,
        },
      )->Animated.start(~endCallback=_ => ())
    } else {
      Animated.timing(
        fadeAnim.current,
        {
          toValue: 1.0->Animated.Value.Timing.fromRawValue,
          duration: 300.,
          useNativeDriver: true,
        },
      )->Animated.start(~endCallback=_ => ())
    }
  }

  let handleContentSizeChange = (_width, height) => {
    setIsScrollable(_ => height > (displayInSeparateScreen ? 600. : 240.))
  }

  animated
    ? <View style={ReactNative.Platform.os === #web ? s({flex: 1.}) : empty}>
        <ScrollView
          keyboardShouldPersistTaps=#handled
          showsVerticalScrollIndicator=false
          nestedScrollEnabled={true}
          onScroll={handleScroll}
          scrollEventThrottle={16}
          onContentSizeChange={handleContentSizeChange}
          style={s({
            maxHeight: ?(displayInSeparateScreen ? None : Some(240.->dp)),
          })}
          contentContainerStyle={s({
            paddingHorizontal: ?(
              displayInSeparateScreen ||
              nativeProp.configuration.paymentMethodLayout.layoutType === Tabs
                ? Some(16.->dp)
                : None
            ),
          })}>
          {content}
        </ScrollView>
        {isScrollable
          ? <Animated.Text
              style={s({
                opacity: fadeAnim.current->Animated.StyleProp.float,
                transform: [translateY(~translateY=bounceAnim.current->Animated.StyleProp.size)],
                position: #absolute,
                bottom: (
                  nativeProp.configuration.paymentMethodLayout.savedMethodCustomization.groupingBehavior.displayInSeparateScreen
                    ? 10.
                    : nativeProp.configuration.paymentMethodLayout.savedMethodCustomization.groupingBehavior.displayInSeparateSection
                    ? 8.
                    : nativeProp.configuration.paymentMethodLayout.layoutType === Tabs
                    ? 10.
                    : -2.
                )->dp,
                alignSelf: #center,
                color: "#aaa",
                fontSize: 12.,
              })}>
              {"Scroll for more ↓"->React.string}
            </Animated.Text>
          : React.null}
      </View>
    : content
}
