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
    ->Utils.getJsonObjectFromRecord
    ->JSON.stringify

  let checkSPayStatus = () => {
    Promise.make((resolve, _reject) =>
      SamsungPayModule.checkSamsungPayValidity(stringifiedSessionToken, status => {
        if status->ThreeDsUtils.isStatusSuccess {
          resolve(Valid)
        } else {
          resolve(Invalid)
        }
      })
    )
  }

  let isSamsungPayPresentInPML = allApiData.paymentList->Array.reduce(false, (acc, item) => {
    let isSamsungPayPresent = switch item {
    | WALLET(walletVal) => walletVal.payment_method_type_wallet == SAMSUNG_PAY
    | _ => false
    }
    acc || isSamsungPayPresent
  })

  let handleSPay = async () => {
    setState(_ => {
      val := Checking
      Checking
    })
    if sessionToken.wallet_name != NONE && isSamsungPayPresentInPML {
      let status = await checkSPayStatus()
      setState(_ => {
        val := status
        status
      })
    } else {
      setState(_ => {
        val := Invalid
        Invalid
      })
    }
  }
  React.useEffect2(() => {
    switch (val.contents, isSamsungPayAvailable, allApiData.sessions) {
    | (_, false, _) =>
      setState(_ => {
        val := Invalid
        Invalid
      })
    | (Not_Started, true, Some(_)) => handleSPay()->ignore
    | (_, _, _) => ()
    }->ignore
    None
  }, (isSamsungPayAvailable, allApiData.sessions))

  state
}

@react.component
let make = (
  ~walletType: PaymentMethodListType.payment_method_types_wallet,
  ~sessionObject: SessionsType.sessions,
) => {
  let samsungPayStatus = useSamsungPayValidityHook()
  samsungPayStatus == Checking ? <CustomLoader /> : <ButtonElement walletType sessionObject />
}
