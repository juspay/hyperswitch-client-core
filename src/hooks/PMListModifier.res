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

let useSheetListModifier = () => {
  let (allApiData, _) = React.useContext(AllApiDataContext.allApiDataContext)
  let (addApplePay, addGooglePay) =
    ReactNative.Platform.os === #web
      ? WebButtonHook.usePayButton()
      : ((~sessionObject as _, ~resolve as _) => (), (~sessionObject as _) => ())
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
            name: paymentMethodData.payment_method_type->CommonUtils.getDisplayName,
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
          name: paymentMethodData.payment_method_type->CommonUtils.getDisplayName,
          componentHoc: (~isScreenFocus, ~setConfirmButtonDataRef) =>
            <PaymentMethod isScreenFocus paymentMethodData setConfirmButtonDataRef />,
        })
      }
      (tabArr, elementArr)
    })
  }, [allApiData.paymentMethodList])
}

let useWidgetListModifier = () => {
  let (allApiData, _) = React.useContext(AllApiDataContext.allApiDataContext)
  let (addApplePay, addGooglePay) =
    ReactNative.Platform.os === #web
      ? WebButtonHook.usePayButton()
      : ((~sessionObject as _, ~resolve as _) => (), (~sessionObject as _) => ())
  let samsungPayStatus = SamsungPay.useSamsungPayValidityHook()

  React.useMemo1(() => {
    allApiData.paymentMethodList->Array.reduce([], (
      widgetArr: array<React.element>,
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
        | _ => None
        } {
        | Some(_) =>
          widgetArr->Array.push(
            <PaymentMethod
              key=paymentMethodData.payment_method_type
              paymentMethodData
              sessionObject
              methodType={WIDGET}
            />,
          )
        | None => ()
        }
      }
      widgetArr
    })
  }, [allApiData.paymentMethodList])
}
