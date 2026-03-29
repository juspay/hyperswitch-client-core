// Native module binding for Redsys 3DS method POST.
// On native (iOS/Android), delegates to a native module that performs a hidden WKWebView/WebView form POST.
// On web, uses a hidden iframe + form POST (same approach as the web SDK).

// --- Native module binding ---
type module_ = {
  performThreeDsMethodPost: (string, string, string, int) => promise<string>,
}

@val external require: string => module_ = "require"

let nativePerformThreeDsMethodPost = switch try {
  require("@juspay-tech/react-native-hyperswitch-3ds-method")->Some
} catch {
| _ => None
} {
| Some(mod) => mod.performThreeDsMethodPost
| None => (_, _, _, _) => Promise.resolve("N")
}

// --- Web fallback: DOM-based hidden iframe + form POST ---
@val @scope("document") external createDomElement: string => Dom.element = "createElement"
@val @scope("document") external domBody: Dom.element = "body"
@send external domAppendChild: (Dom.element, Dom.element) => unit = "appendChild"
@send external domRemoveChild: (Dom.element, Dom.element) => unit = "removeChild"
@set external setId: (Dom.element, string) => unit = "id"
@set external setName: (Dom.element, string) => unit = "name"
@set external setDomValue: (Dom.element, string) => unit = "value"
@set external setInputType: (Dom.element, string) => unit = "type"
@set external setAction: (Dom.element, string) => unit = "action"
@set external setFormMethod: (Dom.element, string) => unit = "method"
@set external setTarget: (Dom.element, string) => unit = "target"
@send external setAttribute: (Dom.element, string, string) => unit = "setAttribute"
@send external submitForm: Dom.element => unit = "submit"
@send external addLoadListener: (Dom.element, @as("load") _, unit => unit) => unit =
  "addEventListener"

let performThreeDsMethodWeb = (~url: string, ~data: string, ~methodKey: string, ~timeoutMs: int) => {
  Promise.make((resolve, _reject) => {
    let isCompleted = ref(false)
    let container = ref(None)
    let timeoutId = ref(None)

    let complete = (indicator: string) => {
      if !isCompleted.contents {
        isCompleted := true
        // Clean up timeout
        timeoutId.contents->Option.forEach(id => clearTimeout(id))
        // Clean up DOM elements
        container.contents->Option.forEach(el => {
          try {
            domRemoveChild(domBody, el)
          } catch {
          | _ => ()
          }
        })
        resolve(indicator)
      }
    }

    // Create hidden container div
    let containerDiv = createDomElement("div")
    setAttribute(containerDiv, "style", "position:fixed;left:-9999px;top:-9999px;width:1px;height:1px;opacity:0;")
    container := Some(containerDiv)

    // Create hidden iframe
    let iframe = createDomElement("iframe")
    setId(iframe, "threeDsMethodIframe")
    setName(iframe, "threeDsMethodIframe")
    setAttribute(iframe, "style", "width:0;height:0;border:none;")
    domAppendChild(containerDiv, iframe)

    // Create form targeting the iframe
    let form = createDomElement("form")
    setAction(form, url)
    setFormMethod(form, "POST")
    setTarget(form, "threeDsMethodIframe")

    // Create hidden input with 3DS method data
    let input = createDomElement("input")
    setInputType(input, "hidden")
    setName(input, methodKey)
    setDomValue(input, data)
    domAppendChild(form, input)

    domAppendChild(containerDiv, form)

    // Append container to body
    domAppendChild(domBody, containerDiv)

    // Listen for iframe load event -> "Y" (second load = form POST response)
    // First load fires when blank iframe is attached to DOM, second when POST completes.
    let loadCount = ref(0)
    addLoadListener(iframe, () => {
      loadCount := loadCount.contents + 1
      if loadCount.contents >= 2 {
        complete("Y")
      }
    })

    // Set timeout -> "N"
    timeoutId := Some(setTimeout(() => {
        complete("N")
      }, timeoutMs))

    // Submit the form
    submitForm(form)
  })
}

// --- Platform dispatcher ---
let performThreeDsMethod = (~url, ~data, ~methodKey, ~timeoutMs) => {
  switch ReactNative.Platform.os {
  | #web => performThreeDsMethodWeb(~url, ~data, ~methodKey, ~timeoutMs)
  | _ => nativePerformThreeDsMethodPost(url, data, methodKey, timeoutMs)
  }
}
