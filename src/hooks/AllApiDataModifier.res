type componentHoc = (
  ~isScreenFocus: bool,
  ~setConfirmButtonData: GlobalConfirmButton.confirmButtonData => unit,
) => React.element

type hoc = {
  name: string,
  paymentMethodType: string,
  componentHoc: componentHoc,
}

type walletProp = {
  walletType: string,
  sessionObject: SessionsType.sessions,
}

let usePaymentMethodModifier = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let {clientData, sessionTokenData} = AllApiDataContextNew.useData()
  let samsungPayStatus = SamsungPay.useSamsungPayValidityHook()

  React.useMemo2(() => {
    let groupingBehavior = nativeProp.configuration.paymentMethodLayout.savedMethodCustomization.groupingBehavior

    // Show a merged "Saved" tab only when displaySavedPaymentMethods=true AND displayInSeparateScreen=false AND groupByPaymentMethods=false
    let showMergedSavedTab =
      nativeProp.configuration.displaySavedPaymentMethods &&
      !groupingBehavior.displayInSeparateScreen &&
      !groupingBehavior.groupByPaymentMethods &&
      !groupingBehavior.displayInSeparateSection

    let (initialTabArr, initialElementArr) = if showMergedSavedTab {
      switch nativeProp.sdkState {
      | PaymentSheet | WidgetPaymentSheet | HostedCheckout | TabSheet | WidgetTabSheet =>
        let customerPaymentMethods = clientData.customer_payment_methods
        (
          customerPaymentMethods->Array.length > 0
            ? [
                {
                  name: "Saved",
                  paymentMethodType: "saved_payment_method",
                  componentHoc: (~isScreenFocus, ~setConfirmButtonData) =>
                    <SavedPaymentSheet
                      isScreenFocus
                      customerPaymentMethods
                      setConfirmButtonData
                      merchantName=clientData.intent_data.merchant_name
                      animated=true
                      style={ReactNative.Style.s({marginBottom: 10.->ReactNative.Style.dp})}
                    />,
                },
              ]
            : [],
          [],
        )
      | ButtonSheet | WidgetButtonSheet => ([], [])
      | _ => ([], [])
      }
    } else {
      ([], [])
    }

    clientData.payment_methods_enabled->Array.reduce(
        (initialTabArr, initialElementArr, []),
        (
          (tabArr, elementArr, giftCardArr): (
            array<hoc>,
            array<React.element>,
            array<ClientResponseType.paymentMethodEnabled>,
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
            exp->Option.isSome && PaypalModule.isAvailable
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
            let isGroupByPMCard =
              !groupingBehavior.displayInSeparateScreen &&
              groupingBehavior.groupByPaymentMethods &&
              paymentMethodData.payment_method === CARD

            let savedCardMethods =
              clientData.customer_payment_methods->Array.filter(m => m.payment_method === CARD)

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
                    paymentMethodType: paymentMethodData.payment_method_type,
                    componentHoc: isGroupByPMCard
                      ? (~isScreenFocus, ~setConfirmButtonData) =>
                          <SavedCardToggleTab
                            isScreenFocus setConfirmButtonData paymentMethodData savedCardMethods
                          />
                      : (~isScreenFocus, ~setConfirmButtonData) =>
                          <PaymentMethod isScreenFocus paymentMethodData setConfirmButtonData />,
                  })

            | TabSheet | WidgetTabSheet =>
              tabArr->Array.push({
                name: paymentMethodData.payment_method_type->CommonUtils.getDisplayName,
                paymentMethodType: paymentMethodData.payment_method_type,
                componentHoc: isGroupByPMCard
                  ? (~isScreenFocus, ~setConfirmButtonData) =>
                      <SavedCardToggleTab
                        isScreenFocus setConfirmButtonData paymentMethodData savedCardMethods
                      />
                  : (~isScreenFocus, ~setConfirmButtonData) =>
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
  }, (clientData, sessionTokenData))
}

let useAddWebPaymentButton = () => {
  let {clientData, sessionTokenData} = AllApiDataContextNew.useData()
  let (addApplePay, addGooglePay) =
    ReactNative.Platform.os === #web
      ? WebButtonHook.usePayButton()
      : ((~sessionObject as _, ~resolve as _) => (), (~sessionObject as _) => ())

  React.useMemo2(() => {
    if ReactNative.Platform.os === #web {
      clientData.payment_methods_enabled->Array.forEach(paymentMethodData => {
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
    }
  }, (clientData, sessionTokenData))
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
