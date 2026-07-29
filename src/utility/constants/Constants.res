// Timeout for the native Apple Pay present callback. If the native
// sheet never calls back within this window, we surface a "try again" warning
// and log APPLE_PAY_PRESENT_FAIL_FROM_NATIVE.
let applePayTimeoutMs = 8000
