@react.component
let make = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let (accountPaymentMethodData, customerPaymentMethodData, sessionTokenData, sdkConfigData) = React.useContext(
    AllApiDataContextNew.allApiDataContext,
  )
  let {sheetType} = React.useContext(DynamicFieldsContext.dynamicFieldsContext)

  let (tabArr, elementArr, giftCardArr) = AllApiDataModifier.useAccountPaymentMethodModifier()

  let localeObject = GetLocale.useGetLocalObj()

  let displayInSeparateScreen = nativeProp.configuration.paymentMethodLayout.savedMethodCustomization.groupingBehavior.displayInSeparateScreen
  let shouldShowSavedPaymentMethods = PaymentUtils.shouldShowSavedPaymentMethods(
    ~sdkConfigData,
    ~sessionTokenData,
  )

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

  React.useEffect2(() => {
    if (
      accountPaymentMethodData->Option.isSome && (
          nativeProp.configuration.allowsDelayedPaymentMethods
            ? customerPaymentMethodData->Option.isNone
            : customerPaymentMethodData
              ->Option.map(data => data.customer_payment_methods->Array.length === 0)
              ->Option.getOr(true)
        )
    ) {
      setIsSavedPaymentScreen(false)
    }
    None
  }, (customerPaymentMethodData, accountPaymentMethodData))

  let isLoading = React.useMemo3(() => {
    if nativeProp.configuration.allowsDelayedPaymentMethods {
      !(accountPaymentMethodData->Option.isSome || customerPaymentMethodData->Option.isSome)
    } else {
      confirmButtonData.loading
    }
  }, (accountPaymentMethodData, customerPaymentMethodData, confirmButtonData))

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
        !nativeProp.configuration.displaySavedPaymentMethods ||
        !displayInSeparateScreen ||
        !shouldShowSavedPaymentMethods,
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
          accountPaymentMethodData->Option.isNone &&
          customerPaymentMethodData->Option.isNone}
          tabArr
          elementArr
          giftCardArr
        />
      | (PaymentSheet, false)
      | (WidgetPaymentSheet, false)
      | (HostedCheckout, false)
      | (WidgetTabSheet, false)
      | (TabSheet, false) =>
        switch customerPaymentMethodData->Option.map(customerPaymentMethods =>
          customerPaymentMethods.customer_payment_methods
        ) {
        | Some(customerPaymentMethods) =>
          let showSavedScreen =
            customerPaymentMethods->Array.length > 0 &&
              shouldShowSavedPaymentMethods &&
              accountPaymentMethodData
              ->Option.map(data => data.payment_type)
              ->Option.getOr(NORMAL) !== SETUP_MANDATE
          <>
            {isSavedPaymentScreen && showSavedScreen
              ? <SavedPaymentSheet
                  customerPaymentMethods
                  setConfirmButtonData
                  merchantName={accountPaymentMethodData
                  ->Option.map(data => data.merchant_name)
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
            {showSavedScreen ||
            (nativeProp.configuration.allowsDelayedPaymentMethods &&
            accountPaymentMethodData->Option.isSome)
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
        | None =>
          nativeProp.configuration.allowsDelayedPaymentMethods &&
          accountPaymentMethodData->Option.isSome
            ? {
                <PaymentSheet
                  setConfirmButtonData
                  isLoading=confirmButtonData.loading
                  tabArr
                  elementArr
                  giftCardArr
                />
              }
            : <InitialLoader />
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
