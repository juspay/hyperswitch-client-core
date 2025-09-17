open LoggerTypes
open LoggerUtils

module LogStorage = {
  let mainLogFile: array<logFile> = []
  let eventsCounter = ref(Dict.make())
  let maxLogsPushedPerEventName = 100

  let getLogCount = () => mainLogFile->Array.length

  let clearLogs = () => {
    let len = mainLogFile->Array.length
    for _ in 0 to len - 1 {
      mainLogFile->Array.pop->ignore
    }
  }

  let conditionalLogPush = (log: logFile) => {
    let eventCountUpdate = eventName => {
      let updatedCounter = switch eventsCounter.contents->Dict.get(eventName) {
      | Some(num) => num + 1
      | None => 1
      }
      eventsCounter.contents->Dict.set(eventName, updatedCounter)
      updatedCounter
    }

    let eventName = log.eventName->eventToStrMapper
    let counter = eventName->eventCountUpdate

    if counter <= maxLogsPushedPerEventName {
      log->(Array.push(mainLogFile, _))->ignore
    }
  }

  let getLogs = () => mainLogFile
}

module PriorityChecker = {
  let priorityEventNames = [
    APP_RENDERED,
    PAYMENT_DATA_FILLED,
    PAYMENT_ATTEMPT,
    CONFIRM_CALL,
    AUTHENTICATION_CALL,
    SDK_CLOSED,
    NETCETERA_SDK,
    REDIRECTING_USER,
    LOADER_CHANGED,
    PAYMENT_METHODS_CALL,
    PAYMENT_METHOD_CHANGED,
    SESSIONS_CALL,
    RETRIEVE_CALL,
    DISPLAY_THREE_DS_SDK,
    APPLE_PAY_STARTED_FROM_JS,
    APPLE_PAY_CALLBACK_FROM_NATIVE,
    APPLE_PAY_PRESENT_FAIL_FROM_NATIVE,
    APPLE_PAY_BRIDGE_SUCCESS,
    DELETE_PAYMENT_METHODS_CALL_INIT,
    DELETE_PAYMENT_METHODS_CALL,
    DELETE_SAVED_PAYMENT_METHOD,
    ADD_PAYMENT_METHOD_CALL_INIT,
    ADD_PAYMENT_METHOD_CALL,
  ]

  let checkForPriorityEvents = (arrayOfLogs: array<logFile>) => {
    arrayOfLogs
    ->Array.find(log => {
      [ERROR, DEBUG]->Array.includes(log.logType) ||
        priorityEventNames->Array.includes(log.eventName)
    })
    ->Option.isSome || arrayOfLogs->Array.length > 8
  }

  let hasPriorityEvents = () => {
    LogStorage.getLogs()->checkForPriorityEvents
  }
}

module LogSender = {
  let sendLogsImmediately = (uri: option<string>, publishableKey, appId) => {
    if LogStorage.getLogCount() > 0 {
      LoggerUtils.sendLogs(LogStorage.getLogs(), uri, publishableKey, appId)
      LogStorage.clearLogs()
    }
  }
}

module DebouncedSender = {
  let logSendDebouncer = Utils.Debouncer.create()
  type logSendParams = (option<string>, string, option<string>)

  let sendLogsDebounced = (uri: option<string>, publishableKey, appId) => {
    let params: logSendParams = (uri, publishableKey, appId)
    let function = ((uri, publishableKey, appId): logSendParams) => {
      LogSender.sendLogsImmediately(uri, publishableKey, appId)
    }

    Utils.Debouncer.execute(~debouncer=logSendDebouncer, ~params, ~delay=5000, ~function)
  }

  let cancelPendingDebouncedSend = () => {
    Utils.Debouncer.cancel(logSendDebouncer)
  }
}

module LogDispatcher = {
  type sendReason =
    | PriorityEvent
    | BatchingDisabled
    | RegularBatch

  let determineSendStrategy = (isEnableLogsBatching: bool) => {
    let hasPriority = PriorityChecker.hasPriorityEvents()
    let shouldSendImmediately = hasPriority || !isEnableLogsBatching

    let reason = if hasPriority {
      PriorityEvent
    } else if !isEnableLogsBatching {
      BatchingDisabled
    } else {
      RegularBatch
    }

    (shouldSendImmediately, reason)
  }

  let executeSendStrategy = (
    uri: option<string>,
    publishableKey,
    appId,
    shouldSendImmediately: bool,
    reason: sendReason,
  ) => {
    if reason == PriorityEvent {
      DebouncedSender.cancelPendingDebouncedSend()
    }

    if shouldSendImmediately {
      LogSender.sendLogsImmediately(uri, publishableKey, appId)
    } else {
      DebouncedSender.sendLogsDebounced(uri, publishableKey, appId)
    }
  }
}

let checkLogSizeAndSendData = (
  logFile: logFile,
  uri: option<string>,
  publishableKey,
  appId,
  isEnableLogsBatching,
) => {
  LogStorage.conditionalLogPush(logFile)
  let (shouldSendImmediately, reason) = LogDispatcher.determineSendStrategy(isEnableLogsBatching)
  LogDispatcher.executeSendStrategy(uri, publishableKey, appId, shouldSendImmediately, reason)
}
