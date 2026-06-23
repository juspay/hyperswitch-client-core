open ReactNative
open Style

@react.component
let make = (~setConfirmButtonData, ~style=empty, ~isActive=false, ~setIsActive: bool => unit) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let (accountPaymentMethodData, customerPaymentMethodData, _, _) = React.useContext(
    AllApiDataContextNew.allApiDataContext,
  )

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
    {switch customerPaymentMethodData {
    | Some(customerPaymentMethods) =>
      <UIUtils.RenderIf
        condition={customerPaymentMethods.customer_payment_methods->Array.length > 0}>
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
            customerPaymentMethods=customerPaymentMethods.customer_payment_methods
            setConfirmButtonData
            merchantName={accountPaymentMethodData
            ->Option.map(data => data.merchant_name)
            ->Option.getOr(nativeProp.configuration.merchantDisplayName)}
            animated=true
          />
        </View>
      </UIUtils.RenderIf>
    | None => React.null
    }}
  </UIUtils.RenderIf>
}
