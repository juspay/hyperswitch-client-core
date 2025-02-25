open ReactNative
open Style

type positionX = Left(float) | Right(float)
type positionY = Top(float) | Bottom(float)

type tooltipPosition = {
  x: positionX,
  y: positionY,
}

@react.component
let make = (
  ~children: React.element,
  ~popover: React.element,
  ~maxHeight=200.,
  ~maxWidth=200.,
  ~containerStyle=?,
  ~backgroundColor=?,
  ~isVisible,
  ~setIsVisible,
) => {
  let (tooltipPosition, setTooltipPosition) = React.useState(_ => None)

  let renderedElement = React.useRef(Js.Nullable.null)

  let {component} = ThemebasedStyle.useThemeBasedStyle()
  let {shadowColor, shadowIntensity} = ThemebasedStyle.useThemeBasedStyle()
  let shadowStyle = ShadowHook.useGetShadowStyle(~shadowIntensity, ~shadowColor, ())
  let (viewPortContants, _) = React.useContext(ViewportContext.viewPortContext)

  let maxHeight =
    viewPortContants.windowHeight > maxHeight ? maxHeight : viewPortContants.windowHeight
  let maxWidth = viewPortContants.windowWidth > maxWidth ? maxWidth : viewPortContants.windowWidth
  let defaultPadding = 20.
  let adjustments = 2.

  React.useEffect(() => {
    if isVisible {
      switch renderedElement.current->Js.Nullable.toOption {
      | Some(element) =>
        element->ReactNative.View.measure((
          ~x as _,
          ~y as _,
          ~width as _,
          ~height,
          ~pageX,
          ~pageY,
        ) => {
          let x = if viewPortContants.windowWidth -. pageX < maxWidth {
            Right(defaultPadding -. adjustments)
          } else {
            Left(pageX)
          }

          let y = if viewPortContants.windowHeight -. pageY < maxHeight {
            Bottom(viewPortContants.windowHeight -. pageY +. adjustments)
          } else {
            Top(pageY +. height +. adjustments)
          }

          setTooltipPosition(_ => Some({x, y}))
        })
      | None => ()
      }
    } else {
      setTooltipPosition(_ => None)
    }
    None
  }, [isVisible])

  let toggleTooltip = () => {
    setIsVisible(visible => !visible)
  }

  let tooltipBaseStyle = array([
    viewStyle(
      ~position=#absolute,
      ~paddingHorizontal=20.->dp,
      ~paddingVertical=10.->dp,
      ~maxWidth=maxWidth->dp,
      ~maxHeight=maxHeight->dp,
      ~backgroundColor={backgroundColor->Option.getOr(component.background)},
      ~borderRadius=8.,
      ~borderWidth=1.,
      ~borderColor="#00000005",
      (),
    ),
    shadowStyle,
    switch tooltipPosition {
    | Some(x) =>
      switch x.x {
      | Left(x) => viewStyle(~left=x->dp, ())
      | Right(x) => viewStyle(~right=x->dp, ())
      }
    | None => viewStyle()
    },
    switch tooltipPosition {
    | Some(y) =>
      switch y.y {
      | Top(y) => viewStyle(~top=y->dp, ())
      | Bottom(y) => viewStyle(~bottom=y->dp, ())
      }
    | None => viewStyle()
    },
  ])

  let tooltipStyle = switch containerStyle {
  | Some(customStyle) => [tooltipBaseStyle, customStyle]->ReactNative.StyleSheet.flatten
  | None => [tooltipBaseStyle]->ReactNative.StyleSheet.flatten
  }

  <ReactNative.View ref={ReactNative.Ref.value(renderedElement)} onLayout={_ => ()}>
    {children}
    <UIUtils.RenderIf condition={isVisible && tooltipPosition->Option.isSome}>
      <Portal>
        <CustomTouchableOpacity
          activeOpacity=1. onPress={_ => toggleTooltip()} style={viewStyle(~flex=1., ())}>
          <ReactNative.View style={tooltipStyle}> popover </ReactNative.View>
        </CustomTouchableOpacity>
      </Portal>
    </UIUtils.RenderIf>
  </ReactNative.View>
}
