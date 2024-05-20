open ReactNative
open Style
@react.component
let make = (~setConfirmButtonDataRef) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let (sessionData, _) = React.useContext(SessionContext.sessionContext)
  //getting payment list data here
  let {tabArr, elementArr} = PMListModifier.useListModifier()
  let (allApiData, _) = React.useContext(AllApiDataContext.allApiDataContext)

  let (savedPaymentMethodsData, _) = React.useContext(
    SavedPaymentMethodContext.savedPaymentMethodContext,
  )
  let savedPaymentMethodsData = switch savedPaymentMethodsData {
  | Some(data) => data

  | _ => SavedPaymentMethodContext.dafaultsavePMObj
  }
  let localeObject = GetLocale.useGetLocalObj()

  <>
    <WalletView
      loading={nativeProp.sdkState !== CardWidget && sessionData == Loading}
      elementArr
      showDisclaimer={allApiData.mandateType->PaymentUtils.showWalletDisclaimerMessage}
    />
    <CustomTabView
      hocComponentArr=tabArr loading={sessionData == Loading} setConfirmButtonDataRef
    />
    <View style={viewStyle(~paddingHorizontal=20.->dp, ())}>
      {PaymentUtils.showUseExisitingSavedCardsBtn(
        ~isGuestCustomer=savedPaymentMethodsData.isGuestCustomer,
        ~pmList=savedPaymentMethodsData.pmList,
        ~mandateType=allApiData.mandateType,
        ~displaySavedPaymentMethods=nativeProp.configuration.displaySavedPaymentMethods,
      )
        ? <>
            <Space height=16. />
            <ClickableTextElement
              initialIconName="cardv1"
              text=localeObject.useExisitingSavedCards
              isSelected=true
              setIsSelected={_ => ()}
              textType={TextWrapper.TextActive}
              fillIcon=true
            />
            <Space height=25. />
          </>
        : React.null}
    </View>
  </>
}
