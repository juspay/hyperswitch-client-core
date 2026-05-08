open ReactNative
open Style

@react.component
let make = (~plan: AccountPaymentMethodType.installmentPlan, ~currency, ~isSelected, ~onSelect, ~isLastItem) => {
  let {primaryColor, component} = ThemebasedStyle.useThemeBasedStyle()
  let localeObject = GetLocale.useGetLocalObj()

  let paymentLabel = Utils.replaceLocaleParams(
    localeObject.installmentPaymentLabel,
    [
      ("count", plan.number_of_installments->Int.toString),
      ("amount", Utils.formatAmountWithTwoDecimals(plan.amount_details.amount_per_installment)),
    ],
  )

  let interestText = if plan.interest_rate == 0.0 {
    localeObject.installmentInterestFree
  } else {
    Utils.replaceLocaleParams(
      localeObject.installmentInterestRate,
      [("rate", Utils.formatAmountWithTwoDecimals(plan.interest_rate))],
    )
  }

  let totalLabel = localeObject.installmentTotalPayable

  let totalAmount = currency ++ " " ++ Utils.formatAmountWithTwoDecimals(plan.amount_details.total_amount)

  <CustomPressable onPress={_ => onSelect()}>
    <View
      style={array([
        s({
          flexDirection: #row,
          alignItems: #center,
          paddingVertical: 12.->dp,
          paddingHorizontal: 4.->dp,
        }),
        isLastItem ? empty : s({borderBottomWidth: 1., borderColor: component.dividerColor}),
      ])}>
      <CustomRadioButton selected=isSelected color=primaryColor />
      <Space width=12. />
      <View style={s({flex: 1.})}>
        <View style={s({flexDirection: #row, justifyContent: #"space-between"})}>
          <TextWrapper text=paymentLabel textType=ModalTextBold />
          <TextWrapper text=totalLabel textType=ModalTextLight />
        </View>
        <View style={s({flexDirection: #row, justifyContent: #"space-between", marginTop: 2.->dp})}>
          <TextWrapper text=interestText textType=ModalTextLight />
          <TextWrapper text=totalAmount textType=ModalTextBold />
        </View>
      </View>
    </View>
  </CustomPressable>
}
