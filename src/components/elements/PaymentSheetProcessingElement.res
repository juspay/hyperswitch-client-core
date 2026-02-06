open ReactNative
open Style

@react.component
let make = () => {
  let {component} = ThemebasedStyle.useThemeBasedStyle()

  let (paymentProcessingText, setPaymentProcessingText) = React.useState(_ => ".")

  React.useEffect1(() => {
    let intervalId = setTimeout(() => {
      let newState = switch paymentProcessingText {
      | "." => ".."
      | ".." => "..."
      | "..." => "."
      | _ => ""
      }
      setPaymentProcessingText(_ => newState)
    }, 800)

    Some(() => clearTimeout(intervalId))
  }, [paymentProcessingText])

  <View
    style={array([
      s({
        alignItems: #center,
        backgroundColor: component.background,
        justifyContent: #center,
        height: 100.->pct,
        width: 100.->pct,
      }),
    ])}
  >
    <TubeSpinner size=60. />
    <Space />
    <View style={s({display: #flex, flexDirection: #row})}>
      <TextWrapper text={"Processing Your Payment"} textType={HeadingBold} />
      <View style={s({marginLeft: 2.->dp, width: 20.->dp})}>
        <TextWrapper text={paymentProcessingText} textType={HeadingBold} />
      </View>
    </View>
    <Space height=15. />
    <TextWrapper text="Please do not press back or close this screen" textType={ModalText} />
  </View>
}
