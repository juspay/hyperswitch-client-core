type bannerType = [#error | #warning | #info | #success | #none]

type bannerState = {
  isVisible: bool,
  message: string,
  bannerType: bannerType,
}

let initialState = {
  isVisible: false,
  message: "",
  bannerType: #none,
}

let defaultSetter = (_: bannerState) => ()
let bannerContext = React.createContext((initialState, defaultSetter))

module Provider = {
  let make = React.Context.provider(bannerContext)
}

@react.component
let make = (~children) => {
  let (state, setState) = React.useState(_ => initialState)
  let setState = React.useCallback1(state => setState(_ => state), [setState])

  <Provider value=(state, setState)> children </Provider>
}

let useBanner = () => {
  let (state, setState) = React.useContext(bannerContext)

  let showBanner = (~message, ~bannerType=#info) => {
    setState({isVisible: true, message, bannerType})
  }

  let hideBanner = () => {
    setState({...state, isVisible: false})
  }

  (state, showBanner, hideBanner)
}
