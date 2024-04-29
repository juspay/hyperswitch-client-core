open ReactNative
open Style

module BottomTabList = {
  @react.component
  let make = (
    ~item: PMListModifier.hoc,
    ~index,
    ~indexInFocus,
    ~setIndexToScrollParentFlatList,
  ) => {
    let isFocused = index == indexInFocus
    let routeName = item.name
    let isLoading = routeName == "loading"

    let {
      iconColor,
      component,
      primaryColor,
      borderRadius,
      bgColor,
      borderWidth,
      shadowColor,
      shadowIntensity,
    } = ThemebasedStyle.useThemeBasedStyle()

    let shadowOffsetHeight = shadowIntensity
    let elevation = shadowIntensity
    let shadowRadius = shadowIntensity
    let shadowOpacity = 0.2
    let shadowOffsetWidth = 0.

    <View
      style={viewStyle(
        ~flex=1.,
        ~alignItems=#center,
        ~justifyContent=#center,
        ~marginRight=13.->dp,
        (),
      )}>
      <TouchableOpacity
        onPress={_ => setIndexToScrollParentFlatList(index)}
        accessibilityRole=#button
        accessibilityState={Accessibility.state(~selected=isFocused, ())}
        accessibilityLabel=routeName
        testID=routeName
        activeOpacity=1.
        style={array([
          bgColor,
          viewStyle(
            // ~backgroundColor={isFocused ? component.background : "transparent"},
            ~backgroundColor={component.background},
            ~borderWidth=isFocused ? borderWidth +. 1.5 : borderWidth,
            ~borderColor=isFocused ? primaryColor : component.borderColor,
            ~minWidth=115.->dp,
            ~padding=10.->dp,
            ~borderRadius,
            // ~elevation=isFocused ? shadow : 0.,
            //~shadowRadius={shadow /. 4.},
            // ~shadowOffset={
            //   shadow != 0. && isFocused
            //     ? offset(~width=-1. *. shadow, ~height=1. *. shadow)
            //     : offset(~width=-0., ~height=0.)
            // },
            // ~shadowOpacity=isFocused ? 0.15 : 0.,
            ~elevation,
            ~shadowRadius,
            ~shadowOpacity,
            ~shadowOffset={
              offset(~width=shadowOffsetWidth, ~height=shadowOffsetHeight /. 2.)
            },
            ~shadowColor,
            (),
          ),
          // bgColor,
        ])}>
        {isLoading
          ? <CustomLoader height="18" width="18" />
          : <Icon
              name=routeName width=18. height=18. fill={isFocused ? primaryColor : iconColor}
            />}
        <Space height=5. />
        {isLoading
          ? <CustomLoader height="18" width="40" />
          : <TextWrapper
              text=routeName
              textType={switch isFocused {
              | true => TextActive
              | _ => CardText
              }}
            />}
      </TouchableOpacity>
    </View>
  }
}

@react.component
let make = (
  ~hocComponentArr: array<PMListModifier.hoc>=[],
  ~indexInFocus,
  ~setIndexToScrollParentFlatList,
  ~height=75.->dp,
) => {
  let flatlistRef = React.useRef(Nullable.null)
  let logger = LoggerHook.useLoggerHook()

  let scrollToItem = () => {
    switch flatlistRef.current->Nullable.toOption {
    | Some(ref) => {
        let flatlistParam = FlatList.scrollToIndexParams(
          ~animated=true,
          ~viewPosition=0.5,
          ~index={indexInFocus},
          (),
        )
        ref->FlatList.scrollToIndex(flatlistParam)
        switch hocComponentArr[indexInFocus] {
        | Some(focusedComponent) =>
          logger(
            ~logType=INFO,
            ~value=focusedComponent.name,
            ~category=USER_EVENT,
            ~paymentMethod=focusedComponent.name,
            ~eventName=PAYMENT_METHOD_CHANGED,
            (),
          )
        | None => ()
        }
      }

    | None => ()
    }
    ()
  }
  React.useEffect1(() => {
    if hocComponentArr->Array.length > 0 {
      scrollToItem()
    }
    None
  }, [indexInFocus])

  <>
    <Space height=15. />
    <View style={viewStyle(~height, ~marginHorizontal=18.->dp, ())}>
      <FlatList
        ref={flatlistRef->ReactNative.Ref.value}
        data=hocComponentArr
        style={viewStyle(~flex=1., ~width=100.->pct, ())}
        showsHorizontalScrollIndicator=false
        keyExtractor={(_, i) => i->Int.toString}
        horizontal=true
        renderItem={({item, index}) =>
          <BottomTabList
            key={index->Int.toString} item index indexInFocus setIndexToScrollParentFlatList
          />}
      />
    </View>
  </>
}
