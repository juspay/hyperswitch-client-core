open Utils

type paymentMethodsSurface =
  | PaymentMethodsTask
  | CardNumberInput
  | CardExpiryInput
  | CardCVCInput
  | CardHolderNameInput
  | Unknown

let parseSurface = str =>
  switch str {
  | "PaymentMethodsTask" | "cardForm" => PaymentMethodsTask
  | "CardNumberInput" | "cardNumberInput" => CardNumberInput
  | "CardExpiryInput" | "cardExpiryInput" => CardExpiryInput
  | "CardCVCInput" | "cardCVCInput" => CardCVCInput
  | "CardHolderNameInput" | "cardHolderInput" => CardHolderNameInput
  | _ => Unknown
  }

type hyperswitchConfiguration = {
  publishableKey: string,
  profileId?: string,
  environment?: string,
  customEndpoints?: JSON.t,
}

// VaultDetails
type vaultDetails = {
  vaultType: string,
  vaultData: JSON.t,
}

// CardFormInstance
type cardFormInstance = {
  tokenize: option<JSON.t> => promise<JSON.t>,
  status: string,
}

// CreateCardFormOptions
type createCardFormOptions = {appearance?: JSON.t}

// PaymentMethodSession
type paymentMethodSession = {
  vaultDetails: vaultDetails,
  createCardForm: createCardFormOptions => cardFormInstance,
}

// PaymentMethodSessionOptions
type paymentMethodSessionOptions = {
  sdkAuthorization?: string,
  vaultDetails?: vaultDetails,
}

// HyperswitchInstance
type hyperswitchInstance = {
  initPaymentMethodSession: paymentMethodSessionOptions => promise<paymentMethodSession>,
}

type sessionLaunchParams = {
  sdkAuthorization: string,
  vaultType: option<string>,
  vaultData: option<JSON.t>,
}

type fieldConfiguration = {
  appearance: option<JSON.t>,
  styles: option<JSON.t>,
  options: option<JSON.t>,
  placeholder: option<string>,
}

type launchProps = {
  surface: paymentMethodsSurface,
  hyperswitchConfig: hyperswitchConfiguration,
  configuration: fieldConfiguration,
  session: sessionLaunchParams,
}

let parseLaunchProps = (props: Dict.t<JSON.t>): launchProps => {
  let configuration = getObj(props, "configuration", Dict.make())
  let session = getObj(props, "session", Dict.make())
  let hyperswitchConfig = getObj(props, "hyperswitchConfig", Dict.make())

  {
    surface: props->getString("type", "")->parseSurface,
    hyperswitchConfig: {
      publishableKey: hyperswitchConfig->getString("publishableKey", ""),
      profileId: ?getOptionString(hyperswitchConfig, "profileId"),
      environment: ?getOptionString(hyperswitchConfig, "environment"),
      customEndpoints: ?hyperswitchConfig->Dict.get("customEndpoints"),
    },
    configuration: {
      appearance: configuration->Dict.get("appearance"),
      styles: configuration->Dict.get("styles"),
      options: configuration->Dict.get("options"),
      placeholder: configuration->getOptionString("placeholder"),
    },
    session: {
      sdkAuthorization: session->getString("sdk_auth", ""),
      vaultType: session->getOptionString("vault_type"),
      vaultData: session->Dict.get("vault_data"),
    },
  }
}

type globalThis

@val external globalThis: globalThis = "globalThis"

@get_index external getGlobalThisKey: (globalThis, string) => option<'a> = ""

@set_index external setGlobalThisKey: (globalThis, string, 'a) => unit = ""

let getHyper = (): option<hyperswitchInstance> => getGlobalThisKey(globalThis, "hyper")

let setHyper = (hyper: hyperswitchInstance) => setGlobalThisKey(globalThis, "hyper", hyper)

let getPms = (): option<paymentMethodSession> => getGlobalThisKey(globalThis, "pms")

let setPms = (pms: paymentMethodSession) => setGlobalThisKey(globalThis, "pms", pms)

let getCardForm = (): option<cardFormInstance> => getGlobalThisKey(globalThis, "cardForm")

let setCardForm = (cardForm: cardFormInstance) =>
  setGlobalThisKey(globalThis, "cardForm", cardForm)
