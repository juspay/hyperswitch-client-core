open ReactNative
open Style
open ThemebasedStyle

module DetailsView = {
  @react.component
  let make = (~title, ~value) => {
    <View style={s({flexDirection: #row, gap: 5.->dp, alignItems: #center})}>
      <Text
        style={s({
          fontSize: 10.,
          fontWeight: #400,
          color: useThemeBasedStyle().detailsViewTextKeyColor,
        })}>
        {React.string(title ++ ":")}
      </Text>
      <Text
        style={s({
          fontSize: 12.,
          fontWeight: #400,
          color: useThemeBasedStyle().detailsViewTextValueColor,
        })}>
        {React.string(value)}
      </Text>
    </View>
  }
}

@react.component
let make = (~data: PaymentConfirmTypes.ach_credit_transfer) => {
  let (clicked, setClicked) = React.useState(_ => false)
  let handleSuccessFailure = AllPaymentHooks.useHandleSuccessFailure()
  let localeObject = GetLocale.useGetLocalObj()
  <View>
    <View style={s({flexDirection: #row, gap: 8.->dp, alignItems: #center})}>
      <Icon name={"ach bank transfer"} height=20. width=20. />
      <TextWrapper
        textType={HeadingBold}
        text=localeObject.achBankTransferText
        overrideStyle=Some(Style.s({fontSize: 16.0, fontWeight: #600}))
      />
    </View>
    <Space height=20.0 />
    <View style={s({flexDirection: #row, gap: 4.->dp, alignItems: #center})}>
      <Icon name={"bank"} height=20. width=20. />
      <TextWrapper
        textType={HeadingBold}
        text=localeObject.accountDetailsText
        overrideStyle=Some(Style.s({fontSize: 14.0, fontWeight: #600}))
      />
    </View>
    <Space height=6.0 />
    <TextWrapper
      textType={CardText}
      text=localeObject.instructionalTextOfAchTransfer
      overrideStyle=Some(
        Style.s({
          fontSize: 12.0,
          fontWeight: #400,
          color: useThemeBasedStyle().instructionalTextColor,
        }),
      )
    />
    <Space height=12.0 />
    <View
      style={s({
        paddingVertical: 16.->dp,
        paddingHorizontal: 14.->dp,
        borderRadius: 8.,
        borderWidth: 0.5,
        borderColor: useThemeBasedStyle().silverBorderColor,
        gap: 12.->dp,
      })}>
      <DetailsView title=localeObject.accountNumberText value={data.account_number} />
      <DetailsView title=localeObject.bankName value={data.bank_name} />
      <DetailsView title=localeObject.formFieldACHRoutingNumberLabel value={data.routing_number} />
      <DetailsView title=localeObject.swiftCode value={data.swift_code} />
    </View>
    <Space height=18.0 />
    <View
      style={s({
        flexDirection: #row,
        gap: 4.->dp,
        paddingVertical: 10.->dp,
        paddingHorizontal: 12.->dp,
        borderRadius: 8.,
        backgroundColor: useThemeBasedStyle().disclaimerBackgroundColor,
      })}>
      <Icon name={"disclaimer"} height=20. width=20. />
      <Text
        style={s({
          fontSize: 12.,
          fontWeight: #400,
          lineHeight: 18.,
          color: useThemeBasedStyle().disclaimerTextColor,
        })}>
        {React.string(localeObject.disclaimerTextAchTransfer)}
      </Text>
    </View>
    <Space height=28.0 />
    <CustomButton
      text={clicked ? localeObject.doneText : localeObject.copyToClipboard}
      borderRadius=4.
      onPress={_ => {
        if clicked {
          handleSuccessFailure(
            ~apiResStatus=PaymentConfirmTypes.defaultSuccess,
            ~closeSDK=true,
            ~reset=false,
            (),
          )
        } else {
          setClicked(_ => true)
          let textToCopy =
            localeObject.accountNumberText ++
            " : " ++
            data.account_number ++
            "\n" ++
            localeObject.bankName ++
            " : " ++
            data.bank_name ++
            "\n" ++
            localeObject.bankName ++
            " : " ++
            data.routing_number ++
            "\n" ++
            localeObject.swiftCode ++
            " : " ++
            data.swift_code
          // let copyToClipboard = () => {
          //  Clipboard.setString(textToCopy)
          RNClipboard.setString(textToCopy)
          // }
        }
      }}
    />
    <Space height=14.0 />
    <View
      style={s({flexDirection: #row, alignItems: #center, justifyContent: #center, gap: 4.->dp})}>
      <TextWrapper
        textType={Heading}
        overrideStyle={Some(
          s({
            fontSize: 10.,
            fontWeight: #400,
            lineHeight: 12.,
            color: useThemeBasedStyle().poweredByTextColor,
          }),
        )}>
        {localeObject.poweredBy->React.string}
      </TextWrapper>
    </View>
    <CustomPressable onPress={_ => ()} />
    <Space height=8.0 />
  </View>
}
