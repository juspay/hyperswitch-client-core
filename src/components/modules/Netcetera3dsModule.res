open ExternalThreeDsTypes

type module_ = {
  initialiseNetceteraSDK: (string, string, statusType => unit) => unit,
  generateAReqParams: (string, string, (aReqParams, statusType) => unit) => unit,
  recieveChallengeParamsFromRN: (
    string,
    string,
    string,
    string,
    statusType => unit,
    option<string>,
  ) => unit,
  generateChallenge: (statusType => unit) => unit,
  isAvailable: bool,
}

/*
  Lazy load Netcetera3ds module (creates chunk)
  Safe if dependency not installed
  Using %raw to preserve webpack magic comment
*/
let loadNetcetera3ds = (): promise<option<module_>> => {
  %raw(`import(/* webpackChunkName: "react-native-hyperswitch-netcetera-3ds" */ "@juspay-tech/react-native-hyperswitch-netcetera-3ds")`)
  ->Promise.then(moduleObj => {
    let mod: option<module_> = Some(moduleObj)
    Promise.resolve(mod)
  })
  ->Promise.catch(_err => {
    let mod: option<module_> = None
    Promise.resolve(mod)
  })
}

/*
  Initialise Netcetera SDK safely
  Native signature: initialiseNetceteraSDK(apiKey, hsSDKEnvironment, callback)
*/
let initialiseNetceteraSDK = async (
  apiKey: string,
  hsSDKEnvironment: string,
  callback: statusType => unit,
) => {
  let modResult = await loadNetcetera3ds()
  switch modResult {
  | Some(mod) =>
    if mod.isAvailable {
      try {
        mod.initialiseNetceteraSDK(apiKey, hsSDKEnvironment, callback)
      } catch {
      | _ => callback({status: "InitFailed", message: "Failed to initialise Netcetera SDK"})
      }
    } else {
      callback({status: "InitFailed", message: "Netcetera SDK not available"})
    }

  | None => callback({status: "InitFailed", message: "Netcetera SDK module not found"})
  }
}

/*
  Generate AReq params safely
  Native signature: generateAReqParams(messageVersion, directoryServerId, callback)
*/
let generateAReqParams = async (
  messageVersion: string,
  directoryServerId: string,
  callback: (aReqParams, statusType) => unit,
) => {
  let modResult = await loadNetcetera3ds()
  switch modResult {
  | Some(mod) =>
    if mod.isAvailable {
      try {
        mod.generateAReqParams(messageVersion, directoryServerId, callback)
      } catch {
      | _ => callback(
          {deviceData: "", messageVersion: "", sdkTransId: "", sdkAppId: "", sdkEphemeralKey: JSON.Encode.null, sdkReferenceNo: ""},
          {status: "GenAReqFailed", message: "Failed to generate AReq params"},
        )
      }
    } else {
      callback(
        {deviceData: "", messageVersion: "", sdkTransId: "", sdkAppId: "", sdkEphemeralKey: JSON.Encode.null, sdkReferenceNo: ""},
        {status: "GenAReqFailed", message: "Netcetera SDK not available"},
      )
    }

  | None => callback(
      {deviceData: "", messageVersion: "", sdkTransId: "", sdkAppId: "", sdkEphemeralKey: JSON.Encode.null, sdkReferenceNo: ""},
      {status: "GenAReqFailed", message: "Netcetera SDK module not found"},
    )
  }
}

/*
  Receive challenge params from RN safely
  Native signature: recieveChallengeParamsFromRN(acsSignedContent, acsRefNumber, acsTransactionId, threeDSServerTransId, callback, threeDSRequestorAppURL?)
*/
let recieveChallengeParamsFromRN = async (
  acsSignedContent: string,
  acsRefNumber: string,
  acsTransactionId: string,
  threeDSServerTransId: string,
  callback: statusType => unit,
  threeDSRequestorAppURL: option<string>,
) => {
  let modResult = await loadNetcetera3ds()
  Console.log2("Manideep load result: ", modResult)
  switch modResult {
  | Some(mod) =>
    if mod.isAvailable {
      try {
        Console.log2("Module called this: ", modResult)
        mod.recieveChallengeParamsFromRN(
          acsSignedContent,
          acsRefNumber,
          acsTransactionId,
          threeDSServerTransId,
          callback,
          threeDSRequestorAppURL,
        )
      } catch {
      | _ => callback({status: "ChallengeParamsFailed", message: "Failed to receive challenge params"})
      }
    } else {
      callback({status: "ChallengeParamsFailed", message: "Netcetera SDK not available"})
    }

  | None => callback({status: "ChallengeParamsFailed", message: "Netcetera SDK module not found"})
  }
}

/*
  Generate challenge safely
*/
let generateChallenge = async (callback: statusType => unit) => {
  let modResult = await loadNetcetera3ds()
  Console.log2("Manideep manideep: ", modResult)

  switch modResult {
  | Some(mod) =>
    if mod.isAvailable {
      try {
        Console.log2("Manideep load game: ", modResult)
        mod.generateChallenge(callback)
      } catch {
      | _ => callback({status: "ChallengeFailed", message: "Failed to generate challenge"})
      }
    } else {
      callback({status: "ChallengeFailed", message: "Netcetera SDK not available"})
    }

  | None => callback({status: "ChallengeFailed", message: "Netcetera SDK module not found"})
  }
}

/* helper */
let isNetcetera3dsAvailable = async () => {
  let modResult = await loadNetcetera3ds()
  switch modResult {
  | Some(mod) => mod.isAvailable
  | None => false
  }
}
