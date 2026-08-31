module SheetContent = {
  @react.component
  let make = (
    ~isSavedPaymentScreen,
    ~setIsSavedPaymentScreen,
    ~confirmButtonData: GlobalConfirmButton.confirmButtonData,
    ~setConfirmButtonData,
  ) => {
    let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
    let {clientData} = AllApiDataContextNew.useData()
    let {sheetType} = React.useContext(DynamicFieldsContext.dynamicFieldsContext)

    let (tabArr, elementArr, giftCardArr) = AllApiDataModifier.usePaymentMethodModifier()

    let localeObject = GetLocale.useGetLocalObj()

    let displayInSeparateScreen = nativeProp.configuration.paymentMethodLayout.savedMethodCustomization.groupingBehavior.displayInSeparateScreen

    React.useEffect1(() => {
      if clientData.customer_payment_methods->Array.length === 0 {
        setIsSavedPaymentScreen(false)
      }
      None
    }, [clientData])

    switch sheetType {
    | ButtonSheet =>
      switch (
        nativeProp.sdkState,
        !nativeProp.configuration.displaySavedPaymentMethods || !displayInSeparateScreen,
      ) {
      | (PaymentSheet, true)
      | (WidgetPaymentSheet, true)
      | (HostedCheckout, true)
      | (TabSheet, true)
      | (WidgetTabSheet, true)
      | (ButtonSheet, _)
      | (WidgetButtonSheet, _) =>
        <PaymentSheet setConfirmButtonData isLoading=false tabArr elementArr giftCardArr />
      | (PaymentSheet, false)
      | (WidgetPaymentSheet, false)
      | (HostedCheckout, false)
      | (WidgetTabSheet, false)
      | (TabSheet, false) =>
        let customerPaymentMethods = clientData.customer_payment_methods
        let showSavedScreen =
          customerPaymentMethods->Array.length > 0 &&
            clientData.intent_data.payment_type !== SETUP_MANDATE
        <>
          {isSavedPaymentScreen && showSavedScreen
            ? <SavedPaymentSheet
                customerPaymentMethods
                setConfirmButtonData
                merchantName=clientData.intent_data.merchant_name
                maxVisibleItems=6
                animated=true
              />
            : <PaymentSheet
                setConfirmButtonData
                isLoading=confirmButtonData.loading
                tabArr
                elementArr
                giftCardArr
              />}
          <Space height=5. />
          {showSavedScreen
            ? <>
                <Space height=5. />
                <ClickableTextElement
                  initialIconName="addwithcircle"
                  updateIconName={Some("cardv1")}
                  text={isSavedPaymentScreen
                    ? localeObject.addPaymentMethodLabel
                    : localeObject.useExisitingSavedCards}
                  isSelected=isSavedPaymentScreen
                  setIsSelected=setIsSavedPaymentScreen
                  textType={TextWrapper.LinkTextBold}
                  size=24.
                />
                <Space height=5. />
              </>
            : React.null}
        </>
      | _ => React.null
      }
    | DynamicFieldsSheet => <DynamicComponent setConfirmButtonData />
    }
  }
}

@react.component
let make = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let allApiData = AllApiDataContextNew.useOptionalData()

  let displayInSeparateScreen = nativeProp.configuration.paymentMethodLayout.savedMethodCustomization.groupingBehavior.displayInSeparateScreen

  let (isSavedPaymentScreen, setIsSavedPaymentScreen) = React.useState(_ => displayInSeparateScreen)
  let setIsSavedPaymentScreen = React.useCallback1(isSaved => {
    setIsSavedPaymentScreen(_ => isSaved)
  }, [setIsSavedPaymentScreen])

  let (confirmButtonData, setConfirmButtonData) = React.useState(_ =>
    GlobalConfirmButton.defaultConfirmButtonData
  )
  let setConfirmButtonData = React.useCallback1(confirmButtonData => {
    setConfirmButtonData(_ => confirmButtonData)
  }, [setConfirmButtonData])

  UseWidgetActions.useWidgetActions(~confirmButtonData)

  let isLoading = React.useMemo2(() => {
    if nativeProp.configuration.allowsDelayedPaymentMethods {
      !(allApiData->Option.isSome)
    } else {
      confirmButtonData.loading
    }
  }, (allApiData, confirmButtonData))

  <FullScreenSheetWrapper
    isSavedPaymentScreen
    isLoading
    renderScrollView={!(isSavedPaymentScreen && displayInSeparateScreen)}
    stickyFooter=?{nativeProp.configuration.stickyPayButton
      ? Some(<GlobalConfirmButton confirmButtonData />)
      : None}>
    {switch allApiData {
    | Some(_) =>
      <SheetContent
        isSavedPaymentScreen setIsSavedPaymentScreen confirmButtonData setConfirmButtonData
      />
    | None => <InitialLoader />
    }}
    <UIUtils.RenderIf condition={!nativeProp.configuration.stickyPayButton}>
      <GlobalConfirmButton confirmButtonData />
    </UIUtils.RenderIf>
  </FullScreenSheetWrapper>
}
