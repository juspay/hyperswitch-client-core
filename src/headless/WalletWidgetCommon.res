open SdkTypes
open HeadlessUtils

type walletModule = {
  getWalletSession: (int, array<JSON.t>, JSON.t => unit) => unit,
  exitHeadless: (int, string) => unit,
}

let makeWalletModule = (): walletModule => {
  {
    getWalletSession: HyperHeadless.getWalletSession,
    exitHeadless: HyperHeadless.exitHeadless,
  }
}

type walletInfo = {
  walletType: SdkTypes.payment_method_type_wallet,
  walletTypeStr: string,
  isEligible: bool,
}

let walletInfoToJson = (info: walletInfo) =>
  [
    ("wallet", info.walletTypeStr->JSON.Encode.string),
    ("isEligible", info.isEligible->JSON.Encode.bool),
  ]
  ->Dict.fromArray
  ->JSON.Encode.object

let supportedWallets = [
  (SdkTypes.GOOGLE_PAY, "google_pay"),
  (SdkTypes.APPLE_PAY, "apple_pay"),
]

let syntheticWalletMethod = (
  ~walletType: SdkTypes.payment_method_type_wallet,
  ~walletTypeStr: string,
): ClientResponseType.customerPaymentMethod => {
  payment_token: "",
  payment_method_id: "",
  customer_id: "",
  payment_method: WALLET,
  payment_method_str: "wallet",
  payment_method_type: walletTypeStr,
  payment_method_type_wallet: walletType,
  payment_method_issuer: "",
  payment_method_issuer_code: None,
  recurring_enabled: false,
  installment_payment_enabled: false,
  payment_experience: [],
  card: None,
  metadata: None,
  created: "",
  bank: None,
  bank_redirect: None,
  surcharge_details: None,
  requires_cvv: false,
  last_used_at: "",
  default_payment_method_set: false,
  billing: None,
}

let isWalletEligible = (
  ~walletType: SdkTypes.payment_method_type_wallet,
  ~paymentMethodData: option<ClientResponseType.paymentMethodEnabled>,
  ~sessionObject: SessionsType.sessions,
) => {
  switch paymentMethodData {
  | None => false
  | Some(pmData) =>
    let exp =
      pmData.payment_experience->Array.find(
        x => x.payment_experience_type_decode === INVOKE_SDK_CLIENT,
      )

    switch walletType {
    | APPLE_PAY =>
      WebKit.platform !== #android &&
      WebKit.platform !== #androidWebView &&
      WebKit.platform !== #next &&
      sessionObject.wallet_name !== NONE &&
      exp->Option.isSome
    | GOOGLE_PAY =>
      WebKit.platform !== #ios &&
      WebKit.platform !== #iosWebView &&
      WebKit.platform !== #next &&
      sessionObject.wallet_name !== NONE &&
      sessionObject.connector !== "trustpay" &&
      exp->Option.isSome
    | _ => false
    }
  }
}

let findSession = (
  ~sessions: option<array<SessionsType.sessions>>,
  ~walletType: SdkTypes.payment_method_type_wallet,
) =>
  sessions
  ->Option.flatMap(arr => arr->Array.find(item => item.wallet_name == walletType))
  ->Option.getOr(SessionsType.defaultToken)

let findEnabledMethod = (
  ~clientData: option<ClientResponseType.clientResponse>,
  ~walletType: SdkTypes.payment_method_type_wallet,
) =>
  clientData->Option.flatMap(data =>
    data.payment_methods_enabled->Array.find(
      item => item.payment_method_type_wallet == walletType,
    )
  )

let getEligibleWallets = (
  ~clientData: option<ClientResponseType.clientResponse>,
  ~sessions: option<array<SessionsType.sessions>>,
) =>
  supportedWallets->Array.map(((walletType, walletTypeStr)) => {
    let sessionObject = findSession(~sessions, ~walletType)
    let paymentMethodData = findEnabledMethod(~clientData, ~walletType)
    {
      walletType,
      walletTypeStr,
      isEligible: isWalletEligible(~walletType, ~paymentMethodData, ~sessionObject),
    }
  })

let updateRequestId = ref(0)
let launchInFlight = ref(false)

let launchWallet = (
  headlessModule: HeadlessCommon.headlessModule,
  reRegisterCallback,
  nativeProp,
  ~walletType: SdkTypes.payment_method_type_wallet,
  ~walletTypeStr: string,
  ~sessions: option<array<SessionsType.sessions>>,
) => {
  let data = syntheticWalletMethod(~walletType, ~walletTypeStr)

  launchInFlight := true

  HeadlessCommon.processRequest(
    headlessModule,
    reRegisterCallback,
    nativeProp,
    data,
    JSON.Encode.null,
    sessions,
    ~getCvc=_ => JSON.Encode.null,
  )->ignore
}

let runWalletFlow = async (
  headlessModule: HeadlessCommon.headlessModule,
  walletModule: walletModule,
  reRegisterCallback,
  nativeProp: SdkTypes.nativeProp,
) => {
  updateRequestId := updateRequestId.contents + 1
  let requestId = updateRequestId.contents

  let (sdkConfigResponse, clientResponse, sessionResponse) = await Promise.all3((
    sdkConfigAPICall(nativeProp),
    fetchClientData(nativeProp),
    sessionAPICall(nativeProp),
  ))

  let sdkConfig = switch sdkConfigResponse {
  | Some(res) if !(res->ErrorUtils.isError) && res != JSON.Encode.null =>
    Some(res->SdkConfigParser.itemToObjMapper)
  | _ => None
  }

  let sessions = switch sessionResponse->ErrorUtils.isError || sessionResponse == JSON.Encode.null {
  | true => None
  | false => sessionResponse->Utils.getDictFromJson->SessionsType.itemToObjMapper
  }

  let clientData = switch (clientResponse, sdkConfig) {
  | (Some(res), Some(cfg)) if !(res->ErrorUtils.isError) && res != JSON.Encode.null =>
    Some(
      ClientResponseType.parseClientResponse(
        res,
        cfg,
        nativeProp.configuration.paymentMethodOrder,
        nativeProp.configuration.paymentMethodLayout.savedMethodCustomization.hiddenPaymentMethods,
      ),
    )
  | _ => None
  }

  if requestId !== updateRequestId.contents {
    ()
  } else {

  let wallets = getEligibleWallets(~clientData, ~sessions)

  let eligible = wallets->Array.filter(w => w.isEligible)

  reRegisterCallback :=
    (
      () => {
        if launchInFlight.contents {
          launchInFlight := false
          walletModule.exitHeadless(
            nativeProp.rootTag,
            {status: "cancelled", message: "", code: "", type_: ""}->HyperModule.stringifiedResStatus,
          )
        }

        walletModule.getWalletSession(
          nativeProp.rootTag,
          wallets->Array.map(walletInfoToJson),
          response => {
            let selected =
              response
              ->Utils.getDictFromJson
              ->Utils.getOptionString("wallet")
              ->Option.getOr("")

            switch eligible->Array.find(w => w.walletTypeStr == selected) {
            | Some(w) =>
              launchWallet(
                headlessModule,
                reRegisterCallback,
                nativeProp,
                ~walletType=w.walletType,
                ~walletTypeStr=w.walletTypeStr,
                ~sessions,
              )
            | None =>
              launchInFlight := false
              walletModule.exitHeadless(
                nativeProp.rootTag,
                getDefaultError->HyperModule.stringifiedResStatus,
              )
            }
          },
        )
      }
    )

  reRegisterCallback.contents()
  }
}
