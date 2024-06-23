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
  ~savedCardCvv,
  ~setSavedCardCvv,
  ~setIsCvcValid,
) => {
  let {borderRadius, component, shadowColor, shadowIntensity} = ThemebasedStyle.useThemeBasedStyle()
  let (selected, isSelected) = React.useState(_ => true)
  let shadowOffsetHeight = shadowIntensity
  let elevation = shadowIntensity
  let shadowRadius = shadowIntensity
  let shadowOpacity = 0.2
  let shadowOffsetWidth = 0.
  let localeObj = GetLocale.useGetLocalObj()

  <View style={viewStyle(~marginHorizontal=5.->pct, ~marginVertical=3.->pct, ())}>
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
            ~paddingHorizontal=24.->dp,
            ~paddingVertical=5.->dp,
            ~borderRadius,
            ~borderColor=component.borderColor,
            ~backgroundColor=component.background,
            (),
          ),
        ])}>
        <SavedPMListWithLoader
          listArr={savedPaymentMethodsData}
          setIsAllDynamicFieldValid
          setDynamicFieldsJson
          savedCardCvv
          setSavedCardCvv
          setIsCvcValid
        />
      </View>
      <Space height=20. />
      <ClickableTextElement
        initialIconName="addwithcircle"
        text="Add new payment method"
        isSelected=selected
        setIsSelected=isSelected
        textType={TextWrapper.LinkTextBold}
        fillIcon=false
      />
      {showSavePMCheckbox
        ? <>
            <Space />
            <ClickableTextElement
              disabled={false}
              initialIconName="checkboxClicked"
              updateIconName=Some("checkboxNotClicked")
              text={localeObj.cardTerms(merchantName)}
              isSelected={isSaveCardCheckboxSelected}
              setIsSelected={setSaveCardChecboxSelected}
              textType={TextWrapper.ModalText}
              disableScreenSwitch=true
            />
          </>
        : React.null}
    </View>
  </View>
}
