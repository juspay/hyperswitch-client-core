open ReactNative
open Style

module GiftCardListComponent = {
  @react.component
  let make = React.memo((~giftCardArr: array<ClientListType.paymentMethodEnabled>) => {
    let (selectedGiftCardType, setSelectedGiftCardType) = React.useState(() =>
      giftCardArr
      ->Array.get(0)
      ->Option.map(payment_method_type => payment_method_type.payment_method_type)
    )

    let items = giftCardArr->Array.map(payment_method_type => {
      SdkTypes.label: payment_method_type.payment_method_type->CommonUtils.getDisplayName,
      value: payment_method_type.payment_method_type,
      icon: payment_method_type.payment_method_type->CommonUtils.getDisplayName,
    })

    let {formDataRef, getRequiredFieldsForTabs, country, _} = React.useContext(
      DynamicFieldsContext.dynamicFieldsContext,
    )

    let (formData, setFormData) = React.useState(_ => Dict.make())
    let setFormData = React.useCallback1(data => {
      formDataRef->Option.map(ref => ref.current = data)->ignore
      setFormData(_ => data)
    }, [setFormData])

    let (_isFormValid, setIsFormValid) = React.useState(_ => false)
    let setIsFormValid = React.useCallback1(isValid => {
      setIsFormValid(_ => isValid)
    }, [setIsFormValid])

    let (_formMethods, setFormMethods) = React.useState(_ => None)
    let setFormMethods = React.useCallback1(formSubmit => {
      setFormMethods(_ => formSubmit)
    }, [setFormMethods])

    let (
      requiredFields,
      initialValues,
      _,
      enabledCardSchemes,
      accessible,
      _,
    ) = React.useMemo3(_ => {
      switch selectedGiftCardType {
      | Some(selectedGiftCardType) =>
        switch giftCardArr->Array.find(
          payment_method_type => payment_method_type.payment_method_type === selectedGiftCardType,
        ) {
        | Some(data) => getRequiredFieldsForTabs(data, formData, true)
        | None => ([], Dict.make(), false, [], true, "")
        }

      | None => ([], Dict.make(), false, [], true, "")
      }
    }, (selectedGiftCardType, getRequiredFieldsForTabs, country))

    <View style={s({paddingHorizontal: 22.->dp, paddingBottom: 20.->dp})}>
      <Space />
      <CustomPicker
        value=selectedGiftCardType
        setValue=setSelectedGiftCardType
        placeholderText="Gift Card"
        items
        onFocus={() => ()}
        onBlur={() => ()}
        animate=false
      />
      <Space />
      <DynamicFields
        fields=requiredFields
        initialValues
        setFormData
        setIsFormValid
        setFormMethods
        isGiftCardPayment=true
        enabledCardSchemes
        accessible
      />
    </View>
  })
}

@react.component
let make = (~isLoading, ~giftCardArr, ~style=empty) => {
  let (expanded, setExpanded) = React.useState(_ => false)

  let {
    bgColor,
    primaryColor,
    component,
    borderRadius,
    borderWidth,
    shadowConfig,
  } = ThemebasedStyle.useThemeBasedStyle()
  let getShadowStyle = ShadowHook.useGetShadowStyle(~shadowConfig, ())

  {
    !isLoading && giftCardArr->Array.length === 0
      ? React.null
      : <>
          <Space />
          {isLoading
            ? <CustomLoader />
            : <View
                style={array([
                  bgColor,
                  getShadowStyle,
                  s({
                    borderWidth,
                    borderColor: expanded ? primaryColor : component.borderColor,
                    borderRadius,
                  }),
                  style,
                ])}>
                <CustomPressable
                  onPress={_ => setExpanded(v => !v)}
                  style={s({
                    flexDirection: #row,
                    alignItems: #center,
                    justifyContent: #"space-between",
                    padding: 20.->dp,
                  })}>
                  <View
                    style={s({
                      flexDirection: #row,
                      alignItems: #center,
                      justifyContent: #center,
                      textAlign: #center,
                    })}>
                    <Icon name="gift" width=22. height=22. />
                    <Space width=10. />
                    <TextWrapper text="Have a gift card?" textType=TextWrapper.Subheading />
                  </View>
                  <Icon name="chevron" width=14. height=14. fill="#525866" />
                </CustomPressable>
                {expanded ? <GiftCardListComponent giftCardArr /> : React.null}
              </View>}
        </>
  }
}
