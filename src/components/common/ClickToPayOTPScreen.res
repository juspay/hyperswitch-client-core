open ReactNative
open ReactNative.Style

@react.component
let make = (
  ~maskedChannel: option<string>,
  ~maskedEmail: option<string>=?,
  ~otp: array<string>,
  ~otpRefs: array<option<React.ref<Nullable.t<ReactNative.TextInput.element>>>>,
  ~handleOtpChange: (int, string) => unit,
  ~onSubmit: unit => unit,
  ~resendOtp: unit => promise<unit>,
  ~resendTimer: int,
  ~resendLoading: bool,
  ~rememberMe: bool,
  ~setRememberMe: (bool => bool) => unit,
  ~otpError: string="NONE",
  ~disabled: bool=false,
) => {
  let {borderRadius, component, primaryColor} = ThemebasedStyle.useThemeBasedStyle()

  <View style={s({flex: 1.})}>
    <View>
      <Text
        style={s({
          fontSize: 35.,
          fontWeight: #700,
          color: component.color,
          marginBottom: 12.->dp,
        })}>
        {"Enter the code to see your cards"->React.string}
      </Text>
      <Text
        style={s({
          fontSize: 20.,
          color: "#666",
          marginBottom: 24.->dp,
        })}>
        {`We sent a code to ${maskedChannel->Option.getOr("")} & ${maskedEmail->Option.getOr(
            "",
          )} to confirm it's you.`->React.string}
      </Text>
    </View>
    <View style={s({flex: 1.})}>
      <View
        style={s({
          flexDirection: #row,
          justifyContent: #"space-between",
          marginBottom: 24.->dp,
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
                ? "#DC3545"
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
                color: "#DC3545",
                fontSize: 14.,
                textAlign: #center,
                fontWeight: #500,
              })}>
              {(
                switch otpError {
                | "VALIDATION_DATA_INVALID" => "Invalid OTP code. Please try again."
                | "ACCT_INACCESSIBLE" =>
                  "Account temporarily locked. Too many attempts. Please try again later."
                | _ => "An error occurred. Please try again."
                }
              )->React.string}
            </Text>
          </View>
        : React.null}
      <TouchableOpacity
        onPress={_ => setRememberMe(prev => !prev)}
        style={s({
          flexDirection: #row,
          alignItems: #center,
          marginBottom: 16.->dp,
        })}>
        <View
          style={s({
            width: 18.->dp,
            height: 18.->dp,
            borderWidth: 2.,
            borderColor: rememberMe ? "#007AFF" : "#CCC",
            borderRadius: 3.,
            marginRight: 8.->dp,
            justifyContent: #center,
            alignItems: #center,
            backgroundColor: rememberMe ? "#007AFF" : "transparent",
          })}>
          {rememberMe
            ? <Text style={s({color: "#FFFFFF", fontSize: 12., fontWeight: #bold})}>
                {"\u2713"->React.string}
              </Text>
            : React.null}
        </View>
        <Text style={s({fontSize: 14., color: "#666", marginRight: 4.->dp})}>
          {"Skip verification next time"->React.string}
        </Text>
        <Text style={s({fontSize: 14., color: "#999"})}> {"\u24D8"->React.string} </Text>
      </TouchableOpacity>
      <TouchableOpacity
        onPress={_ => resendOtp()->ignore}
        disabled={resendTimer > 0 || resendLoading}
        style={s({
          backgroundColor: resendTimer > 0 || resendLoading ? "transparent" : "#E8F4FF",
          paddingVertical: 10.->dp,
          paddingHorizontal: 16.->dp,
          borderRadius: 8.,
          alignSelf: #"flex-start",
        })}>
        <Text
          style={s({
            fontSize: 14.,
            color: resendTimer > 0 || resendLoading ? "#CCC" : "#007AFF",
            fontWeight: #600,
          })}>
          {(
            resendTimer > 0
              ? `Resend code in ${resendTimer->Int.toString}s`
              : resendLoading
              ? "Sending..."
              : "I didn't get a code"
          )->React.string}
        </Text>
      </TouchableOpacity>
    </View>
    <View
      style={s({
        paddingVertical: 16.->dp,
        backgroundColor: component.background,
      })}>
      <TouchableOpacity
        onPress={_ => onSubmit()}
        disabled={otp->Array.some(d => d === "") || disabled}
        style={s({
          backgroundColor: otp->Array.some(d => d === "") || disabled ? "#CCC" : "#007AFF",
          paddingVertical: 16.->dp,
          borderRadius: 12.,
          alignItems: #center,
        })}>
        <Text style={s({color: "#FFFFFF", fontSize: 16., fontWeight: #600})}>
          {"Continue"->React.string}
        </Text>
      </TouchableOpacity>
    </View>
  </View>
}
