@react.component
let make = (
  ~requiredFields,
  ~initialValues,
  ~onFormChange,
  ~onValidationChange,
  ~onFormMethodsChange,
  ~cardNetworks,
) => {
  <>
    <UIUtils.RenderIf condition={requiredFields->Array.length > 0}>
      <DynamicFields
        fields=requiredFields
        initialValues
        onFormChange
        onValidationChange
        onFormMethodsChange
        cardNetworks
      />
    </UIUtils.RenderIf>
    <UIUtils.RenderIf condition={cardNetworks->Array.length === 0}>
      <Space height=?{requiredFields->Array.length === 0 ? Some(36.) : None} />
      <RedirectionText />
    </UIUtils.RenderIf>
  </>
}
