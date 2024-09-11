open ReactNative
open Style
open TabViewType

module TopTabScreenWraper = {
  @react.component
  let make = (~children, ~setDynamicHeight, ~isScrollBarOnlyCards, ~isScreenFocus) => {
    let (viewHeight, setViewHeight) = React.useState(_ => 0.)
    let updateTabHeight = (event: Event.layoutEvent) => {
      let nativeEvent = Event.LayoutEvent.nativeEvent(event)
      let vheight =
        nativeEvent
        ->JSON.Decode.object
        ->Option.getOr(Dict.make())
        ->Dict.get("layout")
        ->Option.getOr(JSON.Encode.null)
        ->JSON.Decode.object
        ->Option.getOr(Dict.make())
        ->Dict.get("height")
      switch vheight {
      | Some(height) => {
          let height = height->JSON.Decode.float->Option.getOr(0.)
          if (viewHeight -. height)->Math.abs > 10. {
            setViewHeight(_ => height)
          } else if height == 0. {
            setViewHeight(_ => 100.)
          }
        }
      | None => ()
      }
    }

    React.useEffect3(() => {
      isScreenFocus ? setDynamicHeight(viewHeight +. {isScrollBarOnlyCards ? 0. : 90.}) : ()
      None
    }, (viewHeight, setDynamicHeight, isScreenFocus))
    <View onLayout=updateTabHeight style={viewStyle(~width=100.->pct, ())}> children </View>
  }
}

@react.component
let make = (
  ~hocComponentArr: array<PMListModifier.hoc>=[],
  ~loading=true,
  ~setConfirmButtonDataRef,
) => {
  let dimensions = Dimensions.useWindowDimensions()
  let (indexInFocus, setIndexInFocus) = React.useState(_ => 0)
  let setIndexInFocus = React.useCallback1(ind => setIndexInFocus(_ => ind), [setIndexInFocus])
  let (height, setHeight) = React.useState(_ => 0.)

  let setDynamicHeight = height => {
    setHeight(_ => height)
    ()
  }

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

  <View
    style={viewStyle(
      ~minHeight=115.->dp,
      ~width=100.->pct,
      ~overflow=#hidden,
      ~height=height->dp,
      (),
    )}>
    {switch data->Array.length {
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
          <TopTabScreenWraper
            setDynamicHeight isScrollBarOnlyCards isScreenFocus={indexInFocus == route.key}>
            {SceneMap.sceneMap(
              switch data->Array.get(route.key) {
              | Some(hoc) =>
                hoc.componentHoc(~isScreenFocus=indexInFocus == route.key, ~setConfirmButtonDataRef)
              | None => React.null
              },
              route,
              jumpTo,
              position,
            )}
          </TopTabScreenWraper>}
        initialLayout={width: dimensions.width}
        // pagerStyle={viewStyle(~height={heightPosition->Animated.StyleProp.size}, ())}
      />
    }}
  </View>
}
