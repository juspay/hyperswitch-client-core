open ReactNative
open Style

@react.component
let make = (
  ~children,
  ~onClickOutside=_ => (),
  ~backgroundColor=?,
  ~target: option<React.ref<'t>>=?,
) => {
  let {component} = ThemebasedStyle.useThemeBasedStyle()
  let {shadowColor, shadowIntensity} = ThemebasedStyle.useThemeBasedStyle()
  let shadowStyle = ShadowHook.useGetShadowStyle(~shadowIntensity, ~shadowColor, ())

  let (top, setTop) = React.useState(_ => None)

  let calculateInitLayout = () => {
    switch target {
    | Some(ref) =>
      switch ref.current->Nullable.toOption {
      | Some(ref) =>
        ref->ReactNative.View.measureInWindow((~x as _, ~y, ~width as _, ~height) => {
          setTop(_ => Some(y +. height +. (ReactNative.Platform.os === #android ? 12. : 0.)))
        })
      | None => ()
      }
    | None => ()
    }
  }

  React.useEffect(() => {
    calculateInitLayout()
    None
  }, [target])

  <UIUtils.RenderIf condition={top->Option.isSome}>
    <Portal>
      <CustomTouchableOpacity
        activeOpacity=1. onPress={event => onClickOutside(event)} style={viewStyle(~flex=1., ())}>
        <SafeAreaView />
        <View
          style={array([
            viewStyle(
              ~position=#absolute,
              ~top=top->Option.getOr(0.)->dp,
              ~right=10.->dp,
              ~margin=10.->dp,
              ~paddingHorizontal=20.->dp,
              ~paddingVertical=10.->dp,
              ~maxHeight=180.->dp,
              ~backgroundColor={backgroundColor->Option.getOr(component.background)},
              ~borderRadius=8.,
              (),
            ),
            shadowStyle,
          ])}>
          {children}
        </View>
      </CustomTouchableOpacity>
    </Portal>
  </UIUtils.RenderIf>
}
