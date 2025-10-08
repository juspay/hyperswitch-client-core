@react.component
let make = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let (accountPaymentMethodData, customerPaymentMethodData, _) = React.useContext(
    AllApiDataContextNew.allApiDataContext,
  )
  let {sheetType} = React.useContext(DynamicFieldsContext.dynamicFieldsContext)

  let (tabArr, elementArr) = AllApiDataModifier.useAccountPaymentMethodModifier()
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

  <FullScreenSheetWrapper isLoading=confirmButtonData.loading>
    {switch sheetType {
    | ButtonSheet =>
      switch (
        nativeProp.sdkState,
        !nativeProp.configuration.displaySavedPaymentMethods ||
        nativeProp.configuration.displayMergedSavedMethods,
      ) {
      | (PaymentSheet, true)
      | (WidgetPaymentSheet, true)
      | (TabSheet, true)
      | (WidgetTabSheet, true)
      | (ButtonSheet, _)
      | (WidgetButtonSheet, _) =>
        <PaymentSheet setConfirmButtonData isLoading=confirmButtonData.loading tabArr elementArr />
      | (PaymentSheet, false)
      | (WidgetPaymentSheet, false)
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
                />
              : <PaymentSheet
                  setConfirmButtonData isLoading=confirmButtonData.loading tabArr elementArr
                />}
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
                    size={isSavedPaymentScreen ? 16. : 24.}
                  />
                  <Space height=12. />
                </>
              : React.null}
          </>
        | None => <SavedPaymentSheetLoader />
        }
      | _ => React.null
      }
    | DynamicFieldsSheet => <DynamicComponent setConfirmButtonData />
    }}
    <GlobalConfirmButton confirmButtonData />
    <Space height=15. />
  </FullScreenSheetWrapper>
}
