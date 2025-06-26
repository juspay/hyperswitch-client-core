open ReactNative
open Style

type customPickerType = {
  label: string,
  value: string,
  icon?: string,
}

@react.component
let make = (
  ~value,
  ~setValue,
  ~borderBottomLeftRadius=0.,
  ~borderBottomRightRadius=0.,
  ~borderBottomWidth=0.,
  ~disabled=false,
  ~placeholderText,
  ~items: array<customPickerType>,
  ~isValid=true,
  ~isLoading=false,
  ~isCountryStateFields=false,
  ~style=?,
  ~showValue=false,
) => {
  let (isModalVisible, setIsModalVisible) = React.useState(_ => false)
  let (searchInput, setSearchInput) = React.useState(_ => None)
  let (_, fetchCountryStateData) = React.useContext(CountryStateDataContext.countryStateDataContext)
  React.useEffect1(() => {
    if isCountryStateFields {
      fetchCountryStateData()
    }
    None
  }, [isCountryStateFields])
  let pickerRef = React.useRef(Nullable.null)
  let searchInputRef = React.useRef(Nullable.null)
  let {
    bgColor,
    component,
    iconColor,
    borderRadius,
    borderWidth,
  } = ThemebasedStyle.useThemeBasedStyle()
  let (nativeProps, _) = React.useContext(NativePropContext.nativePropContext)
  let {bgTransparentColor} = ThemebasedStyle.useThemeBasedStyle()
  let transparentBG = nativeProps.sdkState == PaymentSheet ? bgTransparentColor : viewStyle()

  React.useEffect1(() => {
    setSearchInput(_ => None)
    None
  }, [isModalVisible])
  <View ?style>
    <CustomTouchableOpacity
      disabled activeOpacity=1. onPress={_ => setIsModalVisible(prev => !prev)}>
      <CustomInput
        state={switch items->Array.find(x => x.value == value->Option.getOr("")) {
        | Some(y) => showValue ? y.value : y.label
        | _ => value->Option.getOr("")
        }}
        setState={_ => ()}
        borderBottomLeftRadius
        borderBottomRightRadius
        borderBottomWidth
        isValid
        borderTopWidth=borderWidth
        borderLeftWidth=borderWidth
        borderRightWidth=borderWidth
        borderTopLeftRadius=borderRadius
        borderTopRightRadius=borderRadius
        placeholder=placeholderText
        editable=false
        textColor=component.color
        iconRight=CustomIcon(
          <CustomTouchableOpacity disabled onPress={_ => setIsModalVisible(prev => !prev)}>
            <ChevronIcon width=13. height=13. fill=iconColor />
          </CustomTouchableOpacity>,
        )
        pointerEvents={#none}
      />
    </CustomTouchableOpacity>
    <Modal
      visible={isModalVisible}
      transparent={true}
      animationType=#slide
      onShow={() => {
        let _ = setTimeout(() => {
          switch searchInputRef.current->Nullable.toOption {
          | Some(input) => input->TextInputElement.focus
          | None => ()
          }
        }, 300)
      }}>
      <SafeAreaView />
      <View style={array([viewStyle(~flex=1., ~paddingTop=24.->dp, ()), transparentBG])}>
        <View
          style={array([
            viewStyle(
              ~flex=1.,
              ~width=100.->pct,
              ~backgroundColor=component.background,
              ~justifyContent=#center,
              ~alignItems=#center,
              ~borderRadius=10.,
              ~padding=15.->dp,
              ~paddingHorizontal=20.->dp,
              (),
            ),
            bgColor,
          ])}>
          <View
            style={viewStyle(
              ~flexDirection=#row,
              ~width=100.->pct,
              ~alignItems=#center,
              ~justifyContent=#"space-between",
              (),
            )}>
            <TextWrapper text=placeholderText textType={HeadingBold} />
            <CustomTouchableOpacity
              onPress={_ => setIsModalVisible(prev => !prev)}
              style={viewStyle(~padding=14.->dp, ())}>
              <Icon name="close" width=20. height=20. fill=iconColor />
            </CustomTouchableOpacity>
          </View>
          <CustomInput
            reference={Some(searchInputRef)}
            placeholder={"Search " ++ placeholderText} // MARK: add Search to locale
            state={searchInput->Option.getOr("")}
            setState={val => {
              setSearchInput(_ => Some(val))
            }}
            keyboardType=#default
            textColor=component.color
            borderBottomLeftRadius=borderRadius
            borderBottomRightRadius=borderRadius
            borderTopLeftRadius=borderRadius
            borderTopRightRadius=borderRadius
            borderTopWidth=borderWidth
            borderBottomWidth=borderWidth
            borderLeftWidth=borderWidth
            borderRightWidth=borderWidth
          />
          <Space />
          {isLoading
            ? <ActivityIndicator
                size={Large}
                color=iconColor
                style={viewStyle(~flex=1., ~width=100.->pct, ~paddingHorizontal=10.->dp, ())}
              />
            : <FlatList
                ref={pickerRef->ReactNative.Ref.value}
                keyboardShouldPersistTaps={#handled}
                data={items->Array.filter(x =>
                  x.label
                  ->String.toLowerCase
                  ->String.includes(searchInput->Option.getOr("")->String.toLowerCase)
                )}
                style={viewStyle(~flex=1., ~width=100.->pct, ~paddingHorizontal=10.->dp, ())}
                showsHorizontalScrollIndicator=false
                keyExtractor={(_, i) => i->Int.toString}
                horizontal=false
                renderItem={({item, index}) =>
                  <CustomTouchableOpacity
                    key={index->Int.toString}
                    style={viewStyle(~height=32.->dp, ~margin=1.->dp, ~justifyContent=#center, ())}
                    onPress={_ => {
                      setValue(_ => Some(item.value))
                      setIsModalVisible(_ => false)
                    }}>
                    <TextWrapper
                      text={item.icon->Option.getOr("") ++ item.label} textType=ModalText
                    />
                  </CustomTouchableOpacity>}
              />}
        </View>
      </View>
    </Modal>
    {isLoading
      ? <View
          style={viewStyle(
            ~overflow=#hidden,
            ~position=#absolute,
            ~opacity=0.6,
            ~width=100.->pct,
            ~height=100.->pct,
            (),
          )}>
          <CustomLoader />
        </View>
      : React.null}
  </View>
}
