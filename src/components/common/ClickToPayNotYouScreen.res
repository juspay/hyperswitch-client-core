open ReactNative
open ReactNative.Style

@react.component
let make = (
  ~newIdentifier: string,
  ~setNewIdentifier: (string => string) => unit,
  ~onBack: unit => unit,
  ~onSwitch: string => unit,
  ~cardBrands: array<string>=[],
  ~disabled: bool=false,
) => {
  let {borderRadius, component} = ThemebasedStyle.useThemeBasedStyle()

  <View style={s({marginVertical: 12.->dp})}>
    <View style={s({alignItems: #"flex-start", marginBottom: 16.->dp})}>
      <Icon name="visa" height=24. width=32. />
    </View>
    <TouchableOpacity onPress={_ => onBack()} style={s({marginBottom: 16.->dp})}>
      <Text style={s({fontSize: 14., color: "#007AFF"})}> {"← Back"->React.string} </Text>
    </TouchableOpacity>
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
      onChangeText={value => setNewIdentifier(_ => value)}
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
      disabled={newIdentifier === "" || disabled}
      style={s({
        backgroundColor: newIdentifier === "" || disabled ? "#CCC" : "#007AFF",
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
