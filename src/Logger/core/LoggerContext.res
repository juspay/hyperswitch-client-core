type t = LoggerTypes.context

let empty: t = {
  sessionId: "",
  merchantId: "",
  paymentId: "",
  pmSessionId: "",
  authenticationId: "",
  scoped: false,
}

// Starts with the generated session id, so rows logged before any screen sets its identity carry
// the same id as the rest (native ids replace it when a screen brings one).
let context = ref({...empty, sessionId: LoggerSession.generatedId()})

let onSessionChange = ref(() => ())

let current = () => context.contents

// Makes another React root's identity current as it is, without merging the previous one.
let switchTo = (next: t) => context := next

let keep = (existing, incoming) =>
  switch incoming->Option.map(String.trim) {
  | Some("") | None => existing
  | Some(value) => value
  }

let fillFrom = (started: t, latest: t): t =>
  started.scoped || (started.sessionId !== "" && started.sessionId !== latest.sessionId)
    ? started
    : {
        sessionId: latest.sessionId->keep(Some(started.sessionId)),
        merchantId: latest.merchantId->keep(Some(started.merchantId)),
        paymentId: latest.paymentId->keep(Some(started.paymentId)),
        pmSessionId: latest.pmSessionId->keep(Some(started.pmSessionId)),
        authenticationId: latest.authenticationId->keep(Some(started.authenticationId)),
        scoped: false,
      }

let setSessionData = (
  ~sessionId=?,
  ~merchantId=?,
  ~paymentId=?,
  ~pmSessionId=?,
  ~authenticationId=?,
  (),
) => {
  let previous = context.contents
  let base = switch sessionId->Option.map(String.trim) {
  | Some(sessionId) if sessionId !== "" && sessionId !== previous.sessionId => {...empty, sessionId}
  | _ => previous
  }
  let next: t = {
    sessionId: base.sessionId->keep(sessionId),
    merchantId: base.merchantId->keep(merchantId),
    paymentId: base.paymentId->keep(paymentId),
    pmSessionId: base.pmSessionId->keep(pmSessionId),
    authenticationId: base.authenticationId->keep(authenticationId),
    scoped: false,
  }
  context := next
  if next.sessionId !== previous.sessionId {
    NativeLoggerUtils.safeRun(() => onSessionChange.contents())
  }
  if (
    next.sessionId !== previous.sessionId ||
    next.merchantId !== previous.merchantId ||
    next.paymentId !== previous.paymentId ||
    next.pmSessionId !== previous.pmSessionId ||
    next.authenticationId !== previous.authenticationId
  ) {
    NativeLoggerUtils.safeRun(() => LoggerQueue.backfillContext(next))
  }
}
