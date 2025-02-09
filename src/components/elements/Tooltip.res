open ReactNative
open Style

module ToolTipListItem = {
  @react.component
  let make = (~onPress, ~iconName, ~text, ~index) => {
    <CustomTouchableOpacity key={index->Int.toString} onPress>
      <View
        style={viewStyle(~flexDirection=#row, ~alignItems=#center, ~paddingVertical=5.->dp, ())}>
        <Icon name={iconName} height=30. width=30. fill="black" />
        <Space />
        <TextWrapper textType={CardText} text />
      </View>
    </CustomTouchableOpacity>
  }
}

@react.component
let make = () => {
  let (y, setY) = React.useState(_ => 0.)
  let (x, setX) = React.useState(_ => 0.)
  let (tooltipWidth, setTooltipWidth) = React.useState(_ => 0.)
  let (tooltipHeight, setTooltipHeight) = React.useState(_ => 0.)
  let (posStyle, setPosStyle) = React.useState(_ => ReactNative.Style.viewStyle())

  let {shadowColor, shadowIntensity} = ThemebasedStyle.useThemeBasedStyle()
  let shadowStyle = ShadowHook.useGetShadowStyle(~shadowIntensity, ~shadowColor, ())
  let (viewPortContants, _) = React.useContext(ViewportContext.viewPortContext)

  let (tooltipConfig, setTooltipConfig) = React.useContext(TooltipContext.tooltipContext)
  let posRef = tooltipConfig.ref->Option.getOr(React.useRef(Nullable.null))
  let isTooltipActive = tooltipConfig.isVisble
  let toolTipHeader = tooltipConfig.header
  let data = tooltipConfig.data
  let backgroundColor = tooltipConfig.backgroundColor

  let tooltipRef = React.useRef(Nullable.null)

  let onLayoutTooltip = () => {
    switch tooltipRef.current->Nullable.toOption {
    | Some(ref) =>
      ref->View.measureInWindow((~x as _, ~y as _, ~width, ~height) => {
        setTooltipWidth(_ => width)
        setTooltipHeight(_ => height)
      })
    | None => ()
    }
  }

  let getElementPosition = _ => {
    switch posRef.current->Nullable.toOption {
    | Some(ref) => {
        ref->View.measureInWindow((~x, ~y, ~width, ~height) => {
          setY(_ => y +. height)
          setX(_ => x +. width)

          setY(_ => {
            ReactNative.Platform.os == #ios ? y +. height -. 48. : y +. height -. 48. +. 18.
          })
          setX(_ => x)
        })

        let screenWidth = viewPortContants.screenWidth
        let screenHeight = viewPortContants.screenHeight

        let left =
          x +. tooltipWidth < screenWidth -. 10.
            ? ReactNative.Style.viewStyle(~left=x->dp, ())
            : ReactNative.Style.viewStyle()

        let right =
          x +. tooltipWidth > screenWidth -. 10.
            ? ReactNative.Style.viewStyle(~right=10.->dp, ())
            : ReactNative.Style.viewStyle()

        let top =
          y +. tooltipHeight < screenHeight -. 10.
            ? ReactNative.Style.viewStyle(~top=y->dp, ())
            : ReactNative.Style.viewStyle()

        let bottom =
          y +. tooltipHeight > screenHeight -. 10.
            ? ReactNative.Style.viewStyle(
                ~bottom=(viewPortContants.navigationBarHeight +. 10.)->dp,
                (),
              )
            : ReactNative.Style.viewStyle()

        Style.array([left, right, top, bottom, ReactNative.Style.viewStyle(~display=#flex, ())])
      }
    | None =>
      ReactNative.Style.viewStyle(~left=0.->dp, ~right=0.->dp, ~top=0.->dp, ~bottom=0.->dp, ~display=#none, ())
    }
  }

  React.useEffect(() => {
    setPosStyle(_ => getElementPosition())
    None
  }, (isTooltipActive, posRef, tooltipWidth, tooltipHeight))

  <UIUtils.RenderIf condition={isTooltipActive}>
    <CustomTouchableOpacity
      onPress={_ => {
        setTooltipConfig({
          ...tooltipConfig,
          isVisble: false,
        })
      }}
      style={array([
        viewStyle(
          ~width=100.->pct,
          ~height=100.->pct,
          ~position=#absolute,
          ~backgroundColor="transparent",
          (),
        ),
      ])}>
      <SafeAreaView />
      <View
        ref={ReactNative.Ref.value(tooltipRef)}
        onLayout={_ => onLayoutTooltip()}
        style={array([
          viewStyle(
            ~position=#absolute,
            ~flex=1.,
            ~margin=10.->dp,
            ~paddingHorizontal=20.->dp,
            ~paddingVertical=10.->dp,
            ~backgroundColor,
            ~borderRadius=8.,
            (),
          ),
          posStyle,
          shadowStyle,
        ])}>
        {toolTipHeader->Option.isSome
          ? <TextWrapper textType={ModalTextLight} text={toolTipHeader->Option.getOr("")} />
          : React.null}
        <ScrollView>
          <Space />
          {switch data {
          | List(items) =>
            items
            ->Array.mapWithIndex((item, index) => {
              let onPressHandler = item.onPress->Option.getOr(() => ())

              <ToolTipListItem
                key={index->Int.toString}
                index={index}
                text={item.text}
                iconName={item.iconName}
                onPress={_ => onPressHandler()}
              />
            })
            ->React.array
          | Data(text) => <TextWrapper textType={ModalTextLight} text />
          | None => React.null
          }}
        </ScrollView>
      </View>
      <SafeAreaView />
    </CustomTouchableOpacity>
  </UIUtils.RenderIf>
}
