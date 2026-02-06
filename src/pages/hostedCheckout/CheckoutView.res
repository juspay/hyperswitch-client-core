open ReactNative
open Style

module LineItem = {
  @react.component
  let make = (~label, ~value, ~sublabel=?, ~subvalue=?) => {
    let {textSecondary} = ThemebasedStyle.useThemeBasedStyle()

    <>
      <View style={s({flexDirection: #row, justifyContent: #"space-between", alignItems: #center})}>
        <TextWrapper text={label} textType={ModalTextBold} />
        <TextWrapper text={value} textType={ModalTextBold} />
      </View>
      {switch (sublabel, subvalue) {
      | (Some(sublabel), Some(subvalue)) =>
        <View
          style={s({
            flexDirection: #row,
            justifyContent: #"space-between",
            alignItems: #center,
            marginTop: 4.->dp,
          })}
        >
          <TextWrapper text={sublabel} textType={ModalText} overrideStyle={Some(textSecondary)} />
          <TextWrapper text={subvalue} textType={ModalText} overrideStyle={Some(textSecondary)} />
        </View>
      | (Some(sublabel), None) =>
        <View style={s({marginTop: 4.->dp})}>
          <TextWrapper text={sublabel} textType={ModalText} overrideStyle={Some(textSecondary)} />
        </View>
      | _ => React.null
      }}
    </>
  }
}

module Divider = {
  @react.component
  let make = () => {
    <View
      style={s({
        height: 1.->dp,
        backgroundColor: "#E5E5E5",
        marginVertical: 16.->dp,
      })}
    />
  }
}

module CheckoutDetails = {
  @react.component
  let make = (
    ~accountPaymentMethodData: option<AccountPaymentMethodType.accountPaymentMethods>,
    ~textSecondary,
  ) => {
    <>
      <Space height={40.} />
      {switch accountPaymentMethodData {
      | Some(data) =>
        <LineItem
          label={`${data.merchant_name->String.toUpperCase} Subscription`}
          value="$399.00"
          sublabel="Billed monthly"
          subvalue="$399.00 per seat"
        />
      | None => React.null
      }}
      <Divider />
      <View style={s({flexDirection: #row, justifyContent: #"space-between", alignItems: #center})}>
        <TextWrapper text="Subtotal" textType={ModalTextBold} />
        <TextWrapper text="$399.00" textType={ModalTextBold} />
      </View>
      <Space height={16.} />
      <View style={s({flexDirection: #row, justifyContent: #"space-between", alignItems: #center})}>
        <View style={s({flexDirection: #row, alignItems: #center, gap: 6.->dp})}>
          <TextWrapper text="Tax" textType={ModalTextBold} />
          <Icon name="disclaimer" fill="#9CA3AF" width=16. height=16. />
        </View>
        <TextWrapper
          text="Enter address to calculate" textType={ModalText} overrideStyle={Some(textSecondary)}
        />
      </View>
      <Divider />
      <View style={s({flexDirection: #row, justifyContent: #"space-between", alignItems: #center})}>
        <TextWrapper
          text="Total due today"
          textType={ModalTextBold}
          overrideStyle={Some(s({fontSize: 16., fontWeight: #600}))}
        />
        <TextWrapper
          text="$399.00"
          textType={ModalTextBold}
          overrideStyle={Some(s({fontSize: 16., fontWeight: #600}))}
        />
      </View>
    </>
  }
}

@react.component
let make = (~isDesktop) => {
  let (accountPaymentMethodData, _, _) = React.useContext(AllApiDataContextNew.allApiDataContext)
  let {textSecondary} = ThemebasedStyle.useThemeBasedStyle()

  let (showDetails, setShowDetails) = React.useState(() => false)
  let shadowStyle = ShadowHook.useGetShadowStyle(
    ~shadowIntensity=100.,
    ~shadowColor="#00000050",
    (),
  )

  <>
    <FloatingBanner
      message=""
      bannerType=#info
      isVisible=showDetails
      isConnected=false
      autoDismiss=false
      onDismiss={_ => setShowDetails(v => !v)}
    >
      <View
        style={array([
          s({
            width: 100.->pct,
            backgroundColor: "#FFFFFF",
            padding: 20.->dp,
            borderBottomLeftRadius: 20.,
            borderBottomRightRadius: 20.,
            zIndex: 999,
          }),
          shadowStyle,
        ])}
      >
        {switch accountPaymentMethodData {
        | Some(data) =>
          <View
            style={s({
              flexDirection: #row,
              alignItems: #center,
              justifyContent: isDesktop ? #center : #"space-between",
              gap: (isDesktop ? 12. : 6.)->dp,
            })}
          >
            <View
              style={s({
                flexDirection: #row,
                alignItems: #center,
                gap: (isDesktop ? 12. : 6.)->dp,
              })}
            >
              <Icon
                name="back"
                fill="#9CA3AF"
                width={isDesktop ? 24. : 18.}
                height={isDesktop ? 24. : 18.}
              />
              <TextWrapper
                text={data.merchant_name->String.toUpperCase}
                textType={HeadingBold}
                overrideStyle={Some(s({fontSize: isDesktop ? 32. : 24., fontWeight: #700}))}
              />
            </View>
            {isDesktop
              ? React.null
              : <CustomPressable onPress={_ => setShowDetails(v => !v)}>
                  <TextWrapper
                    text={"Close ^"}
                    textType={Heading}
                    overrideStyle={Some(s({fontSize: 14., fontWeight: #600}))}
                  />
                </CustomPressable>}
          </View>
        | None => React.null
        }}
        <CheckoutDetails accountPaymentMethodData textSecondary />
        <Space />
      </View>
    </FloatingBanner>
    <View
      style={s({
        flex: 1.,
        backgroundColor: "#FFFFFF",
        paddingHorizontal: 20.->dp,
      })}
    >
      <Space height={isDesktop ? 40. : 20.} />
      {switch accountPaymentMethodData {
      | Some(data) =>
        <View
          style={s({
            flexDirection: #row,
            alignItems: #center,
            justifyContent: isDesktop ? #center : #"space-between",
            gap: (isDesktop ? 12. : 6.)->dp,
          })}
        >
          <View
            style={s({
              flexDirection: #row,
              alignItems: #center,
              gap: (isDesktop ? 12. : 6.)->dp,
            })}
          >
            <Icon
              name="back"
              fill="#9CA3AF"
              width={isDesktop ? 24. : 18.}
              height={isDesktop ? 24. : 18.}
            />
            <TextWrapper
              text={data.merchant_name->String.toUpperCase}
              textType={HeadingBold}
              overrideStyle={Some(s({fontSize: isDesktop ? 32. : 24., fontWeight: #700}))}
            />
          </View>
          {isDesktop
            ? React.null
            : <CustomPressable onPress={_ => setShowDetails(v => !v)}>
                <TextWrapper
                  text={"Details v"}
                  textType={Heading}
                  overrideStyle={Some(s({fontSize: 14., fontWeight: #600}))}
                />
              </CustomPressable>}
        </View>
      | None => React.null
      }}
      <View style=?{isDesktop ? None : Some(s({alignItems: #center}))}>
        <Space height={40.} />
        {switch accountPaymentMethodData {
        | Some(data) =>
          <TextWrapper
            text={`Subscribe to ${data.merchant_name} Subscription`}
            textType={Subheading}
            overrideStyle={Some(textSecondary)}
          />
        | None => React.null
        }}
        <Space height={12.} />
        <View style={s({flexDirection: #row, alignItems: #"flex-end", gap: 8.->dp})}>
          <TextWrapper
            text="$399.00"
            textType={HeadingBold}
            overrideStyle={Some(s({fontSize: 48., fontWeight: #700, lineHeight: 56.}))}
          />
          <View style={s({paddingBottom: 8.->dp})}>
            <TextWrapper
              text="per"
              textType={ModalText}
              overrideStyle={Some(array([textSecondary, s({fontSize: 16.})]))}
            />
            <TextWrapper
              text="month"
              textType={ModalText}
              overrideStyle={Some(array([textSecondary, s({fontSize: 16.})]))}
            />
          </View>
        </View>
      </View>
      {isDesktop ? <CheckoutDetails accountPaymentMethodData textSecondary /> : React.null}
    </View>
  </>
}
