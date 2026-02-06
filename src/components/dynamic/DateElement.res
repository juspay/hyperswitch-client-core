open ReactNative
open Style

module DatePicker = {
  @react.component
  let make = (
    ~fieldProps as {input, meta}: ReactFinalForm.Field.fieldProps,
    ~placeholder,
    ~accessible,
  ) => {
    let (day, setDay) = React.useState(_ => "")
    let (month, setMonth) = React.useState(_ => "")
    let (year, setYear) = React.useState(_ => "")

    let fontFamily = FontFamily.useCustomFontFamily()
    let {
      placeholderColor,
      placeholderTextSizeAdjust,
      fontScale,
    } = ThemebasedStyle.useThemeBasedStyle()

    let handleInputChange = (value: string) => {
      input.onChange(value)
    }

    React.useEffect3(() => {
      if day != "" && month != "" && year != "" {
        let maxDays = Utils.getDaysInMonth(month, year)
        let currentDay = day->Int.fromString->Option.getOr(1)
        if currentDay > maxDays {
          let newDay = maxDays->Int.toString
          setDay(_ => newDay)
        } else {
          let dateString = `${year}-${month->String.padStart(2, "0")}-${day->String.padStart(
              2,
              "0",
            )}`
          handleInputChange(dateString)
        }
      }
      None
    }, (day, month, year))

    let (dayItems, monthItems, yearItems) = React.useMemo2(() => {
      let maxDays = Utils.getDaysInMonth(month, year)
      let dayItems = []
      Belt.Range.forEach(1, maxDays, y => {
        let dateStr = y->Int.toString
        dayItems->Array.push({SdkTypes.label: dateStr, value: dateStr})
      })
      let monthItems = [
        {SdkTypes.label: "Jan", value: "01"},
        {label: "Feb", value: "02"},
        {label: "Mar", value: "03"},
        {label: "Apr", value: "04"},
        {label: "May", value: "05"},
        {label: "Jun", value: "06"},
        {label: "Jul", value: "07"},
        {label: "Aug", value: "08"},
        {label: "Sep", value: "09"},
        {label: "Oct", value: "10"},
        {label: "Nov", value: "11"},
        {label: "Dec", value: "12"},
      ]
      let yearItems = []
      Belt.Range.forEach(0, 125, y => {
        let yearStr = (2025 - y)->Int.toString
        yearItems->Array.push({SdkTypes.label: yearStr, value: yearStr})
      })
      (dayItems, monthItems, yearItems)
    }, (month, year))

    <>
      <Text
        style={array([
          s({
            fontFamily,
            fontWeight: #normal,
            fontSize: (13. +. placeholderTextSizeAdjust) *. fontScale,
            color: placeholderColor,
          }),
        ])}
      >
        {React.string(placeholder)}
      </Text>
      <Space height=8. />
      <View style={s({flexDirection: #row, gap: 8.->dp})}>
        <View style={s({flex: 1.})}>
          <CustomPicker
            value={Some(day)}
            setValue={v => setDay(_ => v()->Option.getOr(""))}
            items=dayItems
            placeholderText="Day"
            isValid={meta.error->Option.isNone || !meta.touched || meta.active}
            isLoading=false
            onFocus={_ => input.onFocus()}
            onBlur={_ => input.onBlur()}
            ?accessible
          />
        </View>
        <View style={s({flex: 1.})}>
          <CustomPicker
            value={Some(month)}
            setValue={v => setMonth(_ => v()->Option.getOr(""))}
            items=monthItems
            placeholderText="Month"
            isValid={meta.error->Option.isNone || !meta.touched || meta.active}
            isLoading=false
            onFocus={_ => input.onFocus()}
            onBlur={_ => input.onBlur()}
            ?accessible
          />
        </View>
        <View style={s({flex: 1.})}>
          <CustomPicker
            value={Some(year)}
            setValue={v => setYear(_ => v()->Option.getOr(""))}
            items=yearItems
            placeholderText="Year"
            isValid={meta.error->Option.isNone || !meta.touched || meta.active}
            isLoading=false
            onFocus={_ => input.onFocus()}
            onBlur={_ => input.onBlur()}
            ?accessible
          />
        </View>
      </View>
      {switch (meta.error, meta.touched, meta.active) {
      | (Some(error), true, false) => <ErrorText text={Some(error)} />
      | _ => React.null
      }}
    </>
  }
}

@react.component
let make = (
  ~fields: array<SuperpositionTypes.fieldConfig>,
  ~createFieldValidator,
  ~formatValue as _,
  ~accessible=?,
) => {
  fields
  ->Array.map(field => {
    let placeholder = GetLocale.getLocalString(field.displayName)

    <React.Fragment key={field.outputPath}>
      <View style={s({marginBottom: 16.->dp})}>
        <ReactFinalForm.Field
          name=field.outputPath validate=Some(createFieldValidator(Validation.Required))
        >
          {fieldProps => <DatePicker fieldProps placeholder accessible />}
        </ReactFinalForm.Field>
      </View>
    </React.Fragment>
  })
  ->React.array
}
