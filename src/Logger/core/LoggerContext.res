type t = LoggerTypes.context

let empty: t = {sessionId: "", merchantId: "", paymentId: "", authenticationId: ""}

let context = ref(empty)

let onSessionChange = ref(_ => ())

let current = () => context.contents

let keep = (existing, incoming) =>
  switch incoming->Option.map(String.trim) {
  | Some("") | None => existing
  | Some(value) => value
  }

let fillFrom = (started: t, latest: t): t =>
  started.sessionId !== "" && started.sessionId !== latest.sessionId
    ? started
    : {
        sessionId: latest.sessionId->keep(Some(started.sessionId)),
        merchantId: latest.merchantId->keep(Some(started.merchantId)),
        paymentId: latest.paymentId->keep(Some(started.paymentId)),
        authenticationId: latest.authenticationId->keep(Some(started.authenticationId)),
      }

let setSessionData = (~sessionId=?, ~merchantId=?, ~paymentId=?, ~authenticationId=?, ()) => {
  let previous = context.contents
  let base = switch sessionId->Option.map(String.trim) {
  | Some(sessionId) if sessionId !== "" && sessionId !== previous.sessionId => {...empty, sessionId}
  | _ => previous
  }
  let next: t = {
    sessionId: base.sessionId->keep(sessionId),
    merchantId: base.merchantId->keep(merchantId),
    paymentId: base.paymentId->keep(paymentId),
    authenticationId: base.authenticationId->keep(authenticationId),
  }
  context := next
  if next.sessionId !== previous.sessionId {
    LoggerUtils.safeRun(() => onSessionChange.contents())
  }
  if (
    next.sessionId !== previous.sessionId ||
    next.merchantId !== previous.merchantId ||
    next.paymentId !== previous.paymentId ||
    next.authenticationId !== previous.authenticationId
  ) {
    LoggerUtils.safeRun(() => LoggerQueue.backfillContext(next))
  }
}

let paymentIdOfClientSecret = clientSecret =>
  switch clientSecret->String.split("_secret_") {
  | parts if parts->Array.length >= 2 => parts->Array.getUnsafe(0)
  | _ => ""
  }

let sdkAuthorizationValue = (sdkAuthorization, key) =>
  try {
    let prefix = key ++ "="
    sdkAuthorization
    ->Base64.decode
    ->String.split(",")
    ->Array.findMap(entry =>
      entry->String.startsWith(prefix)
        ? switch entry->String.sliceToEnd(~start=prefix->String.length) {
          | "" => None
          | value => Some(value)
          }
        : None
    )
  } catch {
  | _ => None
  }

let paymentIdOfSdkAuthorization = sdkAuthorization =>
  switch sdkAuthorization->sdkAuthorizationValue("payment_id") {
  | Some(_) as paymentId => paymentId
  | None => sdkAuthorization->sdkAuthorizationValue("payment_method_session_id")
  }

let setPaymentId = paymentId =>
  switch paymentId->String.trim {
  | "" => ()
  | paymentId => setSessionData(~paymentId, ())
  }

let setPaymentIdFromCredentials = (~clientSecret="", ~sdkAuthorization=?) =>
  sdkAuthorization
  ->Option.flatMap(paymentIdOfSdkAuthorization)
  ->Option.getOr(clientSecret->paymentIdOfClientSecret)
  ->setPaymentId

let setAuthenticationId = authenticationId =>
  switch authenticationId->String.trim {
  | "" => ()
  | authenticationId => setSessionData(~authenticationId, ())
  }
