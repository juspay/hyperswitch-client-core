@react.component
let make = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let (accountPaymentMethodData, customerPaymentMethodData, _) = React.useContext(
    AllApiDataContextNew.allApiDataContext,
  )
  let {sheetType, upiData, setSheetType} = React.useContext(
    DynamicFieldsContext.dynamicFieldsContext,
  )

  let (tabArr, elementArr, giftCardArr) = AllApiDataModifier.useAccountPaymentMethodModifier()
  let localeObject = GetLocale.useGetLocalObj()

  let (isSavedPaymentScreen, setIsSavedPaymentScreen) = React.useState(_ => true)
  let setIsSavedPaymentScreen = React.useCallback1(isSaved => {
    setIsSavedPaymentScreen(_ => isSaved)
  }, [setIsSavedPaymentScreen])

  let (confirmButtonData, setConfirmButtonData) = React.useState(_ =>
    GlobalConfirmButton.defaultConfirmButtonData
  )
  let setConfirmButtonData = React.useCallback1(confirmButtonData => {
    setConfirmButtonData(_ => confirmButtonData)
  }, [setConfirmButtonData])

  let handleUpiAppSelect = uri => {
    setSheetType(UpiTimerSheet)
  }

  let (_, setLoading) = React.useContext(LoadingContext.loadingContext)
  let handleSuccessFailure = AllPaymentHooks.useHandleSuccessFailure()

  let responseCallback = (~paymentStatus: LoadingContext.sdkPaymentState, ~status) => {
    switch paymentStatus {
    | PaymentSuccess => {
        setLoading(PaymentSuccess)
        setTimeout(() => {
          handleSuccessFailure(~apiResStatus=status, ())
        }, 300)->ignore
      }
    | _ => handleSuccessFailure(~apiResStatus=status, ())
    }
  }

  let errorCallback = (~errorMessage: PaymentConfirmTypes.error, ~closeSDK, ()) => {
    if !closeSDK {
      setLoading(FillingDetails)
    }
    handleSuccessFailure(~apiResStatus=errorMessage, ~closeSDK, ())
  }

  let shortPollUpiStatus = UpiPollingHooks.useUpiPolling()(~responseCallback, ~errorCallback)

  React.useEffect3(() => {
    switch sheetType {
    | UpiTimerSheet | UpiQrSheet =>
      switch (upiData.pollConfig, upiData.displayToTimestamp) {
      | (Some(config), Some(maxTimestamp)) =>
        let now = Date.now()
        let endTime = maxTimestamp /. 1_000_000.

        if now < endTime {
          let timeoutId = setTimeout(() => {
            shortPollUpiStatus(~pollConfig=config, ~pollCount=0, ~displayToTimestamp=maxTimestamp)
          }, config.delay_in_secs * 1000)

          Some(() => clearTimeout(timeoutId))
        } else {
          errorCallback(
            ~errorMessage={
              PaymentConfirmTypes.status: "failed",
              message: "Payment timeout - maximum time exceeded",
              code: "",
              type_: "",
            },
            ~closeSDK=true,
            (),
          )
          None
        }
      | _ => None
      }
    | _ => None
    }
  }, (sheetType, upiData.pollConfig, upiData.displayToTimestamp))

  <FullScreenSheetWrapper isLoading={confirmButtonData.loading}>
    {switch sheetType {
    | UpiAppSelectionSheet =>
      <UpiAppListScreen
        sdkUri={upiData.sdkUri->Option.getOr("")} onAppSelect={handleUpiAppSelect}
      />
    | UpiTimerSheet =>
      <UpiTimerScreen
        displayFromTimestamp={upiData.displayFromTimestamp->Option.getOr(0.)}
        displayToTimestamp={upiData.displayToTimestamp->Option.getOr(0.)}
      />
    | UpiQrSheet =>
      <UpiQrScreen
        qrDataUrl={upiData.sdkUri->Option.getOr("")}
        displayFromTimestamp={upiData.displayFromTimestamp->Option.getOr(0.)}
        displayToTimestamp={upiData.displayToTimestamp->Option.getOr(0.)}
      />
    | ButtonSheet =>
      switch (
        nativeProp.sdkState,
        !nativeProp.configuration.displaySavedPaymentMethods ||
        nativeProp.configuration.displayMergedSavedMethods,
      ) {
      | (PaymentSheet, true)
      | (WidgetPaymentSheet, true)
      | (HostedCheckout, true)
      | (TabSheet, true)
      | (WidgetTabSheet, true)
      | (ButtonSheet, _)
      | (WidgetButtonSheet, _) =>
        <>
          <PaymentSheet
            setConfirmButtonData isLoading=confirmButtonData.loading tabArr elementArr giftCardArr
          />
          <Space />
        </>
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
                  <Space />
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
    <UIUtils.RenderIf
      condition={sheetType !== UpiAppSelectionSheet &&
      sheetType !== UpiTimerSheet &&
      sheetType !== UpiQrSheet}>
      <GlobalConfirmButton confirmButtonData />
    </UIUtils.RenderIf>
    <Space height=15. />
  </FullScreenSheetWrapper>
}
