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
  let sceneMap = Map.make()

  <UIUtils.RenderIf condition={hocComponentArr->Array.length > 0}>
    {
      let routes = hocComponentArr->Array.mapWithIndex((hoc, index) => {
        sceneMap->Map.set(index, (~route as _, ~position as _, ~jumpTo as _) =>
          hoc.componentHoc(~isScreenFocus=indexInFocus == index, ~setConfirmButtonData)
        )

        let route: TabViewType.route = {
          key: index,
          title: hoc.name,
          componentHoc: hoc.componentHoc,
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
        sceneContainerStyle={s({padding: 10.->dp})}
        style={s({marginHorizontal: -10.->dp})}
        indexInFocus
        routes
        onIndexChange=setIndexInFocus
        renderTabBar={(~indexInFocus, ~routes as _, ~position as _, ~layout as _, ~jumpTo) => {
          isScrollBarOnlyCards
            ? React.null
            : <ScrollableCustomTopBar
                hocComponentArr indexInFocus setIndexToScrollParentFlatList={jumpTo}
              />
        }}
        renderScene={SceneMap.sceneMap(sceneMap)}
        isLoading
      />
    }
  </UIUtils.RenderIf>
}
