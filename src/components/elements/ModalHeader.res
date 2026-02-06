open ReactNative
open Style

@react.component
let make = (~onModalClose, ~isLoading=false) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let {sheetType, setSheetType} = React.useContext(DynamicFieldsContext.dynamicFieldsContext)
  let {iconColor} = ThemebasedStyle.useThemeBasedStyle()

  <View
    style={s({
      display: #flex,
      flexGrow: ?(ReactNative.Platform.os !== #web ? Some(1.) : None),
      flexDirection: #row,
      alignItems: #center,
      justifyContent: #"space-between",
    })}
  >
    {if sheetType !== ButtonSheet {
      <CustomPressable
        style={s({maxWidth: 60.->pct, flexDirection: #row, alignItems: #center})}
        onPress={_ => setSheetType(ButtonSheet)}
      >
        <Icon name="back" fill="#000" />
        <Space width=5. />
        <TextWrapper text={"Back"} textType={ModalTextBold} />
      </CustomPressable>
    } else if isLoading {
      <View />
    } else {
      switch nativeProp.configuration.paymentSheetHeaderText {
      | Some(var) =>
        <View style={s({maxWidth: 60.->pct})}>
          <TextWrapper text={var} textType={HeadingBold} />
        </View>
      | _ => <View />
      }
    }}
    <View
      style={s({flexDirection: #row, flexWrap: #wrap, alignItems: #center, maxWidth: 40.->pct})}
    >
      {isLoading
        ? <CustomLoader width="60" height="20" />
        : <>
            {nativeProp.env === GlobalVars.PROD
              ? React.null
              : <View
                  style={s({
                    backgroundColor: "#ffdd93",
                    marginHorizontal: 5.->dp,
                    padding: 5.->dp,
                    borderRadius: 5.,
                  })}
                >
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
