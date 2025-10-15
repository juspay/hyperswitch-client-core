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
            customerPaymentMethods.customerPaymentMethodTypes->Array.filter(
              customerPaymentMethodType =>
                customerPaymentMethodType.paymentMethod !== WALLET,
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
                        ->Option.map(data => data.merchantName)
                        ->Option.getOr(nativeProp.configuration.merchantDisplayName)}
                        animated=false
                      />,
                  },
                ]
              : [],
            [],
          )
        | ButtonSheet | WidgetButtonSheet => // elementArr->Array.push(
          //   <PaymentMethod
          //     key={paymentMethodData.paymentMethodType}
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
      accountPaymentMethodData.paymentMethods->Array.reduce((initialTabArr, initialElementArr), (
        (tabArr, elementArr): (array<hoc>, array<React.element>),
        paymentMethodData,
      ) => {
        let sessionObject = switch sessionTokenData {
        | Some(sessionData) =>
          sessionData
          ->Array.find(item => item.walletName == paymentMethodData.paymentMethodTypeWallet)
          ->Option.getOr(SessionsType.defaultToken)
        | _ => SessionsType.defaultToken
        }

        let exp =
          paymentMethodData.paymentExperience->Array.find(
            x => x.paymentExperienceTypeDecode === INVOKE_SDK_CLIENT,
          )

        let walletExperience = switch paymentMethodData.paymentMethodTypeWallet {
        | APPLE_PAY =>
          WebKit.platform !== #android &&
          WebKit.platform !== #androidWebView &&
          WebKit.platform !== #next &&
          sessionObject.walletName !== NONE &&
          exp->Option.isSome
            ? Some()
            : None
        | GOOGLE_PAY =>
          WebKit.platform !== #ios &&
          WebKit.platform !== #iosWebView &&
          WebKit.platform !== #next &&
          sessionObject.walletName !== NONE &&
          sessionObject.connector !== "trustpay" &&
          exp->Option.isSome
            ? Some()
            : None
        | SAMSUNG_PAY =>
          exp->Option.isSome && SamsungPayModule.isAvailable && samsungPayStatus == SamsungPay.Valid
            ? Some()
            : None
        | PAYPAL =>
          exp->Option.isSome && PaypalModule.payPalModule->Option.isSome
            ? Some()
            : switch paymentMethodData.paymentExperience->Array.find(
                x => x.paymentExperienceTypeDecode === REDIRECT_TO_URL,
              ) {
              | Some(_) => Some()
              | None => None
              }
        | _ => Some()
        }

        if walletExperience->Option.isSome {
          switch nativeProp.sdkState {
          | PaymentSheet | WidgetPaymentSheet | HostedCheckout =>
            Types.defaultButtonElementArr->Array.includes(paymentMethodData.paymentMethodType)
              ? elementArr->Array.push(
                  <PaymentMethod
                    key={paymentMethodData.paymentMethodType}
                    paymentMethodData
                    sessionObject
                    methodType=ELEMENT
                  />,
                )
              : tabArr->Array.push({
                  name: paymentMethodData.paymentMethodType->CommonUtils.getDisplayName,
                  componentHoc: (~isScreenFocus, ~setConfirmButtonData) =>
                    <PaymentMethod isScreenFocus paymentMethodData setConfirmButtonData />,
                })

          | TabSheet | WidgetTabSheet =>
            tabArr->Array.push({
              name: paymentMethodData.paymentMethodType->CommonUtils.getDisplayName,
              componentHoc: (~isScreenFocus, ~setConfirmButtonData) =>
                <PaymentMethod isScreenFocus paymentMethodData setConfirmButtonData />,
            })
          | ButtonSheet | WidgetButtonSheet =>
            elementArr->Array.push(
              <PaymentMethod
                key={paymentMethodData.paymentMethodType}
                paymentMethodData
                sessionObject
                methodType=ELEMENT
              />,
            )
          | _ => ()
          }
        }
        (tabArr, elementArr)
      })
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
        )
      | TabSheet | WidgetTabSheet => (
          [loadingTabElement, loadingTabElement, loadingTabElement, loadingTabElement],
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
        )
      | _ => ([], [])
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
        accountPaymentMethodData.paymentMethods->Array.forEach(paymentMethodData => {
          let sessionObject = switch sessionTokenData {
          | Some(sessionData) =>
            sessionData
            ->Array.find(item => item.walletName == paymentMethodData.paymentMethodTypeWallet)
            ->Option.getOr(SessionsType.defaultToken)
          | _ => SessionsType.defaultToken
          }

          let exp =
            paymentMethodData.paymentExperience->Array.find(
              x => x.paymentExperienceTypeDecode === INVOKE_SDK_CLIENT,
            )

          switch paymentMethodData.paymentMethodTypeWallet {
          | APPLE_PAY =>
            if (
              WebKit.platform !== #android &&
              WebKit.platform !== #androidWebView &&
              WebKit.platform !== #next &&
              sessionObject.walletName !== NONE &&
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
              sessionObject.walletName !== NONE &&
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
  //         ->Array.find(item => item.walletName == paymentMethodData.paymentMethodTypeWallet)
  //         ->Option.getOr(SessionsType.defaultToken)
  //       | _ => SessionsType.defaultToken
  //       }

  //       let exp =
  //         paymentMethodData.paymentExperience->Array.find(
  //           x => x.paymentExperienceTypeDecode === INVOKE_SDK_CLIENT,
  //         )

  //       switch switch paymentMethodData.paymentMethodTypeWallet {
  //       | APPLE_PAY =>
  //         WebKit.platform !== #android &&
  //         WebKit.platform !== #androidWebView &&
  //         WebKit.platform !== #next &&
  //         sessionObject.walletName !== NONE
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
  //         sessionObject.walletName !== NONE &&
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
  //           : paymentMethodData.paymentExperience->Array.find(
  //               x => x.paymentExperienceTypeDecode === REDIRECT_TO_URL,
  //             )
  //       | _ => None
  //       } {
  //       | Some(_) =>
  //         widgetArr->Array.push(
  //           <PaymentMethod
  //             key=paymentMethodData.paymentMethodType
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
