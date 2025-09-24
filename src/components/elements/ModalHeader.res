open ReactNative
open Style

@react.component
let make = (~onModalClose) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let {iconColor} = ThemebasedStyle.useThemeBasedStyle()
  let (paymentScreenType, _) = React.useContext(PaymentScreenContext.paymentScreenTypeContext)
  let (allApiData, _) = React.useContext(AllApiDataContext.allApiDataContext)
  let (localStrings, _) = React.useContext(LocaleStringDataContext.localeDataContext)
  let isLoadingScreenActive = switch (allApiData.savedPaymentMethods, localStrings) {
  | (Loading, _) | (_, Loading) => true
  | _ => false
  }

  <View
    style={s({
      display: #flex,
      flexGrow: ?(ReactNative.Platform.os !== #web ? Some(1.) : None),
      flexDirection: #row,
      alignItems: #center,
      justifyContent: #"space-between",
    })}>
    {if isLoadingScreenActive {
      <View />
    } else {
      switch switch paymentScreenType {
      | PaymentScreenContext.PAYMENTSHEET => nativeProp.configuration.paymentSheetHeaderText
      | PaymentScreenContext.SAVEDCARDSCREEN =>
        nativeProp.configuration.savedPaymentScreenHeaderText
      } {
      | Some(var) =>
        <View style={s({maxWidth: 60.->pct})}>
          <TextWrapper text={var} textType={HeadingBold} />
        </View>
      | _ => <View />
      }
    }}
    <View
      style={s({flexDirection: #row, flexWrap: #wrap, alignItems: #center, maxWidth: 40.->pct})}>
      {isLoadingScreenActive
        ? React.null
        : <>
            {nativeProp.env === GlobalVars.PROD
              ? React.null
              : <View
                  style={s({
                    backgroundColor: "#ffdd93",
                    marginHorizontal: 5.->dp,
                    padding: 5.->dp,
                    borderRadius: 5.,
                  })}>
                  <TextWrapper
                    textType={ModalTextBold}
                    text="Test Mode"
                    overrideStyle=Some(s({color: "black"}))
                  />
                </View>}
            <CustomPressable onPress={_ => onModalClose()}>
              <Icon name="close" width=16. height=16. fill=iconColor />
            </CustomPressable>
          </>}
    </View>
  </View>
}
