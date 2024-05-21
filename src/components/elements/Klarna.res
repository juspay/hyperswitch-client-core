open ReactNative

external toViewRef: React.ref<Nullable.t<'a>> => Ref.t<KlarnaModule.element> = "%identity"
@send external focus: Dom.element => unit = "focus"
@send external blur: Dom.element => unit = "blur"

@react.component
let make = (
  ~launchKlarna: option<PaymentMethodListType.payment_method_types_pay_later>,
  ~return_url,
  ~klarnaSessionTokens: string,
  ~processRequest: (PaymentMethodListType.payment_method_types_pay_later, string) => unit,
) => {
  let (_paymentViewLoaded, setpaymentViewLoaded) = React.useState(_ => false)
  let (_token, _) = React.useState(_ => None)
  let paymentMethods = ["pay_later"] //["pay_now", "pay_later", "pay_over_time", "pay_in_parts"]

  let refs = React.useRef(Nullable.null)
  let handleSuccessFailure = AllPaymentHooks.useHandleSuccessFailure()

  React.useEffect1(() => {
    switch refs.current->Nullable.toOption {
    | None => ()
    | Some(ref) =>
      ref
      ->Nullable.toOption
      ->Option.forEach((view: KlarnaModule.element) =>
        view.initialize(klarnaSessionTokens, return_url)
      )
    }
    None
  }, [refs])

  let onInitialized = () => {
    switch refs.current->Nullable.toOption {
    | None => ()
    | Some(ref) => ref->Nullable.toOption->Option.forEach(view => view.load())
    }
  }

  let onLoaded = () => {
    setpaymentViewLoaded(_ => true)
  }

  let buyButtonPressed = _ => {
    switch refs.current->Nullable.toOption {
    | None => ()
    | Some(ref) => ref->Nullable.toOption->Option.forEach(view => view.authorize())
    }
    ()
  }

  React.useEffect1(() => {
    if launchKlarna->Option.isSome {
      buyButtonPressed()
    }
    None
  }, [launchKlarna])

  let onAuthorized = (event: KlarnaModule.event) => {
    let params = event.nativeEvent
    if (Platform.os == #ios || params.approved) && params.authToken !== None {
      switch launchKlarna {
      | Some(prop) => processRequest(prop, params.authToken->Option.getOr(""))
      | _ =>
        handleSuccessFailure(
          ~apiResStatus={status: "failed", message: "", code: "", type_: ""},
          ~closeSDK=false,
          (),
        )
      }
    } else {
      switch params.errorMessage {
      | None =>
        handleSuccessFailure(~apiResStatus={status: "failed", message: "", code: "", type_: ""}, ())
      | Some(err) =>
        handleSuccessFailure(~apiResStatus={status: err, message: "", code: "", type_: ""}, ())
      }
    }
  }

  <ScrollView
    pointerEvents=#none style={Style.viewStyle(~height=220.->Style.dp, ~borderRadius=15., ())}>
    {React.array(
      Array.map(paymentMethods, paymentMethod => {
        <KlarnaModule
          paymentMethod reference={refs->toViewRef} onInitialized onLoaded onAuthorized
        />
      }),
    )}
  </ScrollView>
}
