open ReactNative
open Style

type screenState = Loading | Loaded | ErrorState

/*
 * Payment Methods Management renders in two shapes:
 *
 *   - Bottom sheet (SdkTypes.PaymentMethodsManagement) — SDK-owned surface:
 *     dimmed dismissible backdrop + rounded sheet chrome + header with close,
 *     and an SDK-owned "Save card" CTA pinned at the bottom (we control it).
 *
 *   - Embedded widget (SdkTypes.WidgetPaymentMethodsManagement) — lives inside
 *     the merchant's own layout, wherever and however tall they place it.
 *     The SDK imposes NO chrome: no confirm CTA (the merchant's own button,
 *     anywhere in their layout, triggers the save via `confirmTokenization()`,
 *     landing here as a CONFIRM_PAYMENT_ACTION widget event) and no pinned
 *     bars — the list and the add-entry simply flow as scrollable content.
 */

module PmmSheetHeader = {
  @react.component
  let make = (~onClose: unit => unit) => {
    let {component, iconColor} = ThemebasedStyle.useThemeBasedStyle()
    <View
      style={s({
        flexDirection: #row,
        alignItems: #center,
        justifyContent: #"space-between",
        padding: 16.->dp,
        borderBottomWidth: 0.8,
        borderBottomColor: component.borderColor,
      })}>
      <TextWrapper text={"Saved payment methods"} textType={HeadingBold} />
      <CustomPressable onPress={_ => onClose()}>
        <Icon name="close" width=16. height=16. fill=iconColor />
      </CustomPressable>
    </View>
  }
}

@react.component
let make = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let {component, paymentSheetOverlay} = ThemebasedStyle.useThemeBasedStyle()
  let insets = SafeAreaContext.useSafeAreaInsets()
  let fetchPaymentMethodSessionList = PaymentMethodSessionHooks.useFetchPaymentMethodSessionList()
  let updateSavedPaymentMethod = PaymentMethodSessionHooks.useUpdateSavedPaymentMethod()
  let localeObject = GetLocale.useGetLocalObj()
  let handleSuccessFailure = AllPaymentHooks.useHandleSuccessFailure()
  let notifyValidationFailure = UseWidgetActions.useNotifyValidationFailure()

  let isWidget = nativeProp.sdkState == SdkTypes.WidgetPaymentMethodsManagement

  let (screenState, setScreenState) = React.useState(_ => Loading)
  let (paymentMethodsEnabled, setPaymentMethodsEnabled) = React.useState((_): array<
    PaymentMethodSessionTypes.paymentMethodEnabled,
  > => [])
  let (savedMethods, setSavedMethods) = React.useState((_): array<
    PaymentMethodSessionTypes.customerPaymentMethod,
  > => [])
  let (isAddScreen, setIsAddScreen) = React.useState(_ => false)

  let (selectedToken, setSelectedToken) = React.useState(_ => "")
  let (manageToken, setManageToken) = React.useState(_ => "")

  let (cvcNumber, setCvcNumber) = React.useState(_ => "")
  let (cvcError, setCvcError) = React.useState((_): option<string> => None)
  let (isCvcSubmitting, setIsCvcSubmitting) = React.useState(_ => false)

  let (isAddSaving, setIsAddSaving) = React.useState(_ => false)

  let selectedSavedMethod = savedMethods->Array.find(pm => pm.payment_method_token == selectedToken)
  let selectedCardBrand =
    selectedSavedMethod
    ->Option.flatMap(pm => pm.card)
    ->Option.map(card => card.card_network)
    ->Option.getOr("")

  let showCvcCta =
    manageToken == "" && selectedSavedMethod->Option.map(pm => pm.requires_cvv)->Option.getOr(false)
  let isCvcValid = Validation.checkCardCVC(cvcNumber, selectedCardBrand)
  let cardEntrySupported =
    paymentMethodsEnabled->Array.some(item => item.payment_method_type == "card")

  let validateCvc = (): option<string> =>
    cvcNumber == ""
      ? Some(localeObject.cvcNumberEmptyText)
      : isCvcValid
      ? None
      : Some(localeObject.inCompleteCVCErrorText)

  let handleCvcConfirm = _ => {
    setIsCvcSubmitting(_ => true)
    let cardDetails =
      [("card_cvc", cvcNumber->JSON.Encode.string)]->Dict.fromArray->JSON.Encode.object
    updateSavedPaymentMethod(~paymentMethodToken=selectedToken, ~cardDetails)
    ->Promise.then(res => {
      setIsCvcSubmitting(_ => false)
      if res->ErrorUtils.isError || res == JSON.Encode.null {
        handleSuccessFailure(
          ~apiResStatus={
            type_: "payment_method_session",
            status: "failed",
            code: "",
            message: ErrorUtils.getErrorMessage(res),
          },
          (),
        )
      } else {
        let dict = res->Utils.getDictFromJson
        handleSuccessFailure(
          ~apiResStatus={
            type_: "payment_method_session",
            status: dict->Utils.getString("status", "succeeded"),
            code: "",
            message: dict->Utils.getString("status", "Card updated successfully"),
          },
          (),
        )
      }
      Promise.resolve()
    })
    ->ignore
  }

  let addConfirmRef: React.ref<option<unit => unit>> = React.useRef(None)

  let confirmActionRef: React.ref<unit => unit> = React.useRef(() => ())
  confirmActionRef.current = _ =>
    if isAddScreen {
      addConfirmRef.current->Option.map(save => save())->Option.getOr()
    } else if showCvcCta {
      switch validateCvc() {
      | None => handleCvcConfirm()
      | Some(error) => {
          setCvcError(_ => Some(error))
          notifyValidationFailure()
        }
      }
    } else {
      notifyValidationFailure()
    }

  React.useEffect0(() => {
    if isWidget {
      let unsubscribe = NativeEventListener.setupWidgetActionListener(~onWidgetAction=(
        actionData: NativeModulesType.widgetActionData,
      ) => {
        switch actionData.actionType {
        | ConfirmPayment =>
          if actionData.rootTag == nativeProp.rootTag {
            confirmActionRef.current()
          }
        | ConfirmCvcPayment => ()
        }
      })
      Some(unsubscribe)
    } else {
      None
    }
  })

  let loadSavedMethods = () => {
    fetchPaymentMethodSessionList()
    ->Promise.then(res => {
      if res->ErrorUtils.isError || res == JSON.Encode.null {
        setScreenState(_ => ErrorState)
      } else {
        let data = res->PaymentMethodSessionTypes.itemToObjMapper
        setPaymentMethodsEnabled(_ => data.payment_methods_enabled)
        setSavedMethods(_ => data.customer_payment_methods)
        setSelectedToken(_ =>
          data.customer_payment_methods
          ->Array.get(0)
          ->Option.map(pm => pm.payment_method_token)
          ->Option.getOr("")
        )
        setScreenState(_ => Loaded)
      }
      Promise.resolve()
    })
    ->Promise.catch(_ => {
      setScreenState(_ => ErrorState)
      Promise.resolve()
    })
    ->ignore
  }

  React.useEffect0(() => {
    loadSavedMethods()
    None
  })

  React.useEffect2(() => {
    if screenState == Loaded && savedMethods->Array.length == 0 {
      setIsAddScreen(_ => true)
    }
    None
  }, (screenState, savedMethods))

  let handleSelectItem = (paymentMethodToken: string) => {
    setSelectedToken(_ => paymentMethodToken)
    setManageToken(_ => "")
    setCvcError(_ => None)
  }

  let onCvcBlur = _ => {
    if cvcNumber != "" && !isCvcValid {
      setCvcError(_ => Some(localeObject.inCompleteCVCErrorText))
    }
  }

  let handleManageItem = (paymentMethodToken: string) => {
    setSelectedToken(_ => paymentMethodToken)
    setManageToken(_ => paymentMethodToken)
  }

  let removeFromList = (paymentMethodToken: string) => {
    let remaining = savedMethods->Array.filter(pm => pm.payment_method_token != paymentMethodToken)
    if selectedToken == paymentMethodToken {
      setSelectedToken(_ =>
        remaining->Array.get(0)->Option.map(pm => pm.payment_method_token)->Option.getOr("")
      )
    }
    if manageToken == paymentMethodToken {
      setManageToken(_ => "")
    }
    setSavedMethods(_ => remaining)
  }

  let updateInList = (paymentMethodToken: string, cardHolderName: string, nickName: string) => {
    setSavedMethods(prev =>
      prev->Array.map(pm =>
        pm.payment_method_token == paymentMethodToken
          ? {
              ...pm,
              card: pm.card->Option.map(
                card => {
                  ...card,
                  card_holder_name: cardHolderName == "" ? None : Some(cardHolderName),
                  nick_name: nickName == "" ? None : Some(nickName),
                },
              ),
            }
          : pm
      )
    )
    if manageToken == paymentMethodToken {
      setManageToken(_ => "")
    }
  }

  let saveCta =
    <View
      style={s({
        paddingHorizontal: 24.->dp,
        paddingVertical: 16.->dp,
        backgroundColor: component.background,
      })}>
      <CustomButton
        text={"Save card"}
        loadingText="Saving"
        buttonState={isAddSaving || isCvcSubmitting ? LoadingButton : Normal}
        onPress={_ =>
          if isAddScreen {
            addConfirmRef.current->Option.map(save => save())->Option.getOr()
          } else {
            switch validateCvc() {
            | None => handleCvcConfirm()

            | Some(error) => setCvcError(_ => Some(error))
            }
          }}
      />
    </View>

  let onModalClose = _ =>
    handleSuccessFailure(
      ~apiResStatus=PaymentConfirmTypes.defaultCancelError,
      ~closeSDK=true,
      ~reset=false,
      (),
    )

  let body = switch screenState {
  | Loading =>
    <View
      style={s({
        width: 100.->pct,
        minHeight: 120.->dp,
        justifyContent: #center,
        alignItems: #center,
      })}>
      <TextWrapper text={"Loading ..."} textType={CardText} />
    </View>
  | ErrorState =>
    <View
      style={s({
        width: 100.->pct,
        paddingVertical: 24.->dp,
        paddingHorizontal: 24.->dp,
        alignItems: #center,
      })}>
      <TextWrapper text={"No saved payment methods available."} textType={ModalTextLight} />
    </View>
  | Loaded =>
    <>
      {isAddScreen
        ? <AddPaymentMethodCardScreen
            paymentMethodsEnabled
            showBackButton={savedMethods->Array.length > 0}
            onBack={_ => setIsAddScreen(_ => false)}
            addConfirmRef
            onInvalidSubmit={isWidget ? notifyValidationFailure : _ => ()}
            setIsSaving=setIsAddSaving
            fillHeight=isWidget
          />
        : <ScrollView
            keyboardShouldPersistTaps=#handled
            style={s(isWidget ? {flexGrow: 1.} : {flexShrink: 1.})}>
            {savedMethods
            ->Array.map(item => {
              <PaymentMethodListItem
                key={item.payment_method_token}
                pmDetails=item
                isActive={item.payment_method_token == selectedToken}
                isManageModeActive={item.payment_method_token == manageToken}
                onSelect=handleSelectItem
                onManage=handleManageItem
                onUpdated=updateInList
                onDeleted=removeFromList
                cvcNumber
                setCvcNumber
                cvcError
                setCvcError
                onCvcBlur
              />
            })
            ->React.array}
            {isWidget
              ? <PaymentMethodListItem.AddPaymentMethodButton
                  onPress={_ => setIsAddScreen(_ => true)}
                />
              : React.null}
            <Space height=16. />
          </ScrollView>}
      {isWidget
        ? React.null
        : <View
            style={s({
              borderTopWidth: 0.8,
              borderColor: component.borderColor,
              backgroundColor: component.background,
            })}>
            {isAddScreen
              ? React.null
              : <PaymentMethodListItem.AddPaymentMethodButton
                  onPress={_ => setIsAddScreen(_ => true)}
                />}
            {(isAddScreen && cardEntrySupported) || (!isAddScreen && showCvcCta)
              ? saveCta
              : React.null}
          </View>}
    </>
  }

  isWidget
  // Widget: merchant layout hosts the content; NO SDK confirm CTA.
    ? <View
        style={s({
          backgroundColor: component.background,
          height: 100.->pct,
          flexDirection: #column,
        })}>
        {body}
      </View>
      // Bottom sheet: dimmed backdrop + rounded chrome + SDK-owned CTA.
    : <View
        style={s({
          flex: 1.,
          alignContent: #"flex-end",
          backgroundColor: paymentSheetOverlay,
          justifyContent: #"flex-end",
          paddingTop: (insets.top +. SafeAreaContext.topGap)->dp,
        })}>
        <CustomView onDismiss=onModalClose>
          <View
            style={s({
              flexShrink: 1.,
              width: 100.->pct,
              maxHeight: 100.->pct,
              backgroundColor: component.background,
            })}>
            <PmmSheetHeader onClose={_ => onModalClose()} />
            {body}
          </View>
        </CustomView>
      </View>
}
