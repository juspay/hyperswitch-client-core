open ReactNative
open Style
open TooltipTypes

@react.component
let make = (
  ~children: React.element,
  ~popover: React.element,
  ~height=40.0,
  ~width=150.0,
  ~leftAlign: option<float>=?,
  ~rightAlign: option<float>=?,
  ~containerStyle=?,
  ~backgroundColor=?,
  ~isVisible,
  ~setIsVisible,
) => {
  let defaultInfo = {
    xOffset: 0.0,
    yOffset: 0.0,
    elementWidth: 0.0,
    elementHeight: 0.0,
  }
  let (elementInfo, setElementInfo) = React.useState(_ => defaultInfo)
  let renderedElement = React.useRef(Js.Nullable.null)

  let {component} = ThemebasedStyle.useThemeBasedStyle()
  let {shadowColor, shadowIntensity} = ThemebasedStyle.useThemeBasedStyle()
  let shadowStyle = ShadowHook.useGetShadowStyle(~shadowIntensity, ~shadowColor, ())
  let (viewPortContants, _) = React.useContext(ViewportContext.viewPortContext)

  React.useEffect(() => {
    let timeout = Js.Global.setTimeout(() => {
      switch renderedElement.current->Js.Nullable.toOption {
      | Some(element) =>
        element->ReactNative.View.measureInWindow(
          (~x, ~y, ~width, ~height) => {
            setElementInfo(
              _ => {xOffset: x, yOffset: y, elementWidth: width, elementHeight: height},
            )
          },
        )
      | None => ()
      }
    }, 500)
    Some(() => Js.Global.clearTimeout(timeout))
  }, [isVisible])

  let toggleTooltip = () => {
    setIsVisible(visible => !visible)
  }

  let {x, y} = React.useMemo(() => {
    GetTooltipcoordinate.getTooltipCoordinate(
      ~x=elementInfo.xOffset,
      ~y=elementInfo.yOffset,
      ~width=elementInfo.elementWidth,
      ~height=elementInfo.elementHeight,
      ~screenWidth=viewPortContants.windowWidth,
      ~screenHeight=viewPortContants.windowHeight,
      ~tooltipWidth=Number(width),
    )
  }, (elementInfo, viewPortContants.windowWidth, viewPortContants.windowHeight, width))

  let tooltipBaseStyle = array([
    viewStyle(
      ~position=#absolute,
      ~top=y->dp,
      ~paddingHorizontal=20.->dp,
      ~paddingVertical=10.->dp,
      ~width=width->dp,
      ~maxHeight=180.->dp,
      ~backgroundColor={backgroundColor->Option.getOr(component.background)},
      ~borderRadius=8.,
      (),
    ),
    shadowStyle,
    if leftAlign->Option.isSome || rightAlign->Option.isSome {
      let alignmentStyle = array([
        switch leftAlign {
        | Some(left) => viewStyle(~left=left->dp, ())
        | None => viewStyle()
        },
        switch rightAlign {
        | Some(right) => viewStyle(~right=right->dp, ())
        | None => viewStyle()
        },
      ])
      alignmentStyle
    } else {
      viewStyle(~left=x->dp, ())
    },
  ])

  let tooltipStyle = switch containerStyle {
  | Some(customStyle) => [tooltipBaseStyle, customStyle]->ReactNative.StyleSheet.flatten
  | None => [tooltipBaseStyle]->ReactNative.StyleSheet.flatten
  }

  let renderContent = (~withTooltip) => {
    if !withTooltip {
      children
    } else {
      <Portal>
        <CustomTouchableOpacity
          activeOpacity=1. onPress={_ => toggleTooltip()} style={viewStyle(~flex=1., ())}>
          <ReactNative.View style={tooltipStyle}> popover </ReactNative.View>
        </CustomTouchableOpacity>
      </Portal>
    }
  }
  <ReactNative.View ref={ReactNative.Ref.value(renderedElement)} onLayout={_ => ()}>
    {renderContent(~withTooltip=false)}
    <UIUtils.RenderIf condition={isVisible}> {renderContent(~withTooltip=true)} </UIUtils.RenderIf>
  </ReactNative.View>
}
