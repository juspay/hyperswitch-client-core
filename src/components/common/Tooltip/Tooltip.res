open ReactNative
open Style

@react.component
let make = (
  ~children: React.element,
  ~renderContent: (_ => unit) => React.element,
  ~maxHeight=200.,
  ~maxWidth=200.,
  ~adjustment=2.,
  ~containerStyle=?,
  ~backgroundColor=?,
  ~disabled=false,
  ~keyboardShouldPersistTaps=false,
) => {
  let {
    component,
    borderWidth,
    borderRadius,
    boxBorderColor,
    shadowColor,
    shadowIntensity,
    sheetContentPadding,
  } = ThemebasedStyle.useThemeBasedStyle()
  let shadowStyle = ShadowHook.useGetShadowStyle(~shadowIntensity, ~shadowColor, ())
  let (viewPortContants, _) = React.useContext(ViewportContext.viewPortContext)

  let maxHeight = min(viewPortContants.screenHeight -. sheetContentPadding *. 2., maxHeight)
  let maxWidth = min(
    viewPortContants.screenWidth -. sheetContentPadding *. 2. -. adjustment *. 2.,
    maxWidth,
  )
  let renderedElement = React.useRef(Nullable.null)
  let (tooltipPosition, setTooltipPosition) = React.useState(_ => None)
  let (isVisible, setIsVisible) = React.useState(_ => false)
  let toggleVisibility = () => {
    setIsVisible(val => !val)
  }

  let calculateTooltipPosition = _ => {
    setTooltipPosition(_ => None)
    toggleVisibility()
    switch renderedElement.current->Js.Nullable.toOption {
    | Some(element) =>
      element->View.measure((~x as _, ~y as _, ~width as _, ~height, ~pageX, ~pageY) => {
        let x: TooltipTypes.positionX = if viewPortContants.screenWidth -. pageX < maxWidth {
          Right(sheetContentPadding -. adjustment)
        } else {
          Left(pageX)
        }

        let y: TooltipTypes.positionY = if viewPortContants.screenHeight -. pageY < maxHeight {
          Bottom(viewPortContants.screenHeight -. pageY)
        } else {
          Top(pageY +. height)
        }

        setTooltipPosition(_ => Some(({x, y}: TooltipTypes.tooltipPosition)))
      })
    | None => ()
    }
  }

  let onPress = _ => {
    !keyboardShouldPersistTaps && Keyboard.isVisible()
      ? Keyboard.dismiss()
      : calculateTooltipPosition()
  }

  let getPositionStyle = (position: option<TooltipTypes.tooltipPosition>) => {
    switch position {
    | None => empty
    | Some(pos) => {
        let xStyle = switch pos.x {
        | Left(x) => s({left: x->dp})
        | Right(x) => s({right: x->dp})
        }

        let yStyle = switch pos.y {
        | Top(y) => s({top: y->dp})
        | Bottom(y) => s({bottom: y->dp})
        }

        StyleSheet.flatten([xStyle, yStyle])
      }
    }
  }

  let tooltipBaseStyle = {
    let baseStyle = s({
      position: #absolute,
      paddingHorizontal: 20.->dp,
      paddingVertical: 10.->dp,
      maxWidth: maxWidth->dp,
      maxHeight: maxHeight->dp,
      backgroundColor: backgroundColor->Option.getOr(component.background),
      borderRadius,
      borderWidth,
    })
    StyleSheet.flatten([baseStyle, boxBorderColor, shadowStyle, getPositionStyle(tooltipPosition)])
  }

  let tooltipStyle = switch containerStyle {
  | Some(customStyle) => [tooltipBaseStyle, customStyle]->StyleSheet.flatten
  | None => [tooltipBaseStyle]->StyleSheet.flatten
  }

  <View ref={Ref.value(renderedElement)} onLayout={_ => ()}>
    <CustomPressable onPress disabled> children </CustomPressable>
    <UIUtils.RenderIf condition={isVisible && tooltipPosition->Option.isSome}>
      <Portal>
        <CustomPressable onPress={_ => toggleVisibility()} style={s({flex: 1.})}>
          <View style={tooltipStyle}> {renderContent(toggleVisibility)} </View>
        </CustomPressable>
      </Portal>
    </UIUtils.RenderIf>
  </View>
}
