@react.component
let make = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)

  switch nativeProp.sdkState {
  | PaymentMethodsManagement => <PMMangementNavigatorRouter />
  | Authentication => <AuthenticationRouter />
  | _ => <NavigatorRouter />
  }
}
