let getSurchargeMessage = (
  ~surchargeDetails: AccountPaymentMethodType.surchargeDetails,
  ~paymentMethod: string,
  ~currency: string,
  ~showShortSurchargeMessage: bool,
  ~localeObject: LocaleDataType.localeStrings,
) => {
  let surchargeValue = surchargeDetails.displayTotalSurchargeAmount->Float.toString

  if showShortSurchargeMessage {
    Some(localeObject.shortSurchargeMessage ++ currency ++ " " ++ surchargeValue)
  } else if paymentMethod === "card" {
    Some(
      localeObject.surchargeMsgAmountForCardPart1 ++
      currency ++
      " " ++
      surchargeValue ++
      localeObject.surchargeMsgAmountForCardPart2,
    )
  } else {
    Some(
      localeObject.surchargeMsgAmountPart1 ++
      currency ++
      " " ++
      surchargeValue ++
      localeObject.surchargeMsgAmountPart2,
    )
  }
}
