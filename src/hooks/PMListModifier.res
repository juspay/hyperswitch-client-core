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
  let (pmList, _) = React.useContext(PaymentListContext.paymentListContext)
  let (sessionData, _) = React.useContext(SessionContext.sessionContext)
  let (allApiData, _) = React.useContext(AllApiDataContext.allApiDataContext)

  React.useMemo2(() => {
    let redirectionList = Types.defaultConfig.redirectionList
    pmList->Array.reduce(
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

          Some({
            name: fields.text,
            componentHoc: (~isScreenFocus, ~setConfirmButtonDataRef) =>
              <Redirect
                isScreenFocus redirectProp=PAY_LATER(payLaterVal) fields setConfirmButtonDataRef
              />,
          })
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

          let sessionObject = switch sessionData {
          | Some(sessionData) =>
            sessionData
            ->Array.find(item => item.wallet_name == walletVal.payment_method_type_wallet)
            ->Option.getOr(SessionsType.defaultToken)
          | _ => SessionsType.defaultToken
          }

          let exp =
            walletVal.payment_experience->Array.find(
              x => x.payment_experience_type_decode === INVOKE_SDK_CLIENT,
            )

          switch walletVal.payment_method_type_wallet {
          | GOOGLE_PAY =>
            ReactNative.Platform.os !== #ios &&
            sessionObject.wallet_name !== NONE &&
            allApiData.mandateType != NORMAL
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
            exp->Option.isNone && allApiData.mandateType != NORMAL
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
              : Some({
                  name: fields.text,
                  componentHoc: (~isScreenFocus, ~setConfirmButtonDataRef) =>
                    <Redirect
                      isScreenFocus redirectProp=WALLET(walletVal) fields setConfirmButtonDataRef
                    />,
                })
          // walletVal.payment_experience->Array.find(
          //     x => x.payment_experience_type_decode === REDIRECT_TO_URL,
          //   )
          // : exp
          | APPLE_PAY =>
            ReactNative.Platform.os !== #android &&
            sessionObject.wallet_name !== NONE &&
            allApiData.mandateType != NORMAL
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
              ->Array.find(
                (item: hoc) => {
                  item.name == tab.name
                },
              )
              ->Option.isSome
          if !isInvalidScreen {
            accumulator.tabArr->Array.push(tab)
          }
        | None => ()
        }

        // if !allApiData.isMandate {
        switch switch payment_method {
        | WALLET(walletVal) =>
          let sessionObject = switch sessionData {
          | Some(sessionData) =>
            sessionData
            ->Array.find(item => item.wallet_name == walletVal.payment_method_type_wallet)
            ->Option.getOr(SessionsType.defaultToken)
          | _ => SessionsType.defaultToken
          }

          let exp =
            walletVal.payment_experience->Array.find(
              x => x.payment_experience_type_decode === INVOKE_SDK_CLIENT,
            )
          switch switch walletVal.payment_method_type_wallet {
          | GOOGLE_PAY =>
            ReactNative.Platform.os !== #ios && sessionObject.wallet_name !== NONE ? exp : None
          | PAYPAL =>
            exp->Option.isNone
              ? walletVal.payment_experience->Array.find(
                  x => x.payment_experience_type_decode === REDIRECT_TO_URL,
                )
              : exp
          | APPLE_PAY =>
            ReactNative.Platform.os !== #android && sessionObject.wallet_name !== NONE ? exp : None
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
  }, (pmList, sessionData))
}

let widgetModifier = (
  pmList: array<PaymentMethodListType.payment_method>,
  sessionData: SessionContext.sessions,
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
                  buttonSize={CustomButton.Small}
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
  | _ => modifiedList[0]
  }
}
