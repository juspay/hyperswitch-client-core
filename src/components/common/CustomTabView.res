@react.component
let make = (
  ~hocComponentArr: array<PMListModifier.hoc>=[],
  ~loading=true,
  ~setConfirmButtonDataRef,
) => {
  let (indexInFocus, setIndexInFocus) = React.useState(_ => 0)
  let setIndexInFocus = React.useCallback1(ind => setIndexInFocus(_ => ind), [setIndexInFocus])

  let data = React.useMemo1(() => {
    if loading {
      hocComponentArr
      ->Array.pushMany([
        {
          name: "loading",
          componentHoc: (~isScreenFocus as _, ~setConfirmButtonDataRef as _) => <>
            <Space height=20. />
            <CustomLoader height="33" />
            <Space height=5. />
            <CustomLoader height="33" />
          </>,
        },
        {
          name: "loading",
          componentHoc: (~isScreenFocus as _, ~setConfirmButtonDataRef as _) => React.null,
        },
      ])
      ->ignore
      hocComponentArr
    } else {
      hocComponentArr
    }
  }, [hocComponentArr])

  let isScrollBarOnlyCards =
    data->Array.length == 1 &&
      switch data->Array.get(0) {
      | Some({name}) => name == "Card"
      | None => true
      }

  switch data->Array.length {
  | 0 => React.null
  | _ =>
    <TabView
      indexInFocus
      routes={data->Array.mapWithIndex((hoc, index) => {
        let route: TabViewType.route = {
          key: index,
          title: hoc.name,
          componentHoc: hoc.componentHoc,
        }
        route
      })}
      onIndexChange=setIndexInFocus
      renderTabBar={(~indexInFocus, ~routes as _, ~position as _, ~layout as _, ~jumpTo) => {
        isScrollBarOnlyCards
          ? React.null
          : <ScrollableCustomTopBar
              hocComponentArr=data indexInFocus setIndexToScrollParentFlatList={jumpTo}
            />
      }}
      renderScene={(~route, ~position, ~layout as _, ~jumpTo) =>
        SceneMap.sceneMap(
          switch data->Array.get(route.key) {
          | Some(hoc) =>
            hoc.componentHoc(~isScreenFocus=indexInFocus == route.key, ~setConfirmButtonDataRef)
          | None => React.null
          },
          route,
          jumpTo,
          position,
        )}
    />
  }
}
