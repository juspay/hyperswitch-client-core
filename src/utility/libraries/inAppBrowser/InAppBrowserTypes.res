type animations = {
  startEnter: string,
  startExit: string,
  endEnter: string,
  endExit: string,
}

type properties = {
  dismissButtonStyle: string,
  preferredBarTintColor: string,
  preferredControlTintColor: string,
  readerMode: bool,
  animated: bool,
  modalPresentationStyle: string,
  modalTransitionStyle: string,
  modalEnabled: bool,
  enableBarCollapsing: bool,
  showTitle: bool,
  toolbarColor: string,
  secondaryToolbarColor: string,
  navigationBarColor: string,
  navigationBarDividerColor: string,
  enableUrlBarHiding: bool,
  enableDefaultShare: bool,
  forceCloseOnRedirection: bool,
  animations: animations,
  // headers: {
  //   "my-custom-header": "my custom header value"
  // }
  ephemeralWebSession: bool,
  showInRecents: bool,
  // waitForRedirectDelay: int,
}

type res = {url: option<string>, message: string, \"type": string}

type status = Success | Failed | Cancel | Error

type browserRes = {
  paymentID: string,
  amount: string,
  status: status,
}
