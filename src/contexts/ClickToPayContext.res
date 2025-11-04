@react.component
let make = (~children) => {
  let (clickToPayCookies, setClickToPayCookies) = React.useState(_ => None)

  let handleCookiesExtracted = React.useCallback1(cookies => {
    setClickToPayCookies(_ => Some(cookies))
  }, [setClickToPayCookies])

  <ClickToPay.Provider
    onCookiesExtracted=(handleCookiesExtracted) initialCookies={clickToPayCookies->Option.getOr("")}>
    children
  </ClickToPay.Provider>
}
