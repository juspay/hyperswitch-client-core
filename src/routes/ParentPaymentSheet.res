@react.component
let make = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let (clientData, _, _) = React.useContext(
    AllApiDataContextNew.allApiDataContext,
  )
  let {sheetType} = React.useContext(DynamicFieldsContext.dynamicFieldsContext)

  let (tabArr, elementArr, giftCardArr) = AllApiDataModifier.usePaymentMethodModifier()

  let localeObject = GetLocale.useGetLocalObj()

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

  React.useEffect1(() => {
    let hasNoSavedMethods = switch clientData {
    | Some(data) => data.customer_payment_methods->Array.length === 0
    | None => false
    }
    if hasNoSavedMethods {
      setIsSavedPaymentScreen(false)
    }
    None
  }, [clientData])

  let isLoading = React.useMemo2(() => {
    if nativeProp.configuration.allowsDelayedPaymentMethods {
      !(clientData->Option.isSome)
    } else {
      confirmButtonData.loading
    }
  }, (clientData, confirmButtonData))

  <FullScreenSheetWrapper
    isSavedPaymentScreen
    isLoading
    renderScrollView={!(isSavedPaymentScreen && displayInSeparateScreen)}
    stickyFooter=?{nativeProp.configuration.stickyPayButton
      ? Some(<GlobalConfirmButton confirmButtonData />)
      : None}>
    {switch sheetType {
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
        <PaymentSheet
          setConfirmButtonData
          isLoading={confirmButtonData.loading &&
          clientData->Option.isNone}
          tabArr
          elementArr
          giftCardArr
        />
      | (PaymentSheet, false)
      | (WidgetPaymentSheet, false)
      | (HostedCheckout, false)
      | (WidgetTabSheet, false)
      | (TabSheet, false) =>
        switch clientData->Option.map(data =>
          data.customer_payment_methods
        ) {
        | Some(customerPaymentMethods) =>
          let showSavedScreen =
            customerPaymentMethods->Array.length > 0 &&
              clientData
              ->Option.map(data => data.intent_data.payment_type)
              ->Option.getOr(NORMAL) !== SETUP_MANDATE
          <>
            {isSavedPaymentScreen && showSavedScreen
              ? <SavedPaymentSheet
                  customerPaymentMethods
                  setConfirmButtonData
                  merchantName={clientData
                  ->Option.map(data => data.intent_data.merchant_name)
                  ->Option.getOr(nativeProp.configuration.merchantDisplayName)}
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
        | None => <InitialLoader />
        }
      | _ => React.null
      }
    | DynamicFieldsSheet => <DynamicComponent setConfirmButtonData />
    }}
    <UIUtils.RenderIf condition={!nativeProp.configuration.stickyPayButton}>
      <GlobalConfirmButton confirmButtonData />
    </UIUtils.RenderIf>
  </FullScreenSheetWrapper>
}
