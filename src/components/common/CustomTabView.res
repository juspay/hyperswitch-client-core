open ReactNative
open Style

module GridTabBar = {
  @react.component
  let make = (
    ~hocComponentArr: array<AllApiDataModifier.hoc>,
    ~indexInFocus: int,
    ~setIndexInFocus: int => unit,
    ~isLoading: bool,
  ) => {
    let {
      component,
      primaryColor,
      iconColor,
      borderRadius,
      borderWidth,
      bgColor,
      shadowColor,
      shadowIntensity,
      sheetContentPadding,
    } = ThemebasedStyle.useThemeBasedStyle()
    let getShadowStyle = ShadowHook.useGetShadowStyle(~shadowIntensity, ~shadowColor, ())

    let numColumns = {
      let len = hocComponentArr->Array.length
      if len < 2 {
        2
      } else if len > 4 {
        4
      } else {
        len
      }
    }
    let itemWidthPct = 100. /. numColumns->Int.toFloat

    <View
      style={s({
        flexDirection: #row,
        flexWrap: #wrap,
        padding: (sheetContentPadding -. 6.)->dp,
      })}>
      {hocComponentArr
      ->Array.mapWithIndex((hoc, index) => {
        let isFocused = indexInFocus === index

        <CustomPressable
          key={index->Int.toString}
          onPress={_ => setIndexInFocus(index)}
          style={array([
            bgColor,
            getShadowStyle,
            s({
              width: itemWidthPct->pct,
              padding: 6.->dp,
            }),
          ])}>
          <View
            style={array([
              s({
                backgroundColor: component.background,
                borderWidth: isFocused ? borderWidth +. 1.5 : borderWidth,
                borderColor: isFocused ? primaryColor : component.borderColor,
                borderRadius,
                padding: (isFocused ? 10. : 11.5)->dp,
                alignItems: #center,
                justifyContent: #center,
                minHeight: 60.->dp,
              }),
            ])}>
            {isLoading
              ? <CustomLoader height="18" width="18" />
              : <Icon
                  name=hoc.name
                  width=18.
                  height=18.
                  fill={isFocused ? primaryColor : iconColor}
                />}
            <Space height=2. />
            {isLoading
              ? <CustomLoader height="18" width="40" />
              : <TextWrapper
                  text=hoc.name
                  textType={isFocused ? CardTextBold : CardText}
                />}
          </View>
        </CustomPressable>
      })
      ->React.array}
    </View>
  }
}

@react.component
let make = (
  ~hocComponentArr: array<AllApiDataModifier.hoc>=[],
  ~isLoading,
  ~setConfirmButtonData,
) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let layout = nativeProp.configuration.appearance.layout

  let (indexInFocus, setIndexInFocus) = React.useState(_ => 0)
  let setIndexInFocus = React.useCallback1(index => {
    setIndexInFocus(_ => index)
  }, [setIndexInFocus])

  let {sheetContentPadding, primaryColor, iconColor} = ThemebasedStyle.useThemeBasedStyle()

  let isGridArrangement = layout.paymentMethodsArrangementForTabs === ArrangementGrid

  let (renderScene, descriptorDict) = React.useMemo3(() => {
    let map = Map.make()
    let descriptorDict: Dict.t<TabViewType.tabDescriptor> = Dict.make()

    hocComponentArr->Array.forEachWithIndex((hoc, index) => {
      map->Map.set(
        index->Int.toString,
        _ => {
          hoc.componentHoc(~isScreenFocus=indexInFocus === index, ~setConfirmButtonData)
        },
      )

      descriptorDict->Dict.set(
        index->Int.toString,
        {
          icon: _ =>
            isLoading
              ? <CustomLoader height="18" width="18" />
              : <Icon
                  name=hoc.name
                  width=18.
                  height=18.
                  fill={indexInFocus === index ? primaryColor : iconColor}
                />,
          label: _ =>
            isLoading
              ? <CustomLoader height="18" width="40" />
              : <TextWrapper
                  text=hoc.name
                  textType={switch indexInFocus === index {
                  | true => CardTextBold
                  | _ => CardText
                  }}
                />,
        },
      )
    })

    (SceneMap.sceneMap(map), descriptorDict)
  }, (hocComponentArr, indexInFocus, isLoading))

  <UIUtils.RenderIf condition={hocComponentArr->Array.length > 0}>
    {
      let routes = hocComponentArr->Array.mapWithIndex((hoc, index) => {
        let route: TabViewType.route = {
          key: index->Int.toString,
          title: hoc.name,
        }
        route
      })

      let isScrollBarOnlyCards =
        hocComponentArr->Array.length == 1 &&
          switch hocComponentArr->Array.get(0) {
          | Some({name}) => name == "Card"
          | None => true
          }

      <TabView
        navigationState={
          index: indexInFocus,
          routes,
        }
        onIndexChange=setIndexInFocus
        renderTabBar={(~position, ~jumpTo, ~navigationState, ~options) =>
          isScrollBarOnlyCards
            ? <Space height=24. />
            : isGridArrangement
            ? <GridTabBar hocComponentArr indexInFocus setIndexInFocus isLoading />
            : <TabBar isLoading position jumpTo navigationState ?options scrollEnabled=true />}
        renderScene
        style={s({
          marginHorizontal: -.sheetContentPadding->dp,
        })}
        options=descriptorDict
        commonOptions={{
          sceneStyle: s({marginHorizontal: sheetContentPadding->dp}),
        }}
      />
    }
  </UIUtils.RenderIf>
}
