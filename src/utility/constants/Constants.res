// Timeout for the native Apple Pay present callback (10 seconds). If the native
// sheet never calls back within this window, we surface a "try again" warning
// and log APPLE_PAY_PRESENT_FAIL_FROM_NATIVE.

// Note: This timeout used to be 5 seconds, but we increased it to 10 seconds because 
// some error-logs were reporting that the Apple Pay sheet was taking longer than 5 seconds to present on some devices.
let applePayTimeoutMs = 10000
