open ReactNative

@module("use-latest-callback") external useLatestCallback: 't => 't = "default"
type isRTL = {isRTL: bool}
type i18nManager = {getConstants: unit => isRTL}
@val @scope("ReactNative") external i18nManager: i18nManager = "I18nManager"

type tabSize = [#auto | #dp(float) | #pct(float) | #none]

let parseSize = (size, key) => {
  let attr = size->Dict.get(key)->Option.getOr(JSON.Null)

  switch attr->JSON.Classify.classify {
  | Number(num) => Float.isFinite(num) ? #dp(num) : #none
  | String(str) =>
    if str === "auto" {
      #auto
    } else if str->String.endsWith("%") {
      let width = Float.parseFloat(str)
      Float.isFinite(width) ? #pct(width) : #dp(0.)
    } else {
      #none
    }
  | _ => #none
  }
}

let getSizeFromTabSize = tabSize => {
  switch tabSize {
  | #dp(num) => num->Style.dp->Some
  | #pct(num) => num->Style.pct->Some
  | #auto => Style.auto->Some
  | #none => None
  }
}

type localeDirection = [#ltr | #rtl]

let localeDirectionToString = direction =>
  switch direction {
  | #ltr => "ltr"
  | #rtl => "rtl"
  }

type keyboardDismissMode = [#none | #"on-drag" | #auto]

type route = {
  key: string,
  icon?: string,
  title?: string,
  accessible?: bool,
  accessibilityLabel?: string,
  testID?: string,
}

type labelProps = {
  route: route,
  labelText?: string,
  focused: bool,
  color: Color.t,
  allowFontScaling?: bool,
  style?: Style.t,
}

type iconProps = {
  route: route,
  focused: bool,
  color: Color.t,
  size: int,
}

type badgeProps = {route: route}

type tabDescriptor = {
  accessibilityLabel?: string,
  accessible?: bool,
  testID?: string,
  labelText?: string,
  labelAllowFontScaling?: bool,
  href?: string,
  label?: React.component<labelProps>,
  labelStyle?: Style.t,
  icon?: React.component<iconProps>,
  badge?: React.component<badgeProps>,
  sceneStyle?: Style.t,
}

type event = {
  mutable defaultPrevented: bool,
  preventDefault: unit => unit,
}

type scene = {route: route}

type navigationState = {
  index: int,
  routes: array<route>,
}

type layout = {
  width: float,
  height: float,
}

type listenerEvent = {
  \"type": [#enter],
  index: int,
}

type listener = listenerEvent => unit

type eventEmitterProps = {subscribe: listener => unit => unit}

type tabSelect = {index: int}
