open ReactNative
open Style

@react.component
let make = (
  ~children: React.element,
  ~popover: React.element,
  ~maxHeight=200.,
  ~maxWidth=200.,
  ~adjustmentX=2.,
  ~adjustmentY=10.,
  ~containerStyle=?,
  ~backgroundColor=?,
  ~isVisible,
  ~setIsVisible,
) => {
  let {
    component,
    borderWidth,
    borderRadius,
    boxBorderColor,
    shadowColor,
    shadowIntensity,
  } = ThemebasedStyle.useThemeBasedStyle()
  let shadowStyle = ShadowHook.useGetShadowStyle(~shadowIntensity, ~shadowColor, ())
  let (viewPortContants, _) = React.useContext(ViewportContext.viewPortContext)

  let defaultPadding = 20.
  let maxHeight =
    viewPortContants.screenHeight > maxHeight
      ? maxHeight
      : viewPortContants.screenHeight -. defaultPadding *. 2. -. adjustmentY *. 2.
  let maxWidth =
    viewPortContants.screenWidth > maxWidth
      ? maxWidth
      : viewPortContants.screenWidth -. defaultPadding *. 2. -. adjustmentX *. 2.
  let renderedElement = React.useRef(Nullable.null)
  let (tooltipPosition, setTooltipPosition) = React.useState(_ => None)

  React.useEffect(_ => {
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
          let x: TooltipTypes.positionX = if viewPortContants.screenWidth -. pageX < maxWidth {
            Right(defaultPadding -. adjustmentX)
          } else {
            Left(pageX)
          }

          let y: TooltipTypes.positionY = if viewPortContants.screenHeight -. pageY < maxHeight {
            Bottom(viewPortContants.screenHeight -. pageY +. adjustmentY)
          } else {
            Top(pageY +. height +. adjustmentY)
          }

          setTooltipPosition(_ => Some(({x, y}: TooltipTypes.tooltipPosition)))
        })
      | None => ()
      }
    } else {
      setTooltipPosition(_ => None)
    }
    None
  }, (isVisible, viewPortContants.screenWidth, viewPortContants.screenHeight))

  let toggleTooltip = () => {
    setIsVisible(visible => !visible)
  }

  let getPositionStyle = (position: option<TooltipTypes.tooltipPosition>) => {
    switch position {
    | None => viewStyle()
    | Some(pos) => {
        let xStyle = switch pos.x {
        | Left(x) => viewStyle(~left=x->dp, ())
        | Right(x) => viewStyle(~right=x->dp, ())
        }

        let yStyle = switch pos.y {
        | Top(y) => viewStyle(~top=y->dp, ())
        | Bottom(y) => viewStyle(~bottom=y->dp, ())
        }

        StyleSheet.flatten([xStyle, yStyle])
      }
    }
  }

  let tooltipBaseStyle = {
    let baseStyle = viewStyle(
      ~position=#absolute,
      ~paddingHorizontal=20.->dp,
      ~paddingVertical=10.->dp,
      ~maxWidth=maxWidth->dp,
      ~maxHeight=maxHeight->dp,
      ~backgroundColor=backgroundColor->Option.getOr(component.background),
      ~borderRadius,
      ~borderWidth,
      (),
    )
    StyleSheet.flatten([baseStyle, boxBorderColor, shadowStyle, getPositionStyle(tooltipPosition)])
  }

  let tooltipStyle = switch containerStyle {
  | Some(customStyle) => [tooltipBaseStyle, customStyle]->ReactNative.StyleSheet.flatten
  | None => [tooltipBaseStyle]->ReactNative.StyleSheet.flatten
  }

  <ReactNative.View ref={ReactNative.Ref.value(renderedElement)} onLayout={_ => ()}>
    children
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
