open ReactNative
open Style

@react.component
let make = (
  ~installmentOptions: array<AccountPaymentMethodType.installmentOption>,
  ~currency,
  ~paymentMethod,
  ~selectedInstallmentPlan: option<AccountPaymentMethodType.installmentPlan>,
  ~setSelectedInstallmentPlan,
  ~showInstallments,
  ~setShowInstallments,
  ~errorString,
  ~setErrorString,
) => {
  let localeObject = GetLocale.useGetLocalObj()

  let plans = PaymentUtils.filterInstallmentPlansByPaymentMethod(installmentOptions, paymentMethod)

  React.useEffect0(() => {
    Some(
      () => {
        setShowInstallments(_ => false)
        setSelectedInstallmentPlan(_ => None)
        setErrorString(_ => "")
      },
    )
  })

  let onCheckboxToggle = checked => {
    setShowInstallments(_ => checked)
    if !checked {
      setSelectedInstallmentPlan(_ => None)
      setErrorString(_ => "")
    }
  }

  <UIUtils.RenderIf condition={plans->Array.length > 0}>
    <View style={s({marginTop: 16.->dp})}>
      <ClickableTextElement
        initialIconName="checkboxclicked"
        updateIconName={Some("checkboxnotclicked")}
        text=localeObject.installmentPayInInstallments
        isSelected=showInstallments
        setIsSelected={onCheckboxToggle}
        textType=ModalText
      />
      <UIUtils.RenderIf condition=showInstallments>
        <View style={s({marginTop: 12.->dp, marginLeft: 4.->dp})}>
          <TextWrapper text=localeObject.installmentChoosePlan textType=ModalTextLight />
          <Space height=8. />
          <ScrollView style={s({maxHeight: 250.->dp})}>
            {plans
            ->Array.mapWithIndex((plan, index) =>
              <InstallmentOptionItem
                key={index->Int.toString}
                plan
                currency
                isSelected={selectedInstallmentPlan->Option.mapOr(false, selected =>
                  selected.number_of_installments === plan.number_of_installments &&
                    selected.interest_rate === plan.interest_rate
                )}
                onSelect={() => {
                  setSelectedInstallmentPlan(_ => Some(plan))
                  setErrorString(_ => "")
                }}
                isLastItem={index === plans->Array.length - 1}
              />
            )
            ->React.array}
          </ScrollView>
        </View>
      </UIUtils.RenderIf>
      <UIUtils.RenderIf condition={errorString->String.length > 0}>
        <TextWrapper text=errorString textType=ErrorText />
      </UIUtils.RenderIf>
    </View>
  </UIUtils.RenderIf>
}
