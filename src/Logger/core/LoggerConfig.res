let enabled = WebKit.platform !== #next

// Resolved from nativeProp (environment + customEndpoints) once a root mounts.
let endpoint = ref("")
let headers: ref<Dict.t<string>> = ref(Dict.make())

let minimumRank = 0

@inline let schemaVersion = 8

@inline let maxRowsPerEventName = 100
@inline let maxUserEventsPerName = 20

@inline let defaultTimeoutMs = 30000
@inline let userGatedTimeoutMs = 600000

@inline let flushDelayMs = 2000
@inline let maxFlushBackoffMs = 60000
@inline let maxBatchBytes = 30000
@inline let maxQueuedRows = 100
@inline let maxSendAttemptsPerBatch = 4
@inline let sendTimeoutMs = 15000

@inline let maxTextLength = 256
@inline let maxRowTextLength = 1024
@inline let maxDetailBytes = 8192
@inline let maxPayloadFields = 120

@inline let maxConfigBytes = 2048
@inline let maxConfigDepth = 6
@inline let maxConfigArrayItems = 20
@inline let maxConfigOmitted = 10
