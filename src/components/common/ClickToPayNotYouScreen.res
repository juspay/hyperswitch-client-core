open ReactNative
open ReactNative.Style
open EmailValidation

@react.component
let make = (
  ~onBack: unit => unit,
  ~onSwitch: string => unit,
  ~cardBrands: array<string>=[],
  ~disabled: bool=false,
  ~showBackButton: bool=true,
) => {
  let {borderRadius, component} = ThemebasedStyle.useThemeBasedStyle()

  let (newIdentifier, setNewIdentifier) = React.useState(() => "")
  let (emailValidationState, setEmailValidationState) = React.useState(() => None)

  let supportedCardBrands = Utils.supportedCardBrands(cardBrands)

  <View style={s({marginVertical: 12.->dp})}>
    <View
      style={s({
        flexDirection: #row,
        alignItems: #center,
        marginBottom: 16.->dp,
      })}>
      <Icon name="src" height=18. width=18. />
      {supportedCardBrands
      ->Array.map(brand => {
        let iconName = Utils.getIconName(brand)
        <Icon key={brand} name={iconName} height=18. style={s({marginLeft: 6.->dp})} />
      })
      ->React.array}
    </View>
    {showBackButton
      ? <TouchableOpacity onPress={_ => onBack()} style={s({marginBottom: 16.->dp})}>
          <Text style={s({fontSize: 14., color: "#007AFF"})}> {"← Back"->React.string} </Text>
        </TouchableOpacity>
      : React.null}
    <Text
      style={s({
        fontSize: 14.,
        color: "#666",
        marginBottom: 16.->dp,
      })}>
      {"Enter a new email or mobile number to access a different set of linked cards."->React.string}
    </Text>
    <TextInput
      value=newIdentifier
      onChangeText={value => {
        setNewIdentifier(_ => value)
        setEmailValidationState(_ => isEmailValid(value))
      }}
      placeholder="Enter email"
      keyboardType=#"email-address"
      autoCapitalize=#none
      editable={!disabled}
      style={s({
        borderWidth: 1.,
        borderColor: component.borderColor,
        borderRadius,
        padding: 12.->dp,
        fontSize: 14.,
        marginBottom: 16.->dp,
        backgroundColor: component.background,
        color: component.color,
      })}
    />
    <TouchableOpacity
      onPress={_ => {
        onSwitch(newIdentifier)
      }}
      disabled={emailValidationState != Some(true) || disabled}
      style={s({
        backgroundColor: emailValidationState == Some(true) && !disabled ? "#007AFF" : "#CCC",
        padding: 14.->dp,
        borderRadius,
        alignItems: #center,
      })}>
      <Text style={s({color: "#FFFFFF", fontSize: 16., fontWeight: #600})}>
        {"Switch ID"->React.string}
      </Text>
    </TouchableOpacity>
  </View>
}
