open ReactNative

module Linking = {
  @module("react-native") @scope("Linking")
  external openURL: string => promise<unit> = "openURL"

  @module("react-native") @scope("Linking")
  external canOpenURL: string => promise<bool> = "canOpenURL"
}

let knownUpiApps: array<UpiTypes.upiApp> = [
  {appName: "GPay", urlScheme: "tez://upi/pay"},
  {appName: "PhonePe", urlScheme: "phonepe://pay"},
  {appName: "Paytm", urlScheme: "paytmmp://pay"},
  {appName: "BHIM", urlScheme: "bhim://pay"},
  {appName: "Mobikwik", urlScheme: "mobikwik://upi/pay"},
  {appName: "CRED", urlScheme: "credpay://upi/pay"},
  {appName: "Navi", urlScheme: "navipay://pay"},
  {appName: "Kiwi", urlScheme: "kiwi://upi/pay"},
  {appName: "Moneyview", urlScheme: "mv://upi/upi://pay"},
  {appName: "Super Money", urlScheme: "super://pay"},
]

let getUriSchemeForAppName = (appName: string): option<string> => {
  knownUpiApps
  ->Array.find(app => app.appName === appName)
  ->Option.map(app => app.urlScheme)
}

@react.component
let make = (~sdkUri: string, ~onAppSelect: string => unit) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let {
    payNowButtonColor,
    payNowButtonBorderColor,
    buttonBorderRadius,
    buttonBorderWidth,
  } = ThemebasedStyle.useThemeBasedStyle()
  let (selectedAppIndex, setSelectedAppIndex) = React.useState(_ => None)
  let (availableUpiApps, setAvailableUpiApps) = React.useState(_ => [])
  let (isLoading, setIsLoading) = React.useState(_ => true)

  React.useEffect(() => {
    HyperModule.getInstalledUpiApps(~knownApps=knownUpiApps)
    ->Promise.then(installedApps => {
      Console.log2("[UPI] Detected UPI apps:", installedApps)
      setAvailableUpiApps(_ => installedApps)
      setIsLoading(_ => false)
      Promise.resolve()
    })
    ->Promise.catch(error => {
      Console.error2("Error detecting UPI apps:", error)
      setIsLoading(_ => false)
      Promise.resolve()
    })
    ->ignore

    None
  }, [])

  let handleAppSelect = (appIndex: int) => {
    setSelectedAppIndex(_ => Some(appIndex))
  }

  let handlePayNow = () => {
    selectedAppIndex->Option.forEach(index => {
      availableUpiApps
      ->Array.get(index)
      ->Option.forEach(app => {
        switch getUriSchemeForAppName(app.appName) {
        | Some(uriScheme) =>
          Console.log2("[UPI] Found URI scheme for app:", sdkUri)
          // let sdkUril = "upi://pay?pa=upi@razopay&pn=MWSolutions&tr=IyGdZuu9AghBbD0&tn=razorpay&am=1&cu=INR&mc=5411"
          let appSpecificUri = sdkUri->String.replace("upi://pay", uriScheme)
          Console.log2("[UPI] Opening UPI app:", app.appName)
          Console.log2("[UPI] Package:", app.packageName)
          Console.log2("[UPI] URI:", appSpecificUri)

          HyperModule.openUpiApp(app.packageName, appSpecificUri)
          ->Promise.then(
            success => {
              if success {
                Console.log("[UPI] Successfully opened UPI app")
                onAppSelect(appSpecificUri)
              } else {
                Console.error("[UPI] Failed to open UPI app - app not found or unavailable")
              }
              Promise.resolve()
            },
          )
          ->Promise.catch(
            error => {
              Console.error2("[UPI] Error opening UPI app:", error)
              Promise.resolve()
            },
          )
          ->ignore

        | None => Console.warn2("[UPI] No URI scheme mapping found for app:", app.appName)
        }
      })
    })
  }

  let renderSectionHeader = (~section: AccordionView.accordionSection, ~isExpanded: bool) => {
    let isSelected = selectedAppIndex->Option.mapOr(false, index => index === section.key)
    <CustomAccordionView.SectionHeader section isExpanded=isSelected />
  }

  let renderSectionContent = (~section: AccordionView.accordionSection) => {
    React.null
  }

  let sections = availableUpiApps->Array.mapWithIndex((app, index) => {
    AccordionView.key: index,
    title: app.appName,
    isExpanded: false,
    componentHoc: (~isScreenFocus, ~setConfirmButtonData) => React.null,
  })

  <View style={Style.s({flex: 1.})}>
    <View>
      <Space height=20. />
      {isLoading
        ? <View>
            <CustomLoader />
          </View>
        : availableUpiApps->Array.length === 0
        ? <View style={Style.s({padding: 20.->Style.dp})}>
          <TextWrapper
            text="No UPI apps found. Please install a UPI app to continue." textType={ModalText}
          />
        </View>
        : <AccordionView
            sections
            expandedSections=[]
            onSectionToggle=handleAppSelect
            renderSectionHeader
            renderSectionContent
            // style={Style.s({marginHorizontal: -10.->Style.dp})}
            // sectionStyle={Style.s({marginHorizontal: 10.->Style.dp})}
            allowMultipleExpanded=false
            layout=nativeProp.configuration.appearance.layout
            // style={Style.s({paddingHorizontal: -100.->Style.dp})}
          />}
      <Space height=20. />
      <UIUtils.RenderIf condition={!isLoading}>
        <CustomButton
          text="Pay Now"
          onPress={_ => handlePayNow()}
          backgroundColor={selectedAppIndex->Option.isSome ? payNowButtonColor : "#93BCF6"}
          borderColor=payNowButtonBorderColor
          borderRadius=buttonBorderRadius
          borderWidth=buttonBorderWidth
          buttonType=Primary
          buttonState={selectedAppIndex->Option.isNone ? Disabled : Normal}
        />
      </UIUtils.RenderIf>
    </View>
  </View>
}
