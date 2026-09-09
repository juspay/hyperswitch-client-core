open PaymentMethodTypes

module Hyperswitch = {
  @module("@juspay-tech/react-native-hyperswitch-payment-methods") @scope("Hyperswitch")
  external init: hyperswitchConfiguration => promise<hyperswitchInstance> = "init"
}

type fieldProps = {
  form?: cardFormInstance,
  styles?: JSON.t,
  options?: JSON.t,
  placeholder?: string,
}

module CardNumberField = {
  @module("@juspay-tech/react-native-hyperswitch-payment-methods")
  external make: React.component<fieldProps> = "CardNumberField"
}

module CardExpiryField = {
  @module("@juspay-tech/react-native-hyperswitch-payment-methods")
  external make: React.component<fieldProps> = "CardExpiryField"
}

module CardCVCField = {
  @module("@juspay-tech/react-native-hyperswitch-payment-methods")
  external make: React.component<fieldProps> = "CardCVCField"
}

module CardholderNameField = {
  @module("@juspay-tech/react-native-hyperswitch-payment-methods")
  external make: React.component<fieldProps> = "CardholderNameField"
}

let runPaymentMethodsTask = (launchProps: launchProps): promise<unit> =>
  Hyperswitch.init(launchProps.hyperswitchConfig)
  ->Promise.then(hyper => {
    setHyper(hyper)
    hyper.initPaymentMethodSession({sdkAuthorization: launchProps.session.sdkAuthorization})
  })
  ->Promise.then(pms => {
    setPms(pms)
    setCardForm(pms.createCardForm({appearance: ?launchProps.configuration.appearance}))
    Promise.resolve()
  })


let buildTokenResultPayload = (json: JSON.t): JSON.t => {
  let dict = json->Utils.getDictFromJson
  let status = dict->Utils.getString("status", "error")
  let vaultType = dict->Utils.getOptionString("vaultType")
  let card = dict->Utils.getOptionalObj("card")
  let error = dict->Utils.getOptionalObj("error")
  let token =
    dict
    ->Utils.getOptionalObj("data")
    ->Option.flatMap(data => data->Utils.getOptionalObj("tokens"))
    ->Option.flatMap(tokens => tokens->Utils.getOptionString("payment_method_token"))

  [
    ("status", status->JSON.Encode.string),
    ("vaultType", vaultType->Option.map(JSON.Encode.string)->Option.getOr(JSON.Encode.null)),
    ("token", token->Option.map(JSON.Encode.string)->Option.getOr(JSON.Encode.null)),
    ("card", card->Option.map(JSON.Encode.object)->Option.getOr(JSON.Encode.null)),
    ("error", error->Option.map(JSON.Encode.object)->Option.getOr(JSON.Encode.null)),
  ]
  ->Dict.fromArray
  ->JSON.Encode.object
}

module PaymentMethodsTask = {
  @react.component
  let make = (~props: JSON.t) => {
    React.useEffect0(() => {
      runPaymentMethodsTask(parseLaunchProps(props->Utils.getDictFromJson))
      ->Promise.catch(err => {
        Console.error2("payment-methods: PaymentMethodsTask initialization failed", err)
        Promise.resolve()
      })
      ->ignore
      None
    })

    React.useEffect0(() => {
      let unsubscribe = PaymentMethodModule.subscribeTokenise(payload => {
        let rootTag = payload->Utils.getOptionInt("rootTag")->Option.getOr(-1)
        switch getCardForm() {
        | Some(form) =>
          form.tokenize(None)
          ->Promise.then(json => {
            PaymentMethodModule.returnTokenResult(rootTag, json->buildTokenResultPayload)
            Promise.resolve()
          })
          ->Promise.catch(err => {
            Console.error2("payment-methods: tokenize failed", err)
            Promise.resolve()
          })
          ->ignore
        | None => ()
        }
      })
      Some(unsubscribe)
    })

    React.null
  }
}

module PaymentMethodField = {
  @react.component
  let make = (~surface: paymentMethodsSurface, ~configuration: fieldConfiguration) => {
    let (cardForm, setCardForm) = React.useState(getCardForm)

    React.useEffect0(() =>
      switch cardForm {
      | Some(_) => None
      | None =>
        let intervalRef = ref(None)
        intervalRef := Some(setInterval(() =>
              switch getCardForm() {
              | Some(next) => {
                  intervalRef.contents->Option.forEach(clearInterval)
                  setCardForm(_ => Some(next))
                }
              | None => ()
              }
            , 50))
        Some(() => intervalRef.contents->Option.forEach(clearInterval))
      }
    )

    switch (surface, cardForm) {
    | (CardNumberInput, Some(form)) =>
      <CardNumberField
        form
        styles=?{configuration.styles}
        options=?{configuration.options}
        placeholder=?{configuration.placeholder}
      />
    | (CardExpiryInput, Some(form)) =>
      <CardExpiryField
        form
        styles=?{configuration.styles}
        options=?{configuration.options}
        placeholder=?{configuration.placeholder}
      />
    | (CardCVCInput, Some(form)) =>
      <CardCVCField
        form
        styles=?{configuration.styles}
        options=?{configuration.options}
        placeholder=?{configuration.placeholder}
      />
    | (CardHolderNameInput, Some(form)) =>
      <CardholderNameField
        form
        styles=?{configuration.styles}
        options=?{configuration.options}
        placeholder=?{configuration.placeholder}
      />
    | _ => React.null
    }
  }
}

@react.component
let make = (~props: JSON.t) => {
  let launchProps = parseLaunchProps(props->Utils.getDictFromJson)

  switch launchProps.surface {
  | PaymentMethodsTask => <PaymentMethodsTask props />
  | surface => <PaymentMethodField surface configuration={launchProps.configuration} />
  }
}
