@react.component
let app = (~props) => {
  let (propFromEvent, setPropFromEvent) = React.useState(() => None)
  let {sdkInitialised} = WebKit.useWebKit()
  Window.useEventListener()

  // Mirror of the native split: payments mounts `App` (hyperSwitch), PMM
  // mounts `PMMApp` (hyperPMM). The root is chosen the same way natives do —
  // from the launch type (props.type) of the *effective* props (the ones
  // posted via `initialProps` once they arrive, else the boot props) — with a
  // `?mode=pmm` URL override for the standalone local preview.
  let urlPmmMode =
    (%raw(`new URLSearchParams(window.location.search).get("mode")`): string) == "pmm"
  let isPmmProps = p =>
    switch p->Utils.getDictFromJson->Utils.getString("type", "") {
    | "paymentMethodsManagement" | "widgetPaymentMethodsManagement" => true
    | _ => false
    }

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

    sdkInitialised(sdkInitialisedProp)

    None
  })

  switch (propFromEvent, props->Utils.getDictFromJson->Utils.getBool("local", false)) {
  | (Some(eventProps), true) =>
    urlPmmMode || isPmmProps(eventProps)
      ? <PMMApp props=eventProps rootTag=1 />
      : <App props=eventProps rootTag=1 />
  | (Some(eventProps), false) =>
    urlPmmMode || isPmmProps(eventProps)
      ? <PMMApp props=eventProps rootTag=0 />
      : <App props=eventProps rootTag=0 />
  | (None, true) => urlPmmMode || isPmmProps(props) ? <PMMApp props rootTag=0 /> : <App props rootTag=0 />
  | _ => React.null
  }
}
