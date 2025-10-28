type componentHoc = (
  ~isScreenFocus: bool,
  ~setConfirmButtonData: GlobalConfirmButton.confirmButtonData => unit,
) => React.element

type hoc = {
  name: string,
  componentHoc: componentHoc,
}

type walletProp = {
  walletType: string,
  sessionObject: SessionsType.sessions,
}

let useAccountPaymentMethodModifier = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let (accountPaymentMethodData, customerPaymentMethodData, sessionTokenData) = React.useContext(
    AllApiDataContextNew.allApiDataContext,
  )
  let samsungPayStatus = SamsungPay.useSamsungPayValidityHook()

  React.useMemo3(() => {
    let (initialTabArr, initialElementArr) = if nativeProp.configuration.displayMergedSavedMethods {
      customerPaymentMethodData
      ->Option.map(customerPaymentMethods => {
        switch nativeProp.sdkState {
        | PaymentSheet | WidgetPaymentSheet | HostedCheckout | TabSheet | WidgetTabSheet =>
          let customerPaymentMethods =
            customerPaymentMethods.customer_payment_methods->Array.filter(
              customer_payment_method_type =>
                customer_payment_method_type.payment_method !== WALLET,
            )
          (
            customerPaymentMethods->Array.length > 0
              ? [
                  {
                    name: "Saved",
                    componentHoc: (~isScreenFocus, ~setConfirmButtonData) =>
                      <SavedPaymentSheet
                        isScreenFocus
                        customerPaymentMethods
                        setConfirmButtonData
                        merchantName={accountPaymentMethodData
                        ->Option.map(data => data.merchant_name)
                        ->Option.getOr(nativeProp.configuration.merchantDisplayName)}
                        animated=false
                        style={ReactNative.Style.s({marginBottom: 10.->ReactNative.Style.dp})}
                      />,
                  },
                ]
              : [],
            [],
          )
        | ButtonSheet | WidgetButtonSheet => // elementArr->Array.push(
          //   <PaymentMethod
          //     key={paymentMethodData.payment_method_type}
          //     paymentMethodData
          //     sessionObject
          //     methodType=ELEMENT
          //   />,
          // )
          ([], [])
        | _ => ([], [])
        }
      })
      ->Option.getOr(([], []))
    } else {
      ([], [])
    }

    switch accountPaymentMethodData {
    | Some(accountPaymentMethodData) =>
      accountPaymentMethodData.payment_methods->Array.reduce(
        (initialTabArr, initialElementArr, []),
        (
          (tabArr, elementArr, giftCardArr): (
            array<hoc>,
            array<React.element>,
            array<AccountPaymentMethodType.payment_method_type>,
          ),
          paymentMethodData,
        ) => {
          let sessionObject = switch sessionTokenData {
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

          let walletExperience = switch paymentMethodData.payment_method_type_wallet {
          | APPLE_PAY =>
            WebKit.platform !== #android &&
            WebKit.platform !== #androidWebView &&
            WebKit.platform !== #next &&
            sessionObject.wallet_name !== NONE &&
            exp->Option.isSome
              ? Some()
              : None
          | GOOGLE_PAY =>
            WebKit.platform !== #ios &&
            WebKit.platform !== #iosWebView &&
            WebKit.platform !== #next &&
            sessionObject.wallet_name !== NONE &&
            sessionObject.connector !== "trustpay" &&
            exp->Option.isSome
              ? Some()
              : None
          | SAMSUNG_PAY =>
            exp->Option.isSome &&
            SamsungPayModule.isAvailable &&
            samsungPayStatus == SamsungPay.Valid
              ? Some()
              : None
          | PAYPAL =>
            exp->Option.isSome && PaypalModule.payPalModule->Option.isSome
              ? Some()
              : switch paymentMethodData.payment_experience->Array.find(
                  x => x.payment_experience_type_decode === REDIRECT_TO_URL,
                ) {
                | Some(_) => Some()
                | None => None
                }
          | NONE =>
            switch paymentMethodData.payment_method {
            | GIFT_CARD =>
              giftCardArr->Array.push(paymentMethodData)
              None
            | CARD_REDIRECT => None
            | _ => Some()
            }
          }

          if walletExperience->Option.isSome {
            switch nativeProp.sdkState {
            | PaymentSheet | WidgetPaymentSheet | HostedCheckout =>
              Types.defaultButtonElementArr->Array.includes(paymentMethodData.payment_method_type)
                ? elementArr->Array.push(
                    <PaymentMethod
                      key={paymentMethodData.payment_method_type}
                      paymentMethodData
                      sessionObject
                      methodType=ELEMENT
                    />,
                  )
                : tabArr->Array.push({
                    name: paymentMethodData.payment_method_type->CommonUtils.getDisplayName,
                    componentHoc: (~isScreenFocus, ~setConfirmButtonData) =>
                      <PaymentMethod isScreenFocus paymentMethodData setConfirmButtonData />,
                  })

            | TabSheet | WidgetTabSheet =>
              tabArr->Array.push({
                name: paymentMethodData.payment_method_type->CommonUtils.getDisplayName,
                componentHoc: (~isScreenFocus, ~setConfirmButtonData) =>
                  <PaymentMethod isScreenFocus paymentMethodData setConfirmButtonData />,
              })
            | ButtonSheet | WidgetButtonSheet =>
              elementArr->Array.push(
                <PaymentMethod
                  key={paymentMethodData.payment_method_type}
                  paymentMethodData
                  sessionObject
                  methodType=ELEMENT
                />,
              )
            | _ => ()
            }
          }
          (tabArr, elementArr, giftCardArr)
        },
      )
    | None =>
      let loadingTabElement = {
        name: "loading",
        componentHoc: (~isScreenFocus as _, ~setConfirmButtonData as _) => <>
          <Space height=20. />
          <CustomLoader />
          <Space height=10. />
          <CustomLoader />
        </>,
      }

      switch nativeProp.sdkState {
      | PaymentSheet | WidgetPaymentSheet => (
          [loadingTabElement, loadingTabElement, loadingTabElement, loadingTabElement],
          [<CustomLoader key="1" />, <Space key="2" />],
          [],
        )
      | TabSheet | WidgetTabSheet => (
          [loadingTabElement, loadingTabElement, loadingTabElement, loadingTabElement],
          [],
          [],
        )
      | ButtonSheet | WidgetButtonSheet => (
          [],
          [
            <CustomLoader key="1" />,
            <Space key="2" />,
            <CustomLoader key="3" />,
            <Space key="4" />,
            <CustomLoader key="5" />,
            <Space key="6" />,
            <CustomLoader key="7" />,
            <Space key="8" />,
            <CustomLoader key="9" />,
          ],
          [],
        )
      | _ => ([], [], [])
      }
    }
  }, (accountPaymentMethodData, customerPaymentMethodData, sessionTokenData))
}

let useAddWebPaymentButton = () => {
  let (accountPaymentMethodData, _, sessionTokenData) = React.useContext(
    AllApiDataContextNew.allApiDataContext,
  )
  let (addApplePay, addGooglePay) =
    ReactNative.Platform.os === #web
      ? WebButtonHook.usePayButton()
      : ((~sessionObject as _, ~resolve as _) => (), (~sessionObject as _) => ())

  React.useMemo2(() => {
    if ReactNative.Platform.os === #web {
      switch accountPaymentMethodData {
      | Some(accountPaymentMethodData) =>
        accountPaymentMethodData.payment_methods->Array.forEach(paymentMethodData => {
          let sessionObject = switch sessionTokenData {
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

          switch paymentMethodData.payment_method_type_wallet {
          | APPLE_PAY =>
            if (
              WebKit.platform !== #android &&
              WebKit.platform !== #androidWebView &&
              WebKit.platform !== #next &&
              sessionObject.wallet_name !== NONE &&
              exp->Option.isSome
            ) {
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
            }
          | GOOGLE_PAY =>
            if (
              WebKit.platform !== #ios &&
              WebKit.platform !== #iosWebView &&
              WebKit.platform !== #next &&
              sessionObject.wallet_name !== NONE &&
              sessionObject.connector !== "trustpay" &&
              exp->Option.isSome
            ) {
              addGooglePay(~sessionObject)
            }
          | _ => ()
          }
        })
      | None => ()
      }
    }
  }, (accountPaymentMethodData, sessionTokenData))
}

let useWidgetListModifier = () => {
  // let (allApiData, _) = React.useContext(AllApiDataContext.allApiDataContext)
  // let (addApplePay, addGooglePay) =
  //   ReactNative.Platform.os === #web
  //     ? WebButtonHook.usePayButton()
  //     : ((~sessionObject as _, ~resolve as _) => (), (~sessionObject as _) => ())
  // let samsungPayStatus = SamsungPay.useSamsungPayValidityHook()

  // React.useMemo1(() => {
  //   allApiData.paymentMethodList->Array.reduce([], (
  //     widgetArr: array<React.element>,
  //     paymentMethodData,
  //   ) => {
  //     if paymentMethodData.payment_method === WALLET {
  //       let sessionObject = switch allApiData.sessions {
  //       | Some(sessionData) =>
  //         sessionData
  //         ->Array.find(item => item.wallet_name == paymentMethodData.payment_method_type_wallet)
  //         ->Option.getOr(SessionsType.defaultToken)
  //       | _ => SessionsType.defaultToken
  //       }

  //       let exp =
  //         paymentMethodData.payment_experience->Array.find(
  //           x => x.payment_experience_type_decode === INVOKE_SDK_CLIENT,
  //         )

  //       switch switch paymentMethodData.payment_method_type_wallet {
  //       | APPLE_PAY =>
  //         WebKit.platform !== #android &&
  //         WebKit.platform !== #androidWebView &&
  //         WebKit.platform !== #next &&
  //         sessionObject.wallet_name !== NONE
  //           ? {
  //               Promise.make(
  //                 (resolve, _) => {
  //                   addApplePay(~sessionObject, ~resolve)
  //                 },
  //               )
  //               // ->Promise.then(isApplePaySupported => {
  //               //   isApplePaySupported ? exp : None
  //               //   Promise.resolve()
  //               // })
  //               ->ignore
  //               exp
  //             }
  //           : None
  //       | GOOGLE_PAY =>
  //         WebKit.platform !== #ios &&
  //         WebKit.platform !== #iosWebView &&
  //         WebKit.platform !== #next &&
  //         sessionObject.wallet_name !== NONE &&
  //         sessionObject.connector !== "trustpay" &&
  //         exp->Option.isSome
  //           ? {
  //               addGooglePay(~sessionObject)
  //               exp
  //             }
  //           : None
  //       | SAMSUNG_PAY =>
  //         exp->Option.isSome && SamsungPayModule.isAvailable && samsungPayStatus == SamsungPay.Valid
  //           ? exp
  //           : None
  //       | PAYPAL =>
  //         exp->Option.isSome && PaypalModule.payPalModule->Option.isSome
  //           ? exp
  //           : paymentMethodData.payment_experience->Array.find(
  //               x => x.payment_experience_type_decode === REDIRECT_TO_URL,
  //             )
  //       | _ => None
  //       } {
  //       | Some(_) =>
  //         widgetArr->Array.push(
  //           <PaymentMethod
  //             key=paymentMethodData.payment_method_type
  //             paymentMethodData
  //             sessionObject
  //             methodType={WIDGET}
  //           />,
  //         )
  //       | None => ()
  //       }
  //     }
  //     widgetArr
  //   })
  // }, [allApiData.paymentMethodList])

  ()
}
