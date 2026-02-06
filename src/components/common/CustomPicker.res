open ReactNative
open Style

@react.component
let make = (
  ~value,
  ~setValue,
  ~borderBottomLeftRadius=0.,
  ~borderBottomRightRadius=0.,
  ~borderBottomWidth=0.,
  ~disabled=false,
  ~placeholderText,
  ~items: array<SdkTypes.customPickerType>,
  ~isValid=true,
  ~isLoading=false,
  ~isCountryStateFields=false,
  ~style=?,
  ~showValue=false,
  ~onFocus,
  ~onBlur,
  ~animate=?,
  ~accessible=?,
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
  let (viewPortContants, _) = React.useContext(ViewportContext.viewPortContext)
  let {bgTransparentColor} = ThemebasedStyle.useThemeBasedStyle()
  let transparentBG = nativeProps.sdkState == PaymentSheet ? bgTransparentColor : empty

  React.useEffect1(() => {
    setSearchInput(_ => None)
    None
  }, [isModalVisible])
  <View ?style>
    <CustomPressable disabled onPress={_ => setIsModalVisible(prev => !prev)}>
      <CustomInput
        state={switch items->Array.find(x =>
          x.value == value->Option.getOr("") || x.label == value->Option.getOr("")
        ) {
        | Some(y) => showValue ? y.value : y.label
        | _ => value->Option.getOr("")
        }}
        setState={_ => ()}
        isValid
        borderTopWidth=borderWidth
        borderLeftWidth=borderWidth
        borderRightWidth=borderWidth
        borderBottomWidth=borderWidth
        borderTopLeftRadius=borderRadius
        borderTopRightRadius=borderRadius
        borderBottomLeftRadius=borderRadius
        borderBottomRightRadius=borderRadius
        placeholder=placeholderText
        editable=false
        textColor=component.color
        iconRight=CustomIcon(
          <CustomPressable disabled onPress={_ => setIsModalVisible(prev => !prev)}>
            <ChevronIcon width=13. height=13. fill=iconColor />
          </CustomPressable>,
        )
        pointerEvents={#none}
        onBlur
        onFocus
        ?animate
        ?accessible
      />
    </CustomPressable>
    <Modal
      visible={isModalVisible}
      transparent={true}
      animationType=#slide
      onShow={() => {
        setTimeout(() => {
          switch searchInputRef.current->Nullable.toOption {
          | Some(input) => input->TextInputElement.focus
          | None => ()
          }
        }, 300)->ignore
      }}
    >
      <View
        style={array([
          s({
            flex: 1.,
            paddingTop: viewPortContants.topInset->dp,
          }),
          transparentBG,
        ])}
      >
        <View
          style={array([
            s({
              flex: 1.,
              width: 100.->pct,
              backgroundColor: component.background,
              justifyContent: #center,
              alignItems: #center,
              borderTopLeftRadius: 15.,
              borderTopRightRadius: 15.,
              borderBottomLeftRadius: 0.,
              borderBottomRightRadius: 0.,
              paddingHorizontal: 20.->dp,
            }),
            bgColor,
          ])}
        >
          <Space />
          <View
            style={s({
              flexDirection: #row,
              width: 100.->pct,
              alignItems: #center,
              justifyContent: #"space-between",
            })}
          >
            <TextWrapper text=placeholderText textType={HeadingBold} />
            <CustomPressable
              onPress={_ => setIsModalVisible(prev => !prev)} style={s({padding: 14.->dp})}
            >
              <Icon name="close" width=20. height=20. fill=iconColor />
            </CustomPressable>
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
            ?accessible
          />
          <Space />
          {isLoading
            ? <ActivityIndicator
                size={Large}
                color=iconColor
                style={s({flex: 1., width: 100.->pct, paddingHorizontal: 10.->dp})}
              />
            : <FlatList
                ref={pickerRef->ReactNative.Ref.value}
                keyboardShouldPersistTaps={#handled}
                keyboardDismissMode={#"on-drag"}
                data={items->Array.filter(x =>
                  x.label
                  ->String.toLowerCase
                  ->String.includes(searchInput->Option.getOr("")->String.toLowerCase)
                )}
                style={s({
                  flex: 1.,
                  width: 100.->pct,
                  paddingHorizontal: 10.->dp,
                  paddingTop: 10.->dp,
                  paddingBottom: viewPortContants.bottomInset->dp,
                })}
                showsHorizontalScrollIndicator=false
                keyExtractor={(_, i) => i->Int.toString}
                horizontal=false
                renderItem={({item, index}) =>
                  <CustomPressable
                    key={index->Int.toString}
                    style={s({height: 32.->dp, margin: 1.->dp, flexDirection: #row, gap: 6.->dp})}
                    onPress={_ => {
                      setValue(_ => Some(item.value))
                      setIsModalVisible(_ => false)
                    }}
                  >
                    {isCountryStateFields
                      ? <TextWrapper
                          text={item.icon->Option.getOr("") ++ item.label} textType=ModalText
                        />
                      : <>
                          {switch item.icon {
                          | Some(name) => <Icon name />
                          | None => React.null
                          }}
                          <TextWrapper text=item.label textType=ModalText />
                        </>}
                  </CustomPressable>}
              />}
        </View>
      </View>
    </Modal>
    {isLoading
      ? <View
          style={s({
            overflow: #hidden,
            position: #absolute,
            opacity: 0.6,
            width: 100.->pct,
            height: 100.->pct,
          })}
        >
          <CustomLoader />
        </View>
      : React.null}
  </View>
}
