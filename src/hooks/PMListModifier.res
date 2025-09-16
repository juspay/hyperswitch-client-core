type hoc = {
  name: string,
  componentHoc: (
    ~isScreenFocus: bool,
    ~setConfirmButtonDataRef: React.element => unit,
  ) => React.element,
}

type walletProp = {
  walletType: PaymentMethodListType.payment_method_type,
  sessionObject: SessionsType.sessions,
}

// let widgetModifier = (
//   pmList: PaymentMethodListType.payment_methods,
//   sessionData: AllApiDataContext.sessions,
//   widgetType,
//   confirm,
// ) => {
//   let modifiedList = pmList->Array.reduce([], (accumulator, payment_method) => {
//     switch payment_method.payment_method {
//     | WALLET =>
//       widgetType == payment_method.payment_method_type_wallet
//         ? {
//             let sessionObject = switch sessionData {
//             | Some(sessionData) =>
//               sessionData
//               ->Array.find(item => item.wallet_name == payment_method.payment_method_type_wallet)
//               ->Option.getOr(SessionsType.defaultToken)
//             | _ => SessionsType.defaultToken
//             }
//             let exp =
//               payment_method.payment_experience->Array.find(x =>
//                 x.payment_experience_type_decode === INVOKE_SDK_CLIENT
//               )
//             switch switch payment_method.payment_method_type_wallet {
//             | GOOGLE_PAY =>
//               WebKit.platform !== #ios &&
//               WebKit.platform !== #iosWebView &&
//               sessionObject.wallet_name !== NONE
//                 ? exp
//                 : None
//             | PAYPAL =>
//               exp->Option.isNone
//                 ? payment_method.payment_experience->Array.find(x =>
//                     x.payment_experience_type_decode === REDIRECT_TO_URL
//                   )
//                 : exp
//             | APPLE_PAY =>
//               WebKit.platform !== #android &&
//               WebKit.platform !== #androidWebView &&
//               sessionObject.wallet_name !== NONE
//                 ? exp
//                 : None
//             | _ => None
//             } {
//             | Some(_) =>
//               accumulator
//               ->Array.push(
//                 <ButtonElement
//                   walletType=payment_method
//                   sessionObject
//                   confirm
//                   isWidget=true
//                 />,
//               )
//               ->ignore
//             | None => ()
//             }
//           }
//         : ()
//     | _ => ()
//     }
//     accumulator
//   })

//   switch modifiedList->Array.length {
//   | 0 => Some(React.null)
//   | _ => modifiedList->Array.get(0)
//   }
// }

let useSheetListModifier = () => {
  let (allApiData, _) = React.useContext(AllApiDataContext.allApiDataContext)
  let dummyFn = ((~sessionObject as _, ~resolve as _) => (), (~sessionObject as _) => ())
  let (addApplePay, addGooglePay) =
    ReactNative.Platform.os === #web ? WebButtonHook.usePayButton() : dummyFn
  let samsungPayStatus = SamsungPay.useSamsungPayValidityHook()

  React.useMemo1(() => {
    allApiData.paymentMethodList->Array.reduce(([], []), (
      (tabArr, elementArr): (array<hoc>, array<React.element>),
      paymentMethodData,
    ) => {
      if paymentMethodData.payment_method === WALLET {
        let sessionObject = switch allApiData.sessions {
        | Some(sessionData) =>
          sessionData
          ->Array.find(item => item.wallet_name == paymentMethodData.payment_method_type_wallet)
          ->Option.getOr(SessionsType.defaultToken)
        | _ => SessionsType.defaultToken
        }

        let exp =
          paymentMethodData.payment_experience->Array.find(
            x => x.payment_experience_type_decode === INVOKE_SDK_CLIENT,
          )

        switch switch paymentMethodData.payment_method_type_wallet {
        | APPLE_PAY =>
          WebKit.platform !== #android &&
          WebKit.platform !== #androidWebView &&
          WebKit.platform !== #next &&
          sessionObject.wallet_name !== NONE
            ? {
                Promise.make(
                  (resolve, _) => {
                    addApplePay(~sessionObject, ~resolve)
                  },
                )
                // ->Promise.then(isApplePaySupported => {
                //   isApplePaySupported ? exp : None
                //   Promise.resolve()
                // })
                ->ignore
                exp
              }
            : None
        | GOOGLE_PAY =>
          WebKit.platform !== #ios &&
          WebKit.platform !== #iosWebView &&
          WebKit.platform !== #next &&
          sessionObject.wallet_name !== NONE &&
          sessionObject.connector !== "trustpay" &&
          exp->Option.isSome
            ? {
                addGooglePay(~sessionObject)
                exp
              }
            : None
        | SAMSUNG_PAY =>
          exp->Option.isSome && SamsungPayModule.isAvailable && samsungPayStatus == SamsungPay.Valid
            ? exp
            : None
        | PAYPAL =>
          exp->Option.isSome && PaypalModule.payPalModule->Option.isSome
            ? exp
            : paymentMethodData.payment_experience->Array.find(
                x => x.payment_experience_type_decode === REDIRECT_TO_URL,
              )
        | _ =>
          tabArr->Array.push({
            name: paymentMethodData.payment_method_type->Utils.getDisplayName,
            componentHoc: (~isScreenFocus, ~setConfirmButtonDataRef) =>
              <PaymentMethod isScreenFocus paymentMethodData setConfirmButtonDataRef />,
          })
          None
        } {
        | Some(_) =>
          elementArr->Array.push(
            <PaymentMethod
              key=paymentMethodData.payment_method_type
              paymentMethodData
              sessionObject
              methodType=ELEMENT
            />,
          )
        | None => ()
        }
      } else {
        tabArr->Array.push({
          name: paymentMethodData.payment_method_type->Utils.getDisplayName,
          componentHoc: (~isScreenFocus, ~setConfirmButtonDataRef) =>
            <PaymentMethod isScreenFocus paymentMethodData setConfirmButtonDataRef />,
        })
      }
      (tabArr, elementArr)
    })
  }, [allApiData.paymentMethodList])
}
