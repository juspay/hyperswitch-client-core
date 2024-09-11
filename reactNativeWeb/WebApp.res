@get external data: ReactEvent.Form.t => string = "data"

@react.component
let app = (~props) => {
  let (propFromEvent, setPropFromEvent) = React.useState(() => None)
  let {sdkInitialised} = WebKit.useWebKit()
  Window.useEventListener()

  React.useEffect0(() => {
    let handleMessage = jsonData => {
      try {
        switch jsonData->Dict.get("props") {
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

    Window.postMessageToParent(sdkInitialisedProp, "*")
    sdkInitialised(sdkInitialisedProp)

    None
  })

  switch (propFromEvent, props->Utils.getDictFromJson->Utils.getBool("local", false)) {
  | (Some(props), _) => <App props rootTag=1 />
  | (None, true) => <App props rootTag=0 />
  | _ => React.null
  }
}
