type errorType = Error | Warning
type errorStringType = Dynamic(string => string) | Static(string)
type errorTupple = (errorType, errorStringType)
type errorKey =
  | INVALID_PK(errorTupple)
  | INVALID_EK(errorTupple)
  | DEPRECATED_LOADSTRIPE(errorTupple)
  | REQUIRED_PARAMETER(errorTupple)
  | UNKNOWN_KEY(errorTupple)
  | UNKNOWN_VALUE(errorTupple)
  | TYPE_BOOL_ERROR(errorTupple)
  | TYPE_STRING_ERROR(errorTupple)
  | INVALID_FORMAT(errorTupple)
  | USED_CL(errorTupple)
  | INVALID_CL(errorTupple)
  | NO_DATA(errorTupple)
  | NO_PML_DATA(errorTupple)

type errorWarning = {
  invalidPk: errorKey,
  invalidEphemeralKey: errorKey,
  deprecatedLoadStripe: errorKey,
  reguirParameter: errorKey,
  typeBoolError: errorKey,
  unknownKey: errorKey,
  typeStringError: errorKey,
  unknownValue: errorKey,
  invalidFormat: errorKey,
  usedCL: errorKey,
  invalidCL: errorKey,
  noData: errorKey,
  noPMLData: errorKey,
}

let isError = (res: JSON.t) => {
  res
  ->JSON.Decode.object
  ->Option.getOr(Dict.make())
  ->Dict.get("error")
  ->Option.isSome
}

let getErrorCode = (res: JSON.t) => {
  res
  ->JSON.Decode.object
  ->Option.getOr(Dict.make())
  ->Dict.get("error")
  ->Option.getOr(JSON.Encode.null)
  ->JSON.Decode.object
  ->Option.getOr(Dict.make())
  ->Dict.get("code")
  ->Option.getOr(JSON.Encode.null)
  ->JSON.stringify
}

let getErrorMessage = (res: JSON.t) => {
  res
  ->JSON.Decode.object
  ->Option.getOr(Dict.make())
  ->Dict.get("error")
  ->Option.getOr(JSON.Encode.null)
  ->JSON.Decode.object
  ->Option.getOr(Dict.make())
  ->Dict.get("message")
  ->Option.getOr(JSON.Encode.null)
  ->JSON.stringify
}

let errorWarning = {
  invalidPk: INVALID_PK(
    Error,
    Static(
      "INTEGRATION ERROR: Invalid Publishable key, starts with pk_snd_(sandbox/test) or pk_prd_(production/live)",
    ),
  ),
  invalidEphemeralKey: INVALID_EK(Error, Static("INTEGRATION ERROR: Ephemeral key not available.")),
  deprecatedLoadStripe: DEPRECATED_LOADSTRIPE(
    Warning,
    Static("loadStripe is deprecated. Please use loadOrca instead."),
  ),
  reguirParameter: REQUIRED_PARAMETER(
    Error,
    Dynamic(
      // str => {`INTEGRATION ERROR: ${str} is a required field/parameter or ${str} cannot be empty`},
      str => {`INTEGRATION ERROR: ${str}`},
    ),
  ),
  unknownKey: UNKNOWN_KEY(
    Warning,
    Dynamic(
      str => {
        `Unknown Key: ${str} is a unknown/invalid key, please provide a correct key. This might cause issue in the future`
      },
    ),
  ),
  typeBoolError: TYPE_BOOL_ERROR(
    Warning,
    Dynamic(
      str => {
        `Type Error: '${str}' Expected boolean`
      },
    ),
  ),
  typeStringError: TYPE_STRING_ERROR(
    Warning,
    Dynamic(
      str => {
        `Type Error: '${str}' Expected string`
      },
    ),
  ),
  unknownValue: UNKNOWN_VALUE(
    Warning,
    Dynamic(
      str => {
        `Unknown Value: ${str}. Please provide a correct value. This might cause issue in the future`
      },
    ),
  ),
  invalidFormat: INVALID_FORMAT(Error, Dynamic(str => {str})),
  usedCL: USED_CL(Error, Static("Data Error: The client secret has been already used.")),
  invalidCL: INVALID_CL(Error, Static("Data Error: The client secret is invalid.")),
  noData: NO_DATA(Error, Static("There is no customer default saved payment method data")),
  noPMLData: NO_PML_DATA(Error, Static("No Payment Method available")),
}
