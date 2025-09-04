open ReactNative
open Style
open PaymentMethodListType

// Type alias for grouped fields
type groupedFields = option<array<(string, array<SuperpositionHelper.fieldConfig>)>>

// Type alias for the setter function
type groupedFieldsSetter = groupedFields => unit

let getInternalName = (displayName: string) => {
  switch displayName {
  | "Card" => "card"
  | _ =>
    Types.defaultConfig.redirectionList
    ->Array.find(item => item.text == displayName)
    ->Option.map(item => item.name)
    ->Option.getOr(displayName->String.toLowerCase)
  }
}

module BottomTabList = {
  @react.component
  let make = (
    ~item: PMListModifier.hoc,
    ~index: int,
    ~indexInFocus: int,
    ~setIndexToScrollParentFlatList,
    ~currentPaymentMethod: string,
    ~setCurrentPaymentMethod: (string => string) => unit,
    ~onPaymentMethodSelected: (string => unit),
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
    let getShadowStyle = ShadowHook.useGetShadowStyle(~shadowIntensity, ~shadowColor, ())

    <View style={s({flex: 1., alignItems: #center, justifyContent: #center, marginRight: 13.->dp})}>
      <CustomTouchableOpacity
        onPress={_ => {
          let internalName = getInternalName(routeName)
          
          if currentPaymentMethod !== internalName {
            setCurrentPaymentMethod(_ => internalName)
            onPaymentMethodSelected(internalName)
          }                  
          setIndexToScrollParentFlatList(index)
        }}
        accessibilityRole=#button
        accessibilityState={selected: isFocused}
        accessibilityLabel=routeName
        testID=routeName
        activeOpacity=1.
        style={array([
          bgColor,
          getShadowStyle,
          s({
            // ~backgroundColor={isFocused ? component.background : "transparent"},
            backgroundColor: component.background,
            borderWidth: isFocused ? borderWidth +. 1.5 : borderWidth,
            borderColor: isFocused ? primaryColor : component.borderColor,
            minWidth: 115.->dp,
            padding: 10.->dp,
            borderRadius,
          }),
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
              | true => CardTextBold
              | _ => CardText
              }}
            />}
      </CustomTouchableOpacity>
    </View>
  }
}

@react.component
let make = (
  ~hocComponentArr: array<PMListModifier.hoc>=[],
  ~indexInFocus,
  ~setIndexToScrollParentFlatList,
  ~height=75.->dp,
  ~onPaymentMethodChange: option<(string) => unit>=?,
  ~onSuperpositionFieldsChange: option<(option<array<(string, array<SuperpositionHelper.fieldConfig>)>>) => unit>=?,
) => {
  let flatlistRef = React.useRef(Nullable.null)
  let logger = LoggerHook.useLoggerHook()
  
  let (currentPaymentMethod, setCurrentPaymentMethod) = React.useState(_ => "")
  
  let (allApiData, _) = React.useContext(AllApiDataContext.allApiDataContext)

  let scrollToItem = () => {
    switch flatlistRef.current->Nullable.toOption {
    | Some(ref) => {
        let flatlistParam: FlatList.scrollToIndexParams = {
          animated: true,
          viewPosition: 0.5,
          index: {indexInFocus},
        }
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
    <View style={s({height, paddingHorizontal: 10.->dp})}>
      <FlatList
        ref={flatlistRef->ReactNative.Ref.value}
        keyboardShouldPersistTaps={#handled}
        data=hocComponentArr
        style={s({flex: 1., width: 100.->pct})}
        showsHorizontalScrollIndicator=false
        keyExtractor={(_, i) => i->Int.toString}
        horizontal=true
        renderItem={({item, index}) =>
          <BottomTabList
            key={index->Int.toString} item index indexInFocus setIndexToScrollParentFlatList
            currentPaymentMethod setCurrentPaymentMethod
            onPaymentMethodSelected={internalName => {
              switch onPaymentMethodChange {
              | Some(callback) => callback(internalName)
              | None => ()
              }
              
              let paymentMethodData = getPaymentMethodDataByType(internalName, allApiData.paymentList)
              
              // Create connector context for superposition
              let connectorStrings = paymentMethodData.eligible_connectors
                ->Array.filterMap(JSON.Decode.string)
                ->Array.map(Utils.capitalizeFirst)
              
              let connectorContext: SuperpositionHelper.connectorArrayContext = {
                eligibleConnectors: connectorStrings,
                payment_method: paymentMethodData.payment_method,
                payment_method_type: Some(Utils.capitalizeFirst(internalName)),
                country: Some("US"),
                mandate_type: Some("non_mandate"),
              }
              
              let _ = SuperpositionHelper.initSuperpositionAndGetRequiredFields(~contextWithConnectorArray=connectorContext)
              ->Promise.then(result => {
                switch result {
                | Some(fields) => 
                  switch onSuperpositionFieldsChange {
                  | Some(callback) => callback(Some(fields))
                  | None => ()
                  }
                | None => 
                  switch onSuperpositionFieldsChange {
                  | Some(callback) => callback(None)
                  | None => ()
                  }
                }
                Promise.resolve()
              })
              ->Promise.catch(_ => {
                switch onSuperpositionFieldsChange {
                | Some(callback) => callback(None)
                | None => ()
                }
                Promise.resolve()
              })
            }}
          />}
      />
    </View>
  </>
}
