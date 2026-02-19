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

  let processedTabs = React.useMemo1(() => {
    let upiTabs = []
    let result = []

    hocComponentArr->Array.forEach(hoc => {
      switch hoc.group {
      | UPI => upiTabs->Array.push(hoc)->ignore
      | None => result->Array.push(hoc)->ignore
      }
    })

    if upiTabs->Array.length > 0 {
      result
      ->Array.push({
        name: "UPI",
        componentHoc: (~isScreenFocus, ~setConfirmButtonData) =>
          <CustomAccordionView
            hocComponentArr=upiTabs
            isLoading=false
            isParentTabFocused=isScreenFocus
            setConfirmButtonData
          />,
        group: None,
      })
      ->ignore
    }

    result
  }, [hocComponentArr])

  let {sheetContentPadding, primaryColor, iconColor} = ThemebasedStyle.useThemeBasedStyle()

  let (renderScene, descriptorDict) = React.useMemo3(() => {
    let map = Map.make()
    let descriptorDict: Dict.t<TabViewType.tabDescriptor> = Dict.make()

    processedTabs->Array.forEachWithIndex((hoc, index) => {
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
  }, (processedTabs, indexInFocus, isLoading))

  <UIUtils.RenderIf condition={processedTabs->Array.length > 0}>
    {
      let routes = processedTabs->Array.mapWithIndex((hoc, index) => {
        let route: TabViewType.route = {
          key: index->Int.toString,
          title: hoc.name,
        }
        route
      })

      let isScrollBarOnlyCards =
        processedTabs->Array.length == 1 &&
          switch processedTabs->Array.get(0) {
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
