open InAppBrowserTypes
open InAppBrowserHelpers

module InAppBrowser = {
  @module("react-native-inappbrowser-reborn") @scope("InAppBrowser")
  external openUrl: (string, option<string>, properties) => promise<res> = "openAuth"

  @module("react-native-inappbrowser-reborn") @scope("InAppBrowser")
  external isAvailable: unit => promise<bool> = "isAvailable"
}

let openUrl = async (
  url,
  returnUrl,
  intervalId: React.ref<RescriptCore.Nullable.t<intervalId>>,
  ~useEphemeralWebSession=false,
  ~appearance: SdkTypes.appearance,
) => {
  try {
    let reactNativeWebRespPromise = Promise.make((resolve, _reject) => {
      let newTab = Window.open_(url)
      intervalId.current = setInterval(() => {
          try {
            switch newTab->Nullable.toOption {
            | Some(tab) =>
              let currentUrl = tab.location.href
              resolve({message: currentUrl, url: None, \"type": ""})
              switch intervalId.current->Nullable.toOption {
              | Some(id) => clearInterval(id)
              | None => ()
              }
              tab.close()

            | None => ()
            }
          } catch {
          | _ => ()
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

    let inAppBrowserIsAvailable = await InAppBrowser.isAvailable()

    let handleOpenURL = () => {
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
    }

    let res = switch (ReactNative.Platform.os, inAppBrowserIsAvailable) {
    | (#web, _) => await reactNativeWebRespPromise
    | (_, true) => await handleOpenURL()
    | (_, false) => {
        url: None,
        message: "InAppBrowser not available",
        \"type": "error",
      }
    }

    let message = WebKit.platform === #ios ? res.url->Option.getOr("") : res.message
    let status = determineStatus(message, res)

    let browserRes = switch status {
    | Success => {
        let (paymentID, amount) = parsePaymentData(message)
        {paymentID, amount, status: Success}
      }
    | Failed => {
        let (paymentID, amount) = parsePaymentData(message)
        {paymentID, amount, status: Failed}
      }
    | InAppBrowserTypes.Error => {
        paymentID: "",
        amount: "",
        status: InAppBrowserTypes.Error,
      }
    | Cancel => {
        paymentID: "",
        amount: "",
        status: Cancel,
      }
    }

    browserRes
  } catch {
  | _ => {
      let browserRes = {
        paymentID: "",
        amount: "",
        status: Failed,
      }
      browserRes
    }
  }
}
