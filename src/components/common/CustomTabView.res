open ReactNative
open Style
@react.component
let make = (
  ~hocComponentArr: array<PMListModifier.hoc>=[],
  ~loading=true,
  ~setConfirmButtonDataRef,
  ~setDynamicFieldsState: (DynamicFieldsTypes.dynamicFieldsState => DynamicFieldsTypes.dynamicFieldsState) => unit,
  ~indexInFocus=0,
  ~setIndexInFocus: (int => int) => unit,
) => {
  let setIndexInFocus = React.useCallback1(ind => setIndexInFocus(_ => ind), [setIndexInFocus])
  let sceneMap = Map.make()

  let data = React.useMemo1(() => {
    if loading {
      hocComponentArr
      ->Array.pushMany([
        {
          name: "loading",
          componentHoc: (~isScreenFocus as _, ~setConfirmButtonDataRef as _, ~setDynamicFieldsState as _) => <>
            <Space height=20. />
            <CustomLoader height="33" />
            <Space height=5. />
            <CustomLoader height="33" />
          </>,
        },
        {
          name: "loading",
          componentHoc: (~isScreenFocus as _, ~setConfirmButtonDataRef as _, ~setDynamicFieldsState as _) => React.null,
        },
      ])
      ->ignore
      hocComponentArr
    } else {
      hocComponentArr
    }
  }, [hocComponentArr])

  <UIUtils.RenderIf condition={data->Array.length > 0}>
    {
      let routes = data->Array.mapWithIndex((hoc, index) => {
        sceneMap->Map.set(index, (~route as _, ~position as _, ~jumpTo as _) =>
          hoc.componentHoc(~isScreenFocus=indexInFocus == index, ~setConfirmButtonDataRef, ~setDynamicFieldsState)
        )

        let route: TabViewType.route = {
          key: index,
          title: hoc.name,
          componentHoc: hoc.componentHoc,
        }
        route
      })

      let isScrollBarOnlyCards =
        data->Array.length == 1 &&
          switch data->Array.get(0) {
          | Some({name}) => name == "Card"
          | None => true
          }

      <TabView
        sceneContainerStyle={viewStyle(~padding=10.->dp, ())}
        style={viewStyle(~marginHorizontal=-10.->dp, ())}
        indexInFocus
        routes
        onIndexChange=setIndexInFocus
        renderTabBar={(~indexInFocus, ~routes as _, ~position as _, ~layout as _, ~jumpTo) => {
          isScrollBarOnlyCards
            ? React.null
            : <ScrollableCustomTopBar
                hocComponentArr=data indexInFocus setIndexToScrollParentFlatList={jumpTo}
              />
        }}
        renderScene={SceneMap.sceneMap(sceneMap)}
      />
    }
  </UIUtils.RenderIf>
}
