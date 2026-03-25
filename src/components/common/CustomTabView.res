open ReactNative
open Style
open PaymentEvents

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
