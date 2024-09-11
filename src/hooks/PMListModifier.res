type hoc = {
  name: string,
  componentHoc: (
    ~isScreenFocus: bool,
    ~setConfirmButtonDataRef: React.element => unit,
  ) => React.element,
}

type walletProp = {
  walletType: PaymentMethodListType.payment_method_types_wallet,
  sessionObject: SessionsType.sessions,
}

type paymentList = {
  tabArr: array<hoc>,
  elementArr: array<React.element>,
}
let useListModifier = () => {
  let (allApiData, _) = React.useContext(AllApiDataContext.allApiDataContext)
  let handleSuccessFailure = AllPaymentHooks.useHandleSuccessFailure()
  let (addApplePay, addGooglePay) = WebButtonHook.usePayButton()

  // React.useMemo2(() => {
  if allApiData.paymentList->Array.length == 0 {
    handleSuccessFailure(
      ~apiResStatus={
        {
          message: "No eligible Payment Method available",
          code: "PAYMENT_METHOD_NOT_AVAILABLE",
          type_: "failed",
          status: "failed",
        }
      },
      ~closeSDK=true,
      (),
    )
    {
      tabArr: [],
      elementArr: [],
    }
  } else {
    let redirectionList = Types.defaultConfig.redirectionList
    allApiData.paymentList->Array.reduce(
      {
        tabArr: [],
        elementArr: [],
      },
      (accumulator: paymentList, payment_method) => {
        switch switch payment_method {
        | CARD(cardVal) =>
          Some({
            name: "Card",
            componentHoc: (~isScreenFocus, ~setConfirmButtonDataRef) =>
              <CardParent cardVal isScreenFocus setConfirmButtonDataRef />,
          })
        | PAY_LATER(payLaterVal) =>
          let fields =
            redirectionList
            ->Array.find(l => l.name == payLaterVal.payment_method_type)
            ->Option.getOr(Types.defaultRedirectType)

          let klarnaSDKCheck = if (
            payLaterVal.payment_method_type == "klarna" &&
              payLaterVal.payment_experience
              ->Array.find(x => x.payment_experience_type_decode === INVOKE_SDK_CLIENT)
              ->Option.isSome
          ) {
            KlarnaModule.klarnaReactPaymentView->Option.isSome
          } else {
            true
          }

          klarnaSDKCheck
            ? Some({
                name: fields.text,
                componentHoc: (~isScreenFocus, ~setConfirmButtonDataRef) =>
                  <Redirect
                    isScreenFocus redirectProp=PAY_LATER(payLaterVal) fields setConfirmButtonDataRef
                  />,
              })
            : None
        | BANK_REDIRECT(bankRedirectVal) =>
          let fields =
            redirectionList
            ->Array.find(l => l.name == bankRedirectVal.payment_method_type)
            ->Option.getOr(Types.defaultRedirectType)

          Some({
            name: fields.text,
            componentHoc: (~isScreenFocus, ~setConfirmButtonDataRef) =>
              <Redirect
                isScreenFocus
                redirectProp=BANK_REDIRECT(bankRedirectVal)
                fields
                setConfirmButtonDataRef
              />,
          })
        | WALLET(walletVal) =>
          let fields =
            redirectionList
            ->Array.find(l => l.name == walletVal.payment_method_type)
            ->Option.getOr(Types.defaultRedirectType)

          let sessionObject = switch allApiData.sessions {
          | Some(sessionData) =>
            sessionData
            ->Array.find(item => item.wallet_name == walletVal.payment_method_type_wallet)
            ->Option.getOr(SessionsType.defaultToken)
          | _ => SessionsType.defaultToken
          }

          let exp =
            walletVal.payment_experience->Array.find(x =>
              x.payment_experience_type_decode === INVOKE_SDK_CLIENT
            )

          switch walletVal.payment_method_type_wallet {
          | GOOGLE_PAY =>
            ReactNative.Platform.os !== #ios &&
            sessionObject.wallet_name !== NONE &&
            allApiData.additionalPMLData.mandateType != NORMAL
              ? Some({
                  name: fields.text,
                  componentHoc: (~isScreenFocus, ~setConfirmButtonDataRef) =>
                    <Redirect
                      isScreenFocus
                      redirectProp=WALLET(walletVal)
                      fields
                      setConfirmButtonDataRef
                      sessionObject
                    />,
                })
                //exp
              : None
          | PAYPAL =>
            exp->Option.isNone &&
            allApiData.additionalPMLData.mandateType != NORMAL &&
            PaypalModule.payPalModule->Option.isSome
              ? Some({
                  name: fields.text,
                  componentHoc: (~isScreenFocus, ~setConfirmButtonDataRef) =>
                    <Redirect
                      isScreenFocus
                      redirectProp=WALLET(walletVal)
                      fields
                      setConfirmButtonDataRef
                      sessionObject
                    />,
                })
              : walletVal.payment_experience
              ->Array.find(x => x.payment_experience_type_decode === REDIRECT_TO_URL)
              ->Option.isSome
              ? Some({
                name: fields.text,
                componentHoc: (~isScreenFocus, ~setConfirmButtonDataRef) =>
                  <Redirect
                    isScreenFocus redirectProp=WALLET(walletVal) fields setConfirmButtonDataRef
                  />,
              })
              : None
          // walletVal.payment_experience->Array.find(
          //     x => x.payment_experience_type_decode === REDIRECT_TO_URL,
          //   )
          // : exp
          | APPLE_PAY =>
            ReactNative.Platform.os !== #android &&
            sessionObject.wallet_name !== NONE &&
            allApiData.additionalPMLData.mandateType != NORMAL
              ? Some({
                  name: fields.text,
                  componentHoc: (~isScreenFocus, ~setConfirmButtonDataRef) =>
                    <Redirect
                      isScreenFocus
                      redirectProp=WALLET(walletVal)
                      fields
                      setConfirmButtonDataRef
                      sessionObject
                    />,
                })
                //exp
              : None
          | _ =>
            Some({
              name: fields.text,
              componentHoc: (~isScreenFocus, ~setConfirmButtonDataRef) =>
                <Redirect
                  isScreenFocus redirectProp=WALLET(walletVal) fields setConfirmButtonDataRef
                />,
            })
          }
        | OPEN_BANKING(openBankingVal) =>
          let fields =
            redirectionList
            ->Array.find(l => l.name == openBankingVal.payment_method_type)
            ->Option.getOr(Types.defaultRedirectType)

          Plaid.isAvailable
            ? Some({
                name: fields.text,
                componentHoc: (~isScreenFocus, ~setConfirmButtonDataRef) =>
                  <Redirect
                    isScreenFocus
                    redirectProp=OPEN_BANKING(openBankingVal)
                    fields
                    setConfirmButtonDataRef
                  />,
              })
            : None
        | CRYPTO(cryptoVal) =>
          let fields =
            redirectionList
            ->Array.find(l => l.name == cryptoVal.payment_method_type)
            ->Option.getOr(Types.defaultRedirectType)

          Some({
            name: fields.text,
            componentHoc: (~isScreenFocus, ~setConfirmButtonDataRef) =>
              <Redirect
                isScreenFocus redirectProp=CRYPTO(cryptoVal) fields setConfirmButtonDataRef
              />,
          })
        } {
        | Some(tab) =>
          let isInvalidScreen =
            tab.name == "" ||
              accumulator.tabArr
              ->Array.find((item: hoc) => {
                item.name == tab.name
              })
              ->Option.isSome
          if !isInvalidScreen {
            accumulator.tabArr->Array.push(tab)
          }
        | None => ()
        }

        // if !allApiData.isMandate {
        switch switch payment_method {
        | WALLET(walletVal) =>
          let sessionObject = switch allApiData.sessions {
          | Some(sessionData) =>
            sessionData
            ->Array.find(item => item.wallet_name == walletVal.payment_method_type_wallet)
            ->Option.getOr(SessionsType.defaultToken)
          | _ => SessionsType.defaultToken
          }

          let exp =
            walletVal.payment_experience->Array.find(x =>
              x.payment_experience_type_decode === INVOKE_SDK_CLIENT
            )
          switch switch walletVal.payment_method_type_wallet {
          | GOOGLE_PAY =>
            ReactNative.Platform.os !== #ios &&
            sessionObject.wallet_name !== NONE &&
            sessionObject.connector !== "trustpay"
              ? {
                  if ReactNative.Platform.os === #web {
                    addGooglePay(~sessionObject, ~requiredFields=walletVal.required_field)
                  }
                  exp
                }
              : None
          | PAYPAL =>
            exp->Option.isSome && PaypalModule.payPalModule->Option.isSome
              ? exp
              : walletVal.payment_experience->Array.find(x =>
                  x.payment_experience_type_decode === REDIRECT_TO_URL
                )
          | APPLE_PAY =>
            ReactNative.Platform.os !== #android && sessionObject.wallet_name !== NONE
              ? {
                  if ReactNative.Platform.os === #web {
                    Promise.make((resolve, _) => {
                      addApplePay(~sessionObject, ~resolve)
                    })
                    // ->Promise.then(isApplePaySupported => {
                    //   isApplePaySupported ? exp : None
                    //   Promise.resolve()
                    // })
                    ->ignore
                  }
                  exp
                }
              : None
          | _ => None
          } {
          | None => None
          | Some(exp) =>
            Some({
              walletType: {
                payment_method: walletVal.payment_method,
                payment_method_type: walletVal.payment_method_type,
                payment_method_type_wallet: walletVal.payment_method_type_wallet,
                payment_experience: [exp],
                required_field: walletVal.required_field,
              },
              sessionObject,
            })
          }
        | _ => None
        } {
        | Some(walletProp) =>
          accumulator.elementArr
          ->Array.push(
            <ButtonElement
              key=walletProp.walletType.payment_method_type
              walletType=walletProp.walletType
              sessionObject={walletProp.sessionObject}
            />,
          )
          ->ignore
        | None => ()
        }

        // }
        accumulator
      },
    )
  }
  // }, (pmList, sessionData))
}

let widgetModifier = (
  pmList: array<PaymentMethodListType.payment_method>,
  sessionData: AllApiDataContext.sessions,
  widgetType,
  confirm,
) => {
  let modifiedList = pmList->Array.reduce([], (accumulator, payment_method) => {
    switch payment_method {
    | WALLET(walletVal) =>
      widgetType == walletVal.payment_method_type_wallet
        ? {
            let sessionObject = switch sessionData {
            | Some(sessionData) =>
              sessionData
              ->Array.find(item => item.wallet_name == walletVal.payment_method_type_wallet)
              ->Option.getOr(SessionsType.defaultToken)
            | _ => SessionsType.defaultToken
            }
            let exp =
              walletVal.payment_experience->Array.find(x =>
                x.payment_experience_type_decode === INVOKE_SDK_CLIENT
              )
            switch switch walletVal.payment_method_type_wallet {
            | GOOGLE_PAY =>
              ReactNative.Platform.os !== #ios && sessionObject.wallet_name !== NONE ? exp : None
            | PAYPAL =>
              exp->Option.isNone
                ? walletVal.payment_experience->Array.find(x =>
                    x.payment_experience_type_decode === REDIRECT_TO_URL
                  )
                : exp
            | APPLE_PAY =>
              ReactNative.Platform.os !== #android && sessionObject.wallet_name !== NONE
                ? exp
                : None
            | _ => None
            } {
            | Some(exp) =>
              accumulator
              ->Array.push(
                <ButtonElement
                  walletType={
                    payment_method: walletVal.payment_method,
                    payment_method_type: walletVal.payment_method_type,
                    payment_method_type_wallet: walletVal.payment_method_type_wallet,
                    payment_experience: [exp],
                    required_field: walletVal.required_field,
                  }
                  sessionObject
                  confirm
                />,
              )
              ->ignore
            | None => ()
            }
          }
        : ()
    | _ => ()
    }
    accumulator
  })

  switch modifiedList->Array.length {
  | 0 => Some(React.null)
  | _ => modifiedList->Array.get(0)
  }
}
