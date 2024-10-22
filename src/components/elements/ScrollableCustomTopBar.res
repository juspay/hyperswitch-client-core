open ReactNative
open Style


module Styles = {
  let container = style(
    ~flex=1.,
    ~flexDirection=#row,
    ~alignItems=#center,
    ~marginLeft=0.->pct,
    ~marginTop=4.->pct,
    ~marginBottom=6.->pct,
    ()
  )

  let flatListContainer = style(
    ~flex=1.,
    ()
  )

  let dropdownContainer = style(
    ~position=#relative,
    ~marginLeft=10.->dp,
    ~zIndex=1000,
    
    ()
  )

  let dropdownList = style(
    ~position=#absolute,
    ~left=0.->dp,
    ~top=45.->dp,
    ~backgroundColor="#454340",
    ~borderRadius=5.,
    ~padding=5.->dp,
    ~shadowColor="#000",
    ~shadowOffset=offset(~width=0., ~height=4.),
    ~shadowOpacity=0.3,
    ~shadowRadius=4.65,
    ~elevation=8.,
    ~zIndex=1001,
    ~maxHeight=200.->dp,
    ()
  )

  let dropdownItem = style(
    ~backgroundColor="#454340",
    ~borderRadius=5.,
    ~padding=8.->dp,
    ~marginBottom=5.->dp,
    ~width=150.->dp,
    ~height=20.->dp,
    ~justifyContent=#center,
    ()
  )

  

  let dropdownItemText = style(
    ~color="#fff",
    ~fontSize=16.,
    
    ()
  )

  let toggleButton = style(
    ~width=40.->dp,
    ~height=55.->dp,
    ~borderRadius=5.,
    ~justifyContent=#center,
    ~alignItems=#center,
    ~backgroundColor="#ffffff",
    ~shadowColor="#4fb4f3",
    ~shadowOffset=offset(~width=0., ~height=2.),
    ~shadowOpacity=0.9,
    ~shadowRadius=6.84,
    ~elevation=5.,
    ~marginRight=1170.->dp,
    ()
  )
  let toggleText = style(
    ~color="#000000",
    ~fontSize=16.,
    ~fontWeight=#bold,
    ()
  )

  let rightToggleButton = style(
    ~position=#absolute,
    ~right=20.->dp,
    ~top=-50.->dp,
    ~backgroundColor="#3498db",
    ~paddingHorizontal=15.->dp,
    ~paddingVertical=5.->dp,
    ~borderRadius=5.,
    ~elevation=5.,
    ~marginRight=1380.->dp,
    ()
  )

  let rightButtonText = style(
    ~color="#fff",
    ~fontSize=16.,
    ()
  )
}

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
    let getShadowStyle = ShadowHook.useGetShadowStyle(~shadowIntensity, ~shadowColor, ())

    <View
      style={viewStyle(
        ~flex=1.,
        ~alignItems=#center,
        ~justifyContent=#center,
        ~marginRight=13.->dp,
        (),
      )}>
      <CustomTouchableOpacity
        onPress={_ => setIndexToScrollParentFlatList(index)}
        accessibilityRole=#button
        accessibilityState={Accessibility.state(~selected=isFocused, ())}
        accessibilityLabel=routeName
        testID=routeName
        activeOpacity=1.
        style={array([
          bgColor,
          getShadowStyle,
          viewStyle(
            ~backgroundColor={component.background},
            ~borderWidth=isFocused ? borderWidth +. 1.5 : borderWidth,
            ~borderColor=isFocused ? primaryColor : component.borderColor,
            ~minWidth=115.->dp,
            ~padding=10.->dp,
            ~borderRadius,
            (),
          ),
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

module DropdownItem = {
  @react.component
  let make = (~item: PMListModifier.hoc, ~onSelect) => {
    let (isPressed, setIsPressed) = React.useState(() => false)

    let itemStyle = 
      if isPressed {
        array([
          Styles.dropdownItem,
          style(
            ~backgroundColor="#1880bf",  // Blue background for "hover" effect
            ~shadowColor="#4fb4f3",  // Light blue glow
            ~shadowOffset=offset(~width=0., ~height=0.),
            ~shadowOpacity=0.8,
            ~shadowRadius=10.,
            ~elevation=5.,
            ()
          )
        ])
      } else {
        array([Styles.dropdownItem])
      }

    <TouchableOpacity
      style=itemStyle
      onPress={_ => onSelect(item)}
      onPressIn={_ => setIsPressed(_ => true)}
      onPressOut={_ => setIsPressed(_ => false)}
    >
      <Text style={Styles.dropdownItemText}>
        {React.string(item.name)}
      </Text>
    </TouchableOpacity>
  }
}

@react.component
let make = (
  ~hocComponentArr: array<PMListModifier.hoc>=[],
  ~indexInFocus,
  ~setIndexToScrollParentFlatList,
  ~height=75.->dp,
  ~dList: bool,
) => {
  let flatlistRef = React.useRef(Nullable.null)
  let logger = LoggerHook.useLoggerHook()

  let (showFullList, setShowFullList) = React.useState(() => false)
  let (secondPaymentMethod, setSecondPaymentMethod) = React.useState(() => None)
  let (showAllMethods, setShowAllMethods) = React.useState(() => false) // New state for toggling between views

  let fullHocComponentArr = hocComponentArr->Array.slice(~start=0, ~end=hocComponentArr->Array.length)

  let displayedPaymentMethods = dList
    ? fullHocComponentArr
    : hocComponentArr->Array.slice(~start=0, ~end=2)

  let updatedDisplayedMethods = displayedPaymentMethods->Array.map(item => {
    let index = Array.indexOf(displayedPaymentMethods, item)
    switch (secondPaymentMethod) {
    | Some(method) =>
      if index == 1 {
        method
      } else {
        item
      }
    | None => item
    }
  })

  let toggleFullList = (_event) => {
    setShowFullList(_prev => !_prev)
  }

  let toggleShowAllMethods = (_event) => {
    setShowAllMethods(_prev => !_prev)
  }

  let handleSelectMethod = (selectedMethod: PMListModifier.hoc) => {
    setSecondPaymentMethod(_ => Some(selectedMethod))
    let newIndexInFocus = Array.indexOf(fullHocComponentArr, selectedMethod)
    if newIndexInFocus != -1 {
      setIndexToScrollParentFlatList(newIndexInFocus)
      logger(
        ~logType=INFO,
        ~value=selectedMethod.name,
        ~category=USER_EVENT,
        ~paymentMethod=selectedMethod.name,
        ~eventName=PAYMENT_METHOD_CHANGED,
        (),
      )
    }
    setShowFullList(_prev => false)
  }

  <View style={Styles.container}>
    <View style={Styles.flatListContainer}>
      {dList
        ? <FlatList
            ref={flatlistRef->ReactNative.Ref.value}
            data=fullHocComponentArr
            showsHorizontalScrollIndicator=false
            keyExtractor={(_, i) => i->Int.toString}
            horizontal=true
            renderItem={({item, index}) =>
              <BottomTabList
                key={index->Int.toString}
                item
                index
                indexInFocus
                setIndexToScrollParentFlatList
              />
            }
          />
        : <FlatList
            ref={flatlistRef->ReactNative.Ref.value}
            data=Array.slice(updatedDisplayedMethods, ~start=0, ~end=2)
            showsHorizontalScrollIndicator=false
            keyExtractor={(_, i) => i->Int.toString}
            horizontal=true
            renderItem={({item, index}) =>
              <BottomTabList
                key={index->Int.toString}
                item
                index
                indexInFocus
                setIndexToScrollParentFlatList
              />
            }
          />
      }
    </View>
    
    {dList == false
      ? <View style={Styles.dropdownContainer}>
          <TouchableOpacity onPress={toggleFullList}>
            <View style={Styles.toggleButton}>
              <Text style={Styles.toggleText}>
                {React.string(showFullList ? "∧" : "∨")}
              </Text>
            </View>
          </TouchableOpacity>
          {showFullList 
            ? <View style={Styles.dropdownList}>
                <FlatList
                  data=fullHocComponentArr
                  keyExtractor={(_, i) => i->Int.toString}
                  showsVerticalScrollIndicator=true
                  renderItem={({item}) => 
                    <DropdownItem item onSelect={handleSelectMethod} />
                  }
                />
              </View>
            : React.null}
        </View>
      : React.null}

    //<TouchableOpacity onPress={toggleShowAllMethods} style={Styles.rightToggleButton}>
    //  <Text style={Styles.rightButtonText}>
    //    {React.string(showAllMethods ? "Hide" : "Show")}
    //  </Text>
    //</TouchableOpacity>
  </View>
}

