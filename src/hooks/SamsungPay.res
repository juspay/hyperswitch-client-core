open SamsungPayType

type samsungPayWalletValidity = Checking | Valid | Invalid | Not_Started
let val = ref(Not_Started)

let isSamsungPayValid = state => {
  state != Checking && state != Not_Started
}

let useSamsungPayValidityHook = () => {
  let (state, setState) = React.useState(_ => val.contents)
  let isSamsungPayAvailable = SamsungPayModule.isAvailable
  let (allApiData, _) = React.useContext(AllApiDataContext.allApiDataContext)
  let sessionToken = allApiData.sessions->getSamsungPaySessionObject

  let stringifiedSessionToken =
    sessionToken
    ->GooglePayTypeNew.toJson
    ->JSON.stringify

  React.useEffect2(() => {
    switch (val.contents, isSamsungPayAvailable, allApiData.sessions) {
    | (Not_Started, false, _) => val := Invalid
    | (Not_Started, true, Some(_)) => {
        val := Checking
        setState(_ => Checking)
        if SamsungPayModule.isAvailable {
          SamsungPayModule.checkSamsungPayValidity(stringifiedSessionToken, status => {
            if status->ThreeDsUtils.isStatusSuccess {
              setState(
                _ => {
                  val := Valid
                  Valid
                },
              )
            } else {
              val := Invalid
              setState(_ => Invalid)
            }
          })
        }
      }

    | (_, _, _) => ()
    }->ignore
    None
  }, (isSamsungPayAvailable, allApiData.sessions))

  state
}
