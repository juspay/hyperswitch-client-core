open ReactNative
open Style

@react.component
let make = () => {
  let (_, setPmManagementScreenType) = React.useContext(
    PMManagementContext.pmManagementScreenTypeContext,
  )
  let (_, setCardData) = React.useContext(CardDataContext.cardDataContext)
  let {borderRadius} = ThemebasedStyle.useThemeBasedStyle()
  let addPaymentMethod = AllPaymentHooks.useSavePaymentMethod()
  let errorOnApiCalls = ErrorHooks.useShowErrorOrWarning()

  React.useEffect(() => {
    let eventEmitter = NativeEventEmitter.make(
      Dict.get(ReactNative.NativeModules.nativeModules, "HyperModule"),
    )
    let event = NativeEventEmitter.addListener(eventEmitter, "onBackButtonPressed", _ => {
      setPmManagementScreenType(LIST_SCREEN)
    })
    Some(_ => event->EventSubscription.remove)
  }, [])

  let onSubmitHandler = _ => {
    addPaymentMethod()->Promise.then(response => {
      if ErrorUtils.isError(response) {
        errorOnApiCalls(
          USED_CL((Error, Static(ErrorUtils.getErrorMessage(response)))),
          (),
        )
      } else {
        setCardData(_ => CardDataContext.dafaultVal)
        setPmManagementScreenType(LIST_SCREEN)
      }
      Promise.resolve()
    })->ignore
  }

  <View
    style={viewStyle(
      ~padding=16.->dp,
      ~width=100.->pct,
      ~flex=1.,
      ~justifyContent=#"space-between",
      (),
    )}>
    <View>
      <TextWrapper text={"Card Details"} textType={ModalText} />
      <Space height=8. />
      <CardElement setIsAllValid={_ => ()} reset=false />
    </View>
    <CustomButton borderRadius text={"Submit"} onPress=onSubmitHandler />
  </View>
}