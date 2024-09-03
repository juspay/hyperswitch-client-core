@get external data: ReactEvent.Form.t => string = "data"

@react.component
let app = (~props) => {
  let (propFromEvent, setPropFromEvent) = React.useState(() => None)
  let {sdkInitialised} = WebKit.useWebKit()
  Window.useEventListener()

  React.useEffect0(() => {
    let handleMessage = optionalJson => {
      try {
        switch optionalJson->Dict.get("props") {
        | Some(json) => setPropFromEvent(_ => Some(json))
        | None => ()
        }
      } catch {
      | _ => ()
      }
    }
    Window.registerEventListener("initialProps", handleMessage)

    let sdkInitialisedProp = JSON.stringifyAny({
      "sdkLoaded": true,
    })->Option.getOr("")

    Window.postMessage(sdkInitialisedProp, "*")
    sdkInitialised(sdkInitialisedProp)

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
