open ReactNative
open ReactNative.Style

@react.component
let make = (
  ~savedPaymentMethodsData,
  ~setIsAllDynamicFieldValid,
  ~setDynamicFieldsJson,
  ~isSaveCardCheckboxSelected,
  ~setSaveCardChecboxSelected,
  ~showSavePMCheckbox,
  ~merchantName,
) => {
  let {borderRadius, component, shadowColor, shadowIntensity} = ThemebasedStyle.useThemeBasedStyle()
  let (selected, isSelected) = React.useState(_ => true)
  let shadowOffsetHeight = shadowIntensity
  let elevation = shadowIntensity
  let shadowRadius = shadowIntensity
  let shadowOpacity = 0.2
  let shadowOffsetWidth = 0.
  let localeObj = GetLocale.useGetLocalObj()

  <View style={viewStyle(~marginHorizontal=5.->pct, ())}>
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
          textType={TextWrapper.TextActive}
          fillIcon=false
        />
      </View>
      {showSavePMCheckbox
        ? <>
            <Space height=20. />
            // <View style={viewStyle(~margin=5.->pct, ())}>
            <ClickableTextElement
              disabled={false}
              initialIconName="checkboxClicked"
              updateIconName="checkboxNotClicked"
              text={localeObj.cardTerms(merchantName)}
              isSelected={isSaveCardCheckboxSelected}
              setIsSelected={setSaveCardChecboxSelected}
              textType={TextWrapper.ModalText}
              disableScreenSwitch=true
            />
            // </View>
          </>
        : React.null}
      <Space height=12. />
    </View>
  </View>
}
