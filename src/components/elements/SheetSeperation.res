@react.component
let make = () => {
  let localeObject = GetLocale.useGetLocalObj()

  <TextWithLine text=localeObject.orPayUsing />
}
