open ReactNative
open Style

@react.component
let make = (
  ~hocComponentArr: array<AllApiDataModifier.hoc>,
  ~indexInFocus: int,
  ~setIndexInFocus: int => unit,
  ~isLoading: bool,
) => {
  let {
    component,
    primaryColor,
    iconColor,
    borderRadius,
    borderWidth,
    bgColor,
    shadowColor,
    shadowIntensity,
    sheetContentPadding,
  } = ThemebasedStyle.useThemeBasedStyle()
  let getShadowStyle = ShadowHook.useGetShadowStyle(~shadowIntensity, ~shadowColor, ())

  let numColumns = {
    let len = hocComponentArr->Array.length
    if len < 2 {
      2
    } else if len > 4 {
      4
    } else {
      len
    }
  }
  let itemWidthPct = 100. /. numColumns->Int.toFloat

  <View
    style={s({
      flexDirection: #row,
      flexWrap: #wrap,
      padding: (sheetContentPadding -. 6.)->dp,
    })}>
    {hocComponentArr
    ->Array.mapWithIndex((hoc, index) => {
      let isFocused = indexInFocus === index

      <CustomPressable
        key={index->Int.toString}
        onPress={_ => setIndexInFocus(index)}
        style={array([
          bgColor,
          getShadowStyle,
          s({
            width: itemWidthPct->pct,
            padding: 6.->dp,
          }),
        ])}>
        <View
          style={array([
            s({
              backgroundColor: component.background,
              borderWidth: isFocused ? borderWidth +. 1.5 : borderWidth,
              borderColor: isFocused ? primaryColor : component.borderColor,
              borderRadius,
              padding: (isFocused ? 10. : 11.5)->dp,
              alignItems: #center,
              justifyContent: #center,
              minHeight: 60.->dp,
            }),
          ])}>
          {isLoading
            ? <CustomLoader height="18" width="18" />
            : <Icon
                name=hoc.name
                width=18.
                height=18.
                fill={isFocused ? primaryColor : iconColor}
              />}
          <Space height=2. />
          {isLoading
            ? <CustomLoader height="18" width="40" />
            : <TextWrapper
                text=hoc.name
                textType={isFocused ? CardTextBold : CardText}
              />}
        </View>
      </CustomPressable>
    })
    ->React.array}
  </View>
}
