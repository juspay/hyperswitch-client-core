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
  let (tooltipPositon, setTooltipPosition) = React.useState(_ => Loading)
  let renderedElement = React.useRef(Js.Nullable.null)

  let {component} = ThemebasedStyle.useThemeBasedStyle()
  let {shadowColor, shadowIntensity} = ThemebasedStyle.useThemeBasedStyle()
  let shadowStyle = ShadowHook.useGetShadowStyle(~shadowIntensity, ~shadowColor, ())
  let (viewPortConstants, _) = React.useContext(ViewportContext.viewPortContext)

  React.useEffect(_ => {
    switch renderedElement.current->Js.Nullable.toOption {
    | Some(element) =>
      element->ReactNative.View.measureInWindow((~x, ~y, ~width, ~height) => {
        setElementInfo(_ => {xOffset: x, yOffset: y, elementWidth: width, elementHeight: height})
      })
    | None => ()
    }

    if !isVisible {
      setTooltipPosition(_ => Loading)
    }
    None
  }, [isVisible])

  React.useEffect(_ => {
    if isVisible {
      let {x, y} = GetTooltipcoordinate.getTooltipCoordinate(
        ~x=elementInfo.xOffset,
        ~y=elementInfo.yOffset,
        ~width=elementInfo.elementWidth,
        ~height=elementInfo.elementHeight,
        ~screenWidth=viewPortConstants.windowWidth,
        ~screenHeight=viewPortConstants.windowHeight,
        ~tooltipWidth=Number(width),
        ~tooltipHeight=Number(height),
      )
      setTooltipPosition(_ => Coordinate({x, y}))
    } else {
      setTooltipPosition(_ => Loading)
    }
    None
  }, [elementInfo])

  let toggleTooltip = _ => {
    setIsVisible(visible => !visible)
  }

  let isLoading = state =>
    switch state {
    | Loading => true
    | Coordinate(_) => false
    }

  let getCoord = state =>
    switch state {
    | Coordinate({x, y}) => [x, y]
    | Loading => [0., 0.]
    }

  let tooltipBaseStyle = array([
    viewStyle(
      ~position=#absolute,
      ~top=tooltipPositon->getCoord->Array.get(1)->Option.getOr(0.)->dp,
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
      viewStyle(~left=tooltipPositon->getCoord->Array.get(0)->Option.getOr(0.)->dp, ())
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
    <UIUtils.RenderIf condition={isVisible && !(tooltipPositon->isLoading)}>
      {renderContent(~withTooltip=true)}
    </UIUtils.RenderIf>
  </ReactNative.View>
}
