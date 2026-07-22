open ReactNative
open Style

@react.component
let make = (~setConfirmButtonData, ~style=empty, ~isActive=false, ~setIsActive: bool => unit) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let {clientData} = AllApiDataContextNew.useData()

  let {
    bgColor,
    component,
    borderRadius,
    borderWidth,
    shadowConfig,
  } = ThemebasedStyle.useThemeBasedStyle()
  let getShadowStyle = ShadowHook.useGetShadowStyle(~shadowConfig, ())

  <UIUtils.RenderIf
    condition={nativeProp.configuration.paymentMethodLayout.savedMethodCustomization.groupingBehavior.displayInSeparateSection &&
    !nativeProp.configuration.paymentMethodLayout.savedMethodCustomization.groupingBehavior.displayInSeparateScreen}>
    <UIUtils.RenderIf condition={clientData.customer_payment_methods->Array.length > 0}>
      <Space />
      <View
        style={array([
          bgColor,
          getShadowStyle,
          s({
            borderWidth,
            borderColor: component.borderColor,
            borderRadius,
            paddingHorizontal: 8.->dp,
          }),
          style,
        ])}>
        <TextWrapper
          text="Saved"
          textType=CardTextBold
          overrideStyle={Some(s({marginTop: 16.->dp, marginBottom: 4.->dp, marginLeft: 12.->dp}))}
        />
        <SavedPaymentSheet
          isScreenFocus=isActive
          setIsScreenFocus=setIsActive
          customerPaymentMethods=clientData.customer_payment_methods
          setConfirmButtonData
          merchantName=clientData.intent_data.merchant_name
          animated=true
        />
      </View>
    </UIUtils.RenderIf>
  </UIUtils.RenderIf>
}
