type animations = {
  startEnter: string,
  startExit: string,
  endEnter: string,
  endExit: string,
}

type properties = {
  dismissButtonStyle: string,
  preferredBarTintColor: string,
  preferredControlTintColor: string,
  readerMode: bool,
  animated: bool,
  modalPresentationStyle: string,
  modalTransitionStyle: string,
  modalEnabled: bool,
  enableBarCollapsing: bool,
  showTitle: bool,
  toolbarColor: string,
  secondaryToolbarColor: string,
  navigationBarColor: string,
  navigationBarDividerColor: string,
  enableUrlBarHiding: bool,
  enableDefaultShare: bool,
  forceCloseOnRedirection: bool,
  animations: animations,
  // headers: {
  //   "my-custom-header": "my custom header value"
  // }
  ephemeralWebSession: bool,
  showInRecents: bool,
  // waitForRedirectDelay: int,
}

type res = {url: option<string>, message: string, \"type": string}

type status = Success | Failed | Cancel | Error

type browserRes = {
  paymentID: string,
  amount: string,
  status: status,
}

module InAppBrowser = {
  @module("react-native-inappbrowser-reborn") @scope("InAppBrowser")
  external openUrl: (string, option<string>, properties) => promise<res> = "openAuth"

  @module("react-native-inappbrowser-reborn") @scope("InAppBrowser")
  external isAvailable: unit => promise<bool> = "isAvailable"
}

let openUrl = (
  url,
  returnUrl,
  intervalId: React.ref<RescriptCore.Nullable.t<intervalId>>,
  ~useEphemeralWebSession=false,
  ~appearance: SdkTypes.appearance,
) => {
  {
    ReactNative.Platform.os === #web
      ? Promise.make((resolve, _reject) => {
          let newTab = Window.open_(url)

          intervalId.current = setInterval(() => {
              switch newTab->Nullable.toOption {
              | Some(tab) =>
                if tab.closed {
                  switch intervalId.current->Nullable.toOption {
                  | Some(id) => clearInterval(id)
                  | None => ()
                  }
                  if WebKit.platform === #web {
                    Window.addEventListener(
                      "focus",
                      _ => {
                        resolve({message: "status=processing", url: None, \"type": "cancel"})
                      },
                    )
                  } else {
                    resolve({message: "", url: None, \"type": "cancel"})
                  }
                } else {
                  try {
                    let currentUrl = tab.location.href
                    if currentUrl->String.includes("status=") {
                      resolve({message: currentUrl, url: None, \"type": ""})
                      switch intervalId.current->Nullable.toOption {
                      | Some(id) => clearInterval(id)
                      | None => ()
                      }
                      tab.close()
                    }
                  } catch {
                  | _ => ()
                  }
                }
              | None => ()
              }
            }, 1000)->Nullable.Value

          // Window.setHref(url)
          // let browserRes = {
          //   paymentID: "",
          //   amount: "",
          //   status: Cancel,
          // }
          // resolve(browserRes)
        })
      : InAppBrowser.isAvailable()->Promise.then(_ => {
          // if !x {
          //   return
          // }
          InAppBrowser.openUrl(
            url,
            //"https://proyecto26.com/react-native-inappbrowser/?redirect_url=" ++ returnUrl,
            returnUrl,
            {
              // iOS Properties
              ephemeralWebSession: useEphemeralWebSession,
              dismissButtonStyle: "cancel",
              preferredBarTintColor: appearance.colors
              ->Option.flatMap(a => a->SdkTypes.getPrimaryColor(~theme=appearance.theme))
              ->Option.getOr("#453AA4"),
              preferredControlTintColor: "white",
              readerMode: false,
              animated: true,
              modalPresentationStyle: "fullScreen",
              modalTransitionStyle: "coverVertical",
              modalEnabled: true,
              enableBarCollapsing: false,
              // Android Properties
              showInRecents: true,
              showTitle: false,
              toolbarColor: appearance.colors
              ->Option.flatMap(a => a->SdkTypes.getPrimaryColor(~theme=appearance.theme))
              ->Option.getOr("#6200EE"),
              secondaryToolbarColor: "black",
              navigationBarColor: "black",
              navigationBarDividerColor: "white",
              enableUrlBarHiding: true,
              enableDefaultShare: true,
              forceCloseOnRedirection: false,
              // Specify full animation resource identifier(package:anim/name)
              // or only resource name(in case of animation bundled with app).
              animations: {
                startEnter: "slide_in_right",
                startExit: "slide_out_left",
                endEnter: "slide_in_left",
                endExit: "slide_out_right",
              },
              // headers: {
              //   "my-custom-header": "my custom header value"
              // }
              // waitForRedirectDelay: 10000,
            },
          )
        })
  }->Promise.then(res => {
    try {
      let message = WebKit.platform === #ios ? res.url->Option.getOr("") : res.message
      if (
        message->String.includes("status=succeeded") ||
        message->String.includes("status=processing") ||
        message->String.includes("status=requires_capture") ||
        message->String.includes("status=partially_captured")
      ) {
        let resP = message->String.split("&")
        let am = (resP[2]->Option.getOr("")->String.split("="))[1]->Option.getOr("")
        let browserRes = {
          paymentID: (resP[1]->Option.getOr("")->String.split("="))[1]->Option.getOr(""),
          amount: am,
          status: Success,
        }
        Promise.resolve(browserRes)
      } else if (
        message->String.includes("status=failed") ||
          message->String.includes("status=requires_payment_method")
      ) {
        let resP = message->String.split("&")
        let am = (resP[2]->Option.getOr("")->String.split("="))[1]->Option.getOr("")
        let browserRes = {
          paymentID: String.split(resP[1]->Option.getOr(""), "=")[1]->Option.getOr(""),
          amount: am,
          status: Failed,
        }
        Promise.resolve(browserRes)
      } else if res.\"type" == "cancel" {
        let browserRes = {
          paymentID: "",
          amount: "",
          status: Cancel,
        }
        Promise.resolve(browserRes)
      } else {
        let browserRes = {
          paymentID: "",
          amount: "",
          status: Error,
        }
        Promise.resolve(browserRes)
      }
    } catch {
    | _ =>
      let browserRes = {
        paymentID: "",
        amount: "",
        status: Failed,
      }
      Promise.resolve(browserRes)
    }
  })
}
