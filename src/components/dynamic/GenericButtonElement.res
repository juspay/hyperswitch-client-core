open ReactNative
open Style

@react.component
let make = (~buttonName, ~color, ~width, ~height=?) => {
  let (themeType, _) = React.useContext(ThemeContext.themeContext)
  let isDarkMode = switch themeType {
  | Light(_) => false
  | Dark(_) => true
  }

  <View
    style={s({
      flexDirection: #row,
      alignItems: #center,
      justifyContent: #center,
      width: 100.->pct,
      backgroundColor: isDarkMode ? "#fff" : color,
    })}>
    {height->Option.isNone
      ? <Icon name=buttonName width=24. height=24. fill={isDarkMode ? color : "#fff"} />
      : React.null}
    <Space width=5. />
    <Icon
      name={`${buttonName}2`}
      width
      height={height->Option.getOr(24.)}
      fill={isDarkMode ? color : "#fff"}
    />
  </View>
}
