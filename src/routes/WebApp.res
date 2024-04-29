@get external data: ReactEvent.Form.t => string = "data"

module Window = {
  type listener<'ev> = 'ev => unit

  @val @scope(("window", "parent")) @val
  external postMessage: (string, string) => unit = "postMessage"

  @val @scope("window")
  external addEventListener: (string, listener<'ev>) => unit = "addEventListener"
}

open WebSDKThemeType
let getCustomView = vt => {
  switch vt {
  | DROPDOWN(dropdown_val, label) => {
      viewType: "dropdown",
      viewVal: dropdown_val,
      label,
    }
  | COLOR(label) => {
      viewType: "color",
      label,
    }
  | NUMERICVAL(label) => {
      viewType: "numeric",
      label,
    }
  | GRADIENTVAL(label) => {
      viewType: "gradient",
      label,
    }
  }
}

@react.component
let app = (~props) => {
  let (propFromEvent, setPropFromEvent) = React.useState(() => None)
  React.useEffect0(() => {
    let themeBasedStyleObj = {
      platform: getCustomView(DROPDOWN(["ios", "android", "web"], "Plarform")),
      bgColor: getCustomView(COLOR("Background")),
      bgTransparentColor: getCustomView(COLOR("Background Transparent")),
      textPrimary: getCustomView(COLOR("Primary Text")),
      textSecondary: getCustomView(COLOR("Secondry Text")),
      placeholderColor: getCustomView(COLOR("Placeholder")),
      textInputBg: getCustomView(COLOR("Input Text Background")),
      iconColor: getCustomView(COLOR("Icon")),
      lineBorderColor: getCustomView(COLOR("Border")),
      linkColor: getCustomView(COLOR("Link")),
      disableBgColor: getCustomView(COLOR("Disabled Background")),
      filterHeaderColor: getCustomView(COLOR("Header Filter")),
      filterOptionTextColor: getCustomView(COLOR("Filter Option text")),
      tooltipTextColor: getCustomView(COLOR("Tool tip text")),
      tooltipBackgroundColor: getCustomView(COLOR("Tool tip text background")),
      boxColor: getCustomView(COLOR("Box color")),
      boxBorderColor: getCustomView(COLOR("Box border color")),
      dropDownSelectAll: getCustomView(COLOR("Dropdown select all")),
      fadedColor: getCustomView(COLOR("Faded")),
      status_color: getCustomView(COLOR("Status")),
      detailViewToolTipText: getCustomView(COLOR("")),
      summarisedViewSingleStatHeading: getCustomView(COLOR("")),
      switchThumbColor: getCustomView(COLOR("")),
      shimmerColor: getCustomView(COLOR("")),
      lastOffset: getCustomView(COLOR("")),
      dangerColor: getCustomView(COLOR("Error")),
      orderDisableButton: getCustomView(COLOR("")),
      toastColorConfig_backgroundColor: getCustomView(COLOR("")),
      toastColorConfig_textColor: getCustomView(COLOR("")),
      primaryColor: getCustomView(COLOR("colors.primary")),
      borderRadius: getCustomView(NUMERICVAL("Border Radius")),
      borderWidth: getCustomView(NUMERICVAL("Border Width")),
      buttonBorderRadius: getCustomView(COLOR("")),
      component_background: getCustomView(COLOR("Component Background")),
      component_borderColor: getCustomView(COLOR("Component Border")),
      component_dividerColor: getCustomView(COLOR("Component Divider")),
      component_color: getCustomView(COLOR("Component Color")),
      locale: getCustomView(DROPDOWN(["English", "Japanese", "Arabic"], "locale")),
      fontFamily: getCustomView(DROPDOWN(["font1", "font2", "font3"], "Font")),
      paypalButonColor: getCustomView(GRADIENTVAL("PayPal Button")),
      applePayButtonColor: getCustomView(GRADIENTVAL("Apple Button")),
      googlePayButtonColor: getCustomView(GRADIENTVAL("Google Button")),
      payNowButtonColor: getCustomView(GRADIENTVAL("Pay Now Button")),
      payNowButtonTextColor: getCustomView(COLOR("Pay Now Button Text")),
      focusedTextInputBoderColor: getCustomView(COLOR("")),
      errorTextInputColor: getCustomView(COLOR("")),
      normalTextInputBoderColor: getCustomView(COLOR("")),
    }
    Window.postMessage(
      JSON.stringifyAny({themeBasedObject: themeBasedStyleObj})->Option.getOr(
        "{\"themeBasedObject\": \"this shouldn't be here\"}",
      ),
      "*",
    )
    let handleMessage = ev => {
      let eventStr = ev->data

      try {
        let optionalJson =
          eventStr
          ->JSON.parseExn
          ->JSON.Decode.object
          ->Option.flatMap(Dict.get(_, "initialProps"))
          ->Option.flatMap(JSON.Decode.object)
          ->Option.flatMap(Dict.get(_, "props"))

        switch optionalJson {
        | Some(json) => setPropFromEvent(_ => Some(json))
        | None => ()
        }
      } catch {
      | _ => ()
      }
    }

    Window.addEventListener("message", handleMessage)
    None
  })

  // <div
  //   className="css-view-175oi2r r-flex-13awgt0 r-pointerEvents-12vffkv"
  //   style={ReactDOMStyle.make(
  //     ~maxWidth="600px",
  //     ~height="100%",
  //     ~width="-webkit-fill-available",
  //     ~margin="0 auto",
  //     (),
  //   )}>
  //   {switch (propFromEvent, props->Utils.getDictFromJson->Utils.getBool("local", false)) {
  //   | (Some(props), _) => <App props rootTag=1 reactNativeRef=None />
  //   | (None, true) => <App props rootTag=0 reactNativeRef=None />
  //   | _ => React.null
  //   }}
  // </div>
  switch (propFromEvent, props->Utils.getDictFromJson->Utils.getBool("local", false)) {
  | (Some(props), _) => <App props rootTag=1 />
  | (None, true) => <App props rootTag=0 />
  | _ => React.null
  }
}
