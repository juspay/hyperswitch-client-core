// open SamsungPayType

type samsungPayWalletValidity = Checking | Valid | Invalid | Not_Started
let val = ref(Not_Started)

let isSamsungPayValid = state => {
  state != Checking && state != Not_Started
}

let useSamsungPayValidityHook = () => {
  let (state, setState) = React.useState(_ => val.contents)
  let _isSamsungPayAvailable = SamsungPayModule.isAvailable
  // let (allApiData, _) = React.useContext(AllApiDataContext.allApiDataContext)
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)

  // let sessionToken = allApiData.sessions->getSamsungPaySessionObject
  // let stringifiedSessionToken =
  //   sessionToken
  //   ->Utils.getJsonObjectFromRecord
  //   ->JSON.stringify

  let _checkSPayStatus = () => {
    // Promise.make((resolve, _reject) =>
    //   SamsungPayModule.checkSamsungPayValidity(stringifiedSessionToken, status => {
    //     if status->ThreeDsUtils.isStatusSuccess {
    //       resolve(Valid)
    //     } else {
    //       resolve(Invalid)
    //     }
    //   })
    // )
    ()
  }

  // let isSamsungPayPresentInPML = {
  //   let isPresentInAccPML = allApiData.paymentMethodList->Array.reduce(false, (acc, item) => {
  //     let isSamsungPayPresent = switch item.payment_method {
  //     | WALLET => item.payment_method_type_wallet == SAMSUNG_PAY
  //     | _ => false
  //     }
  //     acc || isSamsungPayPresent
  //   })
  //   let isPresentInCustPML = switch allApiData.savedPaymentMethods {
  //   | Some({pmList: Some(pmList)}) =>
  //     pmList->Array.reduce(false, (acc, item) => {
  //       let isSamsungPayPresent = switch item {
  //       | SAVEDLISTWALLET(val) =>
  //         val.walletType->Option.getOr("")->SdkTypes.walletNameToTypeMapper == SAMSUNG_PAY
  //       | _ => false
  //       }
  //       acc || isSamsungPayPresent
  //     })
  //   | _ => false
  //   }
  //   isPresentInCustPML || isPresentInAccPML
  // }
  let _isSamsungDevice = nativeProp.hyperParams.deviceBrand->Option.getOr("") == "samsung"

  let _handleSPay = async () => {
    setState(_ => {
      val := Checking
      Checking
    })
    // if sessionToken.wallet_name != NONE && isSamsungPayPresentInPML && isSamsungDevice {
    //   let status = await checkSPayStatus()
    //   setState(_ => {
    //     val := status
    //     status
    //   })
    // } else {
    //   setState(_ => {
    //     val := Invalid
    //     Invalid
    //   })
    // }
  }

  // React.useEffect2(() => {
  //   switch (val.contents, isSamsungPayAvailable, allApiData.sessions) {
  //   | (_, false, _) =>
  //     setState(_ => {
  //       val := Invalid
  //       Invalid
  //     })
  //   | (Not_Started, true, Some(_)) => handleSPay()->ignore
  //   | (_, _, _) => ()
  //   }->ignore
  //   None
  // }, (isSamsungPayAvailable, allApiData.sessions))

  state
}

@react.component
let make = (~walletType as _: string, ~sessionObject as _: SessionsType.sessions) => {
  let samsungPayStatus = useSamsungPayValidityHook()
  samsungPayStatus == Checking ? <CustomLoader /> : React.null //<ButtonElement walletType sessionObject />
}
