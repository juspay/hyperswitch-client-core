open ReactNative
open ReactNative.Style

@react.component
let make = (
  ~maskedChannel: option<string>,
  ~otp: array<string>,
  ~otpRefs: array<option<React.ref<Nullable.t<ReactNative.TextInput.element>>>>,
  ~handleOtpChange: (int, string) => unit,
  ~onSubmit: unit => unit,
  ~onNotYouPress: unit => unit,
  ~resendOtp: unit => promise<unit>,
  ~resendTimer: int,
  ~resendLoading: bool,
  ~rememberMe: bool,
  ~setRememberMe: (bool => bool) => unit,
  ~otpError: string="NONE",
  ~disabled: bool=false,
) => {
  let {borderRadius, component, primaryColor, dangerColor} = ThemebasedStyle.useThemeBasedStyle()

  <View style={s({marginVertical: 12.->dp})}>
    {switch maskedChannel {
    | Some(channel) =>
      <View style={s({alignItems: #"flex-start", marginBottom: 16.->dp})}>
        <View style={s({flexDirection: #row, alignItems: #center})}>
          <Text style={s({fontSize: 14., color: "#666", marginRight: 8.->dp})}>
            {channel->React.string}
          </Text>
          <TouchableOpacity onPress={_ => onNotYouPress()}>
            <Text style={s({fontSize: 14., color: "#007AFF"})}> {"Not you?"->React.string} </Text>
          </TouchableOpacity>
        </View>
      </View>
    | None => React.null
    }}
    <Text style={s({fontSize: 14., marginBottom: 12.->dp, fontWeight: #600})}>
      {"Enter verification code"->React.string}
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
          keyboardType=#numeric
          maxLength=1
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
      <Text style={s({fontSize: 12., color: "#666"})}>
        {"Remember me on this browser"->React.string}
      </Text>
    </TouchableOpacity>
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
