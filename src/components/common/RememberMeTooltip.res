open ReactNative
open ReactNative.Style

@react.component
let make = () => {
  let {borderRadius, component} = ThemebasedStyle.useThemeBasedStyle()
  let (showTooltip, setShowTooltip) = React.useState(() => false)

  <>
    <TouchableOpacity onPress={_ => setShowTooltip(_ => true)}>
      <Icon name="tooltip" height=12. width=12. />
    </TouchableOpacity>
    <Modal
      visible=showTooltip
      transparent=true
      animationType=#fade
      onRequestClose={_ => setShowTooltip(_ => false)}>
      <TouchableOpacity
        activeOpacity=1.
        onPress={_ => setShowTooltip(_ => false)}
        style={s({
          flex: 1.,
          backgroundColor: "rgba(0, 0, 0, 0.5)",
          justifyContent: #center,
          alignItems: #center,
          padding: 20.->dp,
        })}>
        <TouchableOpacity
          activeOpacity=1.
          onPress={_ => ()}
          style={s({
            backgroundColor: component.background,
            borderRadius,
            padding: 16.->dp,
            maxWidth: 320.->dp,
            width: 100.->pct,
          })}>
          <View
            style={s({
              flexDirection: #row,
              justifyContent: #"space-between",
              marginBottom: 12.->dp,
            })}>
            <Text style={s({fontSize: 16., fontWeight: #600, color: component.color})}>
              {"Remember Me"->React.string}
            </Text>
            <TouchableOpacity onPress={_ => setShowTooltip(_ => false)}>
              <Icon name="close" height=20. width=20. />
            </TouchableOpacity>
          </View>
          <Text
            style={s({
              fontSize: 14.,
              color: component.color,
              marginBottom: 12.->dp,
              lineHeight: 20.,
            })}>
            {"If you're remembered, you won't need to enter a code next time to securely access your saved cards."->React.string}
          </Text>
          <Text style={s({fontSize: 14., color: component.color, lineHeight: 20.})}>
            {"Not recommended for public or shared devices because this uses cookies."->React.string}
          </Text>
        </TouchableOpacity>
      </TouchableOpacity>
    </Modal>
  </>
}
