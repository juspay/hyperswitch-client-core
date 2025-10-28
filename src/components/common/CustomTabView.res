open ReactNative
open Style

@react.component
let make = (
  ~hocComponentArr: array<AllApiDataModifier.hoc>=[],
  ~isLoading,
  ~setConfirmButtonData,
) => {
  let (indexInFocus, setIndexInFocus) = React.useState(_ => 0)
  let setIndexInFocus = React.useCallback1(index => {
    setIndexInFocus(_ => index)
  }, [setIndexInFocus])

  let {sheetContentPadding, primaryColor, iconColor} = ThemebasedStyle.useThemeBasedStyle()

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
