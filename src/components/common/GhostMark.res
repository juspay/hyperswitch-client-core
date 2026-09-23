open ReactNative
open Style

// Stands in for a control whose optional package is not in this build (vault,
// scancard, ...). Shoppers see the muted shape of the control, never a
// "package not installed" message: that is for the integrating developer and
// goes to the logs, or to the merchant's onError callback.
@react.component
let make = (~height: float, ~width=?, ~radius=?, ~style=?, ~testID=?) => {
  let {loadingBgColor, borderRadius, component} = ThemebasedStyle.useThemeBasedStyle()
  <View
    ?testID
    pointerEvents=#none
    accessibilityElementsHidden=true
    importantForAccessibility=#"no-hide-descendants"
    style={array([
      s({
        height: height->dp,
        width: width->Option.getOr(100.->pct),
        borderRadius: radius->Option.getOr(borderRadius),
        backgroundColor: loadingBgColor === "" ? component.borderColor : loadingBgColor,
        opacity: 0.6,
      }),
      style->Option.getOr(s({})),
    ])}
  />
}
