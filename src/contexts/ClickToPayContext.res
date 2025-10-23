@react.component
let make = (~children) => {
  let (clickToPayCookies, setClickToPayCookies) = React.useState(_ => None)

  let handleCookiesExtracted = React.useCallback1(cookies => {
    setClickToPayCookies(_ => Some(cookies))
  }, [setClickToPayCookies])

  <ClickToPay.Provider
    onCookiesExtracted=Some(handleCookiesExtracted) initialCookies=clickToPayCookies>
    children
  </ClickToPay.Provider>
}
