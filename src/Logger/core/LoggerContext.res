include SharedLogger.Context.Native({
  let decode = Base64.decode
  let backfill = LoggerQueue.backfillContext
})
