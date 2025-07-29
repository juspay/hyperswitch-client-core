open ReactNative
open Style
@react.component
let make = (
  ~hocComponentArr: array<PMListModifier.hoc>=[],
  ~loading=true,
  ~setConfirmButtonDataRef,
) => {
  let (indexInFocus, setIndexInFocus) = React.useState(_ => 0)
  let setIndexInFocus = React.useCallback1(ind => setIndexInFocus(_ => ind), [setIndexInFocus])
  let sceneMap = Map.make()

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

  <UIUtils.RenderIf condition={data->Array.length > 0}>
    {
      let routes = data->Array.mapWithIndex((hoc, index) => {
        sceneMap->Map.set(index, (~route as _, ~position as _, ~jumpTo as _) =>
          hoc.componentHoc(~isScreenFocus=indexInFocus == index, ~setConfirmButtonDataRef)
        )

        let route: TabViewType.route = {
          key: index,
          title: hoc.name,
          componentHoc: hoc.componentHoc,
        }
        route
      })

      let isSinglePaymentMethod = data->Array.length == 1

      <TabView
        sceneContainerStyle={s({padding: 10.->dp})}
        style={s({marginHorizontal: -10.->dp})}
        indexInFocus
        routes
        onIndexChange=setIndexInFocus
        renderTabBar={(~indexInFocus, ~routes as _, ~position as _, ~layout as _, ~jumpTo) => {
          isSinglePaymentMethod
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
