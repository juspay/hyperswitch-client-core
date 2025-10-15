open ReactNative
open ReactNative.Style

@react.component
let make = (
  ~maskedEmail: option<string>=?,
  ~maskedPhone: option<string>=?,
  ~otp: array<string>,
  ~otpRefs: array<option<React.ref<Nullable.t<ReactNative.TextInput.element>>>>,
  ~handleOtpChange: (int, string) => unit,
  ~handleKeyPress: (int, ReactNative.TextInput.KeyPressEvent.t) => unit,
  ~onSubmit: unit => unit,
  ~onNotYouPress: unit => unit,
  ~resendOtp: unit => promise<unit>,
  ~resendTimer: int,
  ~resendLoading: bool,
  ~rememberMe: bool,
  ~setRememberMe: (bool => bool) => unit,
  ~otpError: string="NONE",
  ~disabled: bool=false,
  ~cardBrands: array<string>=[],
) => {
  let {borderRadius, component, primaryColor, dangerColor} = ThemebasedStyle.useThemeBasedStyle()
  let (showTooltip, setShowTooltip) = React.useState(() => false)

  let supportedCardBrands = cardBrands->Array.filter(brand => {
    switch brand {
    | "AmericanExpress" | "DinersClub" | "Visa" | "Mastercard" => true
    | _ => false
    }
  })

  let getIconName = brand => {
    switch brand {
    | "AmericanExpress" => "americanexpress"
    | "DinersClub" => "discoverc2p"
    | "Visa" => "visac2p"
    | "Mastercard" => "mastercardc2p"
    | _ => ""
    }
  }

  <View style={s({marginVertical: 12.->dp})}>
    <View
      style={s({
        flexDirection: #row,
        alignItems: #center,
        marginBottom: 16.->dp,
      })}>
      <Icon name="src" height=24. width=18. />
      {supportedCardBrands
      ->Array.map(brand => {
        let iconName = getIconName(brand)
        <Icon key={brand} name={iconName} height=18. style={s({marginLeft: 6.->dp})} />
      })
      ->React.array}
    </View>
    <View style={s({alignItems: #"flex-start", marginBottom: 16.->dp})}>
      <TouchableOpacity onPress={_ => onNotYouPress()}>
        <Text style={s({fontSize: 14., color: "#007AFF"})}> {"Not you?"->React.string} </Text>
      </TouchableOpacity>
    </View>
    <Text style={s({fontSize: 20., marginBottom: 12.->dp, fontWeight: #800, color: "#000000"})}>
      {"Click to Pay has found your linked cards"->React.string}
    </Text>
    <Text style={s({fontSize: 14., marginBottom: 12.->dp, fontWeight: #600})}>
      {switch (maskedEmail, maskedPhone) {
      | (Some(email), Some(phone)) => `Enter the code sent to ${email}, ${phone}`->React.string
      | (Some(email), None) => `Enter the code sent to ${email}`->React.string
      | (None, Some(phone)) => `Enter the code sent to ${phone}`->React.string
      | (None, None) => "Enter verification code"->React.string
      }}
    </Text>
    <View
      style={s({
        flexDirection: #row,
        justifyContent: #"space-between",
        marginBottom: 16.->dp,
      })}>
      {[0, 1, 2, 3, 4, 5]
      ->Array.mapWithIndex((index, _) =>
        <TextInput
          key={index->Int.toString}
          ref={switch otpRefs[index] {
          | Some(Some(ref)) => ref->ReactNative.Ref.value
          | _ => ReactNative.Ref.value(React.useRef(Nullable.null))
          }}
          style={s({
            width: 45.->dp,
            height: 50.->dp,
            borderWidth: 2.,
            borderColor: otpError !== "NONE"
              ? dangerColor
              : otp[index]->Option.getOr("") !== ""
              ? primaryColor
              : component.borderColor,
            borderRadius,
            textAlign: #center,
            fontSize: 20.,
            fontWeight: #600,
            backgroundColor: component.background,
            color: component.color,
          })}
          value={otp[index]->Option.getOr("")}
          onChangeText={value => handleOtpChange(index, value)}
          onKeyPress={event => handleKeyPress(index, event)}
          keyboardType=#numeric
          autoFocus={index === 0}
          selectTextOnFocus=true
          editable={!disabled}
        />
      )
      ->React.array}
    </View>
    {otpError !== "NONE"
      ? <View style={s({marginBottom: 16.->dp})}>
          <Text
            style={s({
              color: dangerColor,
              fontSize: 14.,
              textAlign: #center,
              fontWeight: #500,
            })}>
            {switch otpError {
            | "VALIDATION_DATA_INVALID" => "Invalid OTP code. Please try again."
            | "OTP_SEND_FAILED" => "Failed to send OTP. Please try again."
            | "ACCT_INACCESSIBLE" => "Account temporarily locked. Too many attempts. Please try again later."
            | _ => "An error occurred. Please try again."
            }->React.string}
          </Text>
        </View>
      : React.null}
    <TouchableOpacity
      onPress={_ => resendOtp()->ignore}
      disabled={resendTimer > 0 || resendLoading}
      style={s({marginBottom: 16.->dp, alignItems: #center})}>
      <Text
        style={s({
          fontSize: 14.,
          color: resendTimer > 0 || resendLoading ? "#CCC" : "#007AFF",
          fontWeight: #500,
        })}>
        {(
          resendTimer > 0
            ? `Resend code in ${resendTimer->Int.toString}s`
            : resendLoading
            ? "Sending..."
            : "Resend code"
        )->React.string}
      </Text>
    </TouchableOpacity>
    <TouchableOpacity
      onPress={_ => setRememberMe(prev => !prev)}
      style={s({
        flexDirection: #row,
        alignItems: #center,
        marginBottom: 16.->dp,
      })}>
      <View
        style={s({
          width: 20.->dp,
          height: 20.->dp,
          borderWidth: 2.,
          borderColor: rememberMe ? "#007AFF" : "#CCC",
          borderRadius: 3.,
          marginRight: 8.->dp,
          justifyContent: #center,
          alignItems: #center,
          backgroundColor: rememberMe ? "#007AFF" : "transparent",
        })}>
        {rememberMe
          ? <Text style={s({color: "#FFFFFF", fontSize: 14., fontWeight: #bold})}>
              {"\u2713"->React.string}
            </Text>
          : React.null}
      </View>
      <Text style={s({fontSize: 12., color: "#666", marginRight: 6.->dp})}>
        {"Remember me on this browser"->React.string}
      </Text>
      <TouchableOpacity onPress={_ => setShowTooltip(_ => true)}>
        <Icon name="tooltip" height=12. width=12. />
      </TouchableOpacity>
    </TouchableOpacity>
    {showTooltip
      ? <View
          style={s({
            backgroundColor: "#F5F5F5",
            borderRadius: 8.,
            padding: 16.->dp,
            marginBottom: 16.->dp,
            position: #relative,
          })}>
          <View
            style={s({
              position: #absolute,
              top: -8.->dp,
              right: 20.->dp,
              width: 0.->dp,
              height: 0.->dp,
              backgroundColor: "transparent",
              borderStyle: #solid,
              borderLeftWidth: 8.,
              borderRightWidth: 8.,
              borderBottomWidth: 8.,
              borderLeftColor: "transparent",
              borderRightColor: "transparent",
              borderBottomColor: "#F5F5F5",
            })}
          />
          <TouchableOpacity
            onPress={_ => setShowTooltip(_ => false)}
            style={s({
              position: #absolute,
              top: 8.->dp,
              right: 8.->dp,
              padding: 4.->dp,
            })}>
            <Icon name="close" height=16. width=16. />
          </TouchableOpacity>
          <Text style={s({fontSize: 14., color: "#000000", marginBottom: 12.->dp, lineHeight: 20., paddingRight: 24.->dp})}>
            {"If you're remembered, you won't need to enter a code next time to securely access your saved cards."->React.string}
          </Text>
          <Text style={s({fontSize: 14., color: "#000000", lineHeight: 20.})}>
            {"Not recommended for public or shared devices because this uses cookies."->React.string}
          </Text>
        </View>
      : React.null}
    <TouchableOpacity
      onPress={_ => onSubmit()}
      disabled={otp->Array.some(d => d === "") || disabled}
      style={s({
        backgroundColor: otp->Array.some(d => d === "") || disabled ? "#CCC" : "#007AFF",
        padding: 14.->dp,
        borderRadius,
        alignItems: #center,
      })}>
      <Text style={s({color: "#FFFFFF", fontSize: 16., fontWeight: #600})}>
        {"Continue"->React.string}
      </Text>
    </TouchableOpacity>
  </View>
}
