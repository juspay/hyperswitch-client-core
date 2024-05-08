open ReactNative
open ReactNative.Style

@react.component
let make = (
  ~savedPaymentMethodsData,
  ~error,
  ~setIsAllDynamicFieldValid,
  ~setDynamicFieldsJson,
) => {
  let {borderRadius, component, shadowColor, shadowIntensity} = ThemebasedStyle.useThemeBasedStyle()
  let (selected, isSelected) = React.useState(_ => true)
  let shadowOffsetHeight = shadowIntensity
  let elevation = shadowIntensity
  let shadowRadius = shadowIntensity
  let shadowOpacity = 0.2
  let shadowOffsetWidth = 0.

  <View style={viewStyle(~marginHorizontal=18.->dp, ())}>
    <View>
      <View
        style={array([
          viewStyle(
            ~elevation,
            ~shadowRadius,
            ~shadowOpacity,
            ~shadowOffset={
              offset(~width=shadowOffsetWidth, ~height=shadowOffsetHeight /. 2.)
            },
            ~shadowColor,
            ~paddingHorizontal=15.->dp,
            ~paddingVertical=6.->dp,
            ~borderRadius,
            ~borderColor=component.borderColor,
            ~backgroundColor=component.background,
            (),
          ),
        ])}>
        <SavedPMListWithLoader
          listArr={savedPaymentMethodsData} setIsAllDynamicFieldValid setDynamicFieldsJson
        />
      </View>
      <Space height=20. />
      <View>
        <ClickableTextElement
          initialIconName="addwithcircle"
          text="Add new payment method"
          isSelected=selected
          setIsSelected=isSelected
          textType={LinkTextBold}
          fillIcon=false
        />
      </View>
      <Space />
    </View>
    <ErrorText text=error />
  </View>
}
