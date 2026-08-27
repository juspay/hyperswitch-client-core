open ReactNative
open Style
open PaymentEvents

module Scene = {
  @react.component
  let make = (
    ~hoc: AllApiDataModifier.hoc,
    ~isScreenFocus,
    ~setConfirmButtonData: GlobalConfirmButton.confirmButtonData => unit,
  ) => {
    hoc.componentHoc(~isScreenFocus, ~setConfirmButtonData)
  }
}

module MemoizedScene = {
  let make = React.memo(Scene.make)
}

@react.component
let make = (
  ~hocComponentArr: array<AllApiDataModifier.hoc>=[],
  ~isLoading,
  ~setConfirmButtonData,
) => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let layout = nativeProp.configuration.paymentMethodLayout

  let (indexInFocus, setIndexInFocus) = React.useState(_ => 0)
  let setIndexInFocus = React.useCallback1(index => {
    setIndexInFocus(_ => index)
  }, [setIndexInFocus])

  let emitter = PaymentEvents.usePaymentEventEmitter()

  React.useEffect2(() => {
    switch hocComponentArr->Array.get(indexInFocus) {
    | Some(hoc) =>
      if hoc.name !== "loading" {
        let event = PaymentEvents.buildPaymentMethodStatusEvent(
          ~paymentMethod=hoc.name,
          ~paymentMethodType=hoc.paymentMethodType,
          ~isSavedPaymentMethod=false,
        )
        emitter.emitPaymentMethodStatus(~event)
      }
    | None => ()
    }
    None
  }, (indexInFocus, hocComponentArr))

  let {sheetContentPadding, iconColor, component} = ThemebasedStyle.useThemeBasedStyle()

  let isGridArrangement = layout.paymentMethodsArrangementForTabs === ArrangementGrid

  let routes = React.useMemo1(() =>
    hocComponentArr->Array.mapWithIndex((hoc, index) => {
      let route: TabViewType.route = {
        key: index->Int.toString,
        title: hoc.name,
      }
      route
    })
  , [hocComponentArr])

  let descriptorDict = React.useMemo4(() => {
    let descriptorDict: Dict.t<TabViewType.tabDescriptor> = Dict.make()

    hocComponentArr->Array.forEachWithIndex((hoc, index) => {
      descriptorDict->Dict.set(
        index->Int.toString,
        {
          icon: (props: TabViewType.iconProps) =>
            isLoading
              ? <CustomLoader height="18" width="18" />
              : <Icon
                  name=hoc.name
                  width=18.
                  height=18.
                  fill={props.focused ? component.selected.color : iconColor}
                />,
          label: (props: TabViewType.labelProps) =>
            isLoading
              ? <CustomLoader height="18" width="40" />
              : <TextWrapper
                  text=hoc.name
                  textType={props.focused ? CardTextBold : CardText}
                  overrideStyle={props.focused
                    ? Some(s({color: component.selected.color}))
                    : None}
                />,
        },
      )
    })

    descriptorDict
  }, (hocComponentArr, isLoading, iconColor, component.selected.color))

  let renderScene = React.useCallback3((
    ~route: TabViewType.route,
    ~jumpTo as _,
    ~position as _,
  ) => {
    switch route.key
    ->Int.fromString
    ->Option.flatMap(index => hocComponentArr->Array.get(index)->Option.map(hoc => (hoc, index))) {
    | Some((hoc, index)) =>
      <MemoizedScene
        key=route.key hoc isScreenFocus={indexInFocus === index} setConfirmButtonData
      />
    | None => React.null
    }
  }, (hocComponentArr, indexInFocus, setConfirmButtonData))

  let commonOptions = React.useMemo1((): TabViewType.tabDescriptor => {
    sceneStyle: s({marginHorizontal: sheetContentPadding->dp}),
  }, [sheetContentPadding])

  <UIUtils.RenderIf condition={hocComponentArr->Array.length > 0}>
    {
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
        lazyBool=true
        lazyPreloadDistance=1
        renderTabBar={(~position, ~jumpTo, ~navigationState, ~options) =>
          isScrollBarOnlyCards
            ? <Space height=24. />
            : isGridArrangement
            ? <GridTabBar hocComponentArr indexInFocus setIndexInFocus isLoading />
            : <TabBar
                isLoading
                position
                jumpTo
                navigationState
                ?options
                scrollEnabled=true
                activeColor=component.selected.color
              />}
        renderScene
        style={s({
          marginHorizontal: -.sheetContentPadding->dp,
        })}
        options=descriptorDict
        commonOptions
      />
    }
  </UIUtils.RenderIf>
}
