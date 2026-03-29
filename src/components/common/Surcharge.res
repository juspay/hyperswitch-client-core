open ReactNative
open Style

@react.component
let make = (~paymentMethodData: AccountPaymentMethodType.payment_method_type) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let (accountPaymentMethodData, _, _) = React.useContext(AllApiDataContextNew.allApiDataContext)
  let localeObject = GetLocale.useGetLocalObj()

  let showShortSurchargeMessage = nativeProp.configuration.showShortSurchargeMessage
  let currency =
    accountPaymentMethodData->Option.map(data => data.currency)->Option.getOr("")
  let paymentMethod = paymentMethodData.payment_method_str

  let surchargeMessage = React.useMemo3(() => {
    // First check payment_method_type level surcharge
    switch paymentMethodData.surcharge_details {
    | Some(surchargeDetails) =>
      SurchargeUtils.getSurchargeMessage(
        ~surchargeDetails,
        ~paymentMethod,
        ~currency,
        ~showShortSurchargeMessage,
        ~localeObject,
      )
    | None =>
      // For cards, check card_networks level surcharge (pick the higher of credit/debit)
      if paymentMethod === "card" {
        let maxSurcharge =
          paymentMethodData.card_networks->Array.reduce(None, (acc, network) => {
            switch (acc, network.surcharge_details) {
            | (None, Some(sd)) => Some(sd)
            | (Some(existing), Some(sd)) =>
              sd.displayTotalSurchargeAmount > existing.displayTotalSurchargeAmount
                ? Some(sd)
                : Some(existing)
            | (existing, None) => existing
            }
          })
        switch maxSurcharge {
        | Some(surchargeDetails) =>
          SurchargeUtils.getSurchargeMessage(
            ~surchargeDetails,
            ~paymentMethod,
            ~currency,
            ~showShortSurchargeMessage,
            ~localeObject,
          )
        | None => None
        }
      } else {
        None
      }
    }
  }, (paymentMethodData, showShortSurchargeMessage, currency))

  switch surchargeMessage {
  | Some(message) =>
    <View
      style={s({
        flexDirection: #row,
        alignItems: #"flex-start",
        marginTop: 8.->dp,
        paddingHorizontal: 2.->dp,
      })}>
      <TextWrapper text="* " textType={ErrorText} />
      <TextWrapper text=message textType={ModalTextLight} />
    </View>
  | None => React.null
  }
}
