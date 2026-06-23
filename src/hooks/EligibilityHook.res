let useCheckEligibility = (~paymentMethodData: AccountPaymentMethodType.payment_method_type) => {
  let (accountPaymentMethodData, _, _) = React.useContext(AllApiDataContextNew.allApiDataContext)
  let {setEligibilityStatus} = React.useContext(DynamicFieldsContext.dynamicFieldsContext)
  let callEligibilityCheck = AllPaymentHooks.useEligibilityCheckHook()

  (cardNumberOpt: option<string>) => {
    switch cardNumberOpt {
    | None => setEligibilityStatus(_ => Allowed)
    | Some(cardNumber) =>
      let shouldCheck =
        accountPaymentMethodData
        ->Option.flatMap(d => d.sdk_next_action)
        ->Option.mapOr(false, action => action == "eligibility_check")

      if shouldCheck {
        setEligibilityStatus(_ => Pending)
        let pmData =
          [
            (
              paymentMethodData.payment_method_str,
              [("card_number", cardNumber->JSON.Encode.string)]
              ->Dict.fromArray
              ->JSON.Encode.object,
            ),
          ]
          ->Dict.fromArray
          ->JSON.Encode.object
        callEligibilityCheck(
          ~paymentMethodType=paymentMethodData.payment_method_str,
          ~paymentMethodData=pmData,
        )
        ->Promise.then(json => {
          let nextActionJson =
            json
            ->Utils.getDictFromJson
            ->Utils.getOptionalObj("sdk_next_action")
            ->Option.flatMap(d => d->Dict.get("next_action"))
          let isDenied = switch nextActionJson {
          | Some(json) =>
            switch JSON.Decode.string(json) {
            | Some("deny") => true
            | Some(_) => false
            | None => json->Utils.getDictFromJson->Dict.get("deny")->Option.isSome
            }
          | None => false
          }
          setEligibilityStatus(_ => isDenied ? Denied : Allowed)
          Promise.resolve()
        })
        ->Promise.catch(_ => {
          setEligibilityStatus(_ => Allowed)
          Promise.resolve()
        })
        ->ignore
      } else {
        setEligibilityStatus(_ => Allowed)
      }
    }
  }
}
