/**
 * Hyperswitch Client-Core API Adapter
 * 
 * Platform-specific adapter for React Native that implements the shared API interface.
 * This module bridges the shared API core with React Native specific implementations.
 * 
 * @version 1.0.0
 * @author Hyperswitch Team
 */

open PaymentApiCore
open ApiResponseProcessor
open ApiTypes
open ApiLogger

// ============================================================================
// PLATFORM-SPECIFIC FETCH IMPLEMENTATION
// ============================================================================

/**
 * React Native specific fetch implementation
 * Adapts CommonHooks.fetchApi to the shared fetchFunction interface
 */
let fetchApi: fetchFunction = (~uri, ~method, ~headers, ~bodyStr) => {
  // Convert method string to Fetch.requestMethod
  let fetchMethod = switch method {
  | "GET" => Fetch.Get
  | "POST" => Fetch.Post
  | "PUT" => Fetch.Put
  | "DELETE" => Fetch.Delete
  | _ => Fetch.Post // Default to POST
  }
  
  CommonHooks.fetchApi(~uri, ~method_=fetchMethod, ~headers, ~bodyStr, ())
  ->Promise.then(response => {
    response->Fetch.Response.json
    ->Promise.then(data => {
      Promise.resolve({
        status: response->Fetch.Response.status,
        data,
        headers: Dict.make(), // Extract headers if needed in future
      })
    })
  })
}

// ============================================================================
// SHARED API WRAPPERS WITH MOBILE-SPECIFIC LOGIC
// ============================================================================

/**
 * Confirms payment with mobile-specific handling
 * @param clientSecret - Payment client secret
 * @param publishableKey - Merchant publishable key
 * @param body - Request body as JSON string
 * @param endpoint - API endpoint base URL
 * @param appId - App identifier
 * @returns Promise with processed payment response
 */
let confirmPayment = (~clientSecret, ~publishableKey, ~body, ~endpoint, ~appId=?) => {
  PaymentApiCore.confirmPayment(
    ~fetchApi,
    ~clientSecret,
    ~publishableKey,
    ~body,
    ~endpoint,
    ~appId?,
  )
  ->Promise.then(response => {
    let processed = processPaymentResponse(response)
    // Add mobile-specific response handling here if needed
    Promise.resolve(processed)
  })
}

/**
 * Retrieves payment with mobile-specific handling
 * @param clientSecret - Payment client secret
 * @param publishableKey - Merchant publishable key
 * @param endpoint - API endpoint base URL
 * @param isForceSync - Whether to force synchronous retrieval
 * @param appId - App identifier
 * @returns Promise with processed payment response
 */
let retrievePayment = (~clientSecret, ~publishableKey, ~endpoint, ~isForceSync=false, ~appId=?) => {
  PaymentApiCore.retrievePayment(
    ~fetchApi,
    ~clientSecret,
    ~publishableKey,
    ~endpoint,
    ~isForceSync,
    ~appId?,
  )
  ->Promise.then(response => {
    let processed = processPaymentResponse(response)
    Promise.resolve(processed)
  })
}

/**
 * Fetches payment methods with mobile-specific handling
 * @param clientSecret - Payment client secret
 * @param publishableKey - Merchant publishable key
 * @param endpoint - API endpoint base URL
 * @param appId - App identifier
 * @returns Promise with API response
 */
let fetchPaymentMethods = (~clientSecret, ~publishableKey, ~endpoint, ~appId=?) => {
  PaymentApiCore.fetchPaymentMethods(
    ~fetchApi,
    ~clientSecret,
    ~publishableKey,
    ~endpoint,
    ~appId?,
  )
}

/**
 * Fetches customer payment methods with mobile-specific handling
 * @param clientSecret - Payment client secret
 * @param publishableKey - Merchant publishable key
 * @param endpoint - API endpoint base URL
 * @param appId - App identifier
 * @returns Promise with API response
 */
let fetchCustomerPaymentMethods = (~clientSecret, ~publishableKey, ~endpoint, ~appId=?) => {
  PaymentApiCore.fetchCustomerPaymentMethods(
    ~fetchApi,
    ~clientSecret,
    ~publishableKey,
    ~endpoint,
    ~appId?,
  )
}

/**
 * Creates session tokens with mobile-specific handling
 * @param clientSecret - Payment client secret
 * @param publishableKey - Merchant publishable key
 * @param endpoint - API endpoint base URL
 * @param wallets - Array of wallet configurations
 * @param appId - App identifier
 * @returns Promise with API response
 */
let createSessionTokens = (~clientSecret, ~publishableKey, ~endpoint, ~wallets=[], ~appId=?) => {
  PaymentApiCore.createSessionTokens(
    ~fetchApi,
    ~clientSecret,
    ~publishableKey,
    ~endpoint,
    ~wallets,
    ~appId?,
  )
}

// ============================================================================
// HOOK REPLACEMENTS FOR EXISTING CODE
// ============================================================================

/**
 * Hook replacement for useRedirectHook
 * Provides the same interface as the original hook but uses shared API
 */
let useConfirmPayment = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let baseUrl = GlobalHooks.useGetBaseUrl()()
  
  (~body, ~publishableKey, ~clientSecret, ~errorCallback, ~responseCallback, ~paymentMethod, ~paymentExperience=?, ~isCardPayment=false, ()) => {
    confirmPayment(
      ~clientSecret,
      ~publishableKey,
      ~body,
      ~endpoint=baseUrl,
      ~appId=?nativeProp.hyperParams.appId,
    )
    ->Promise.then(processed => {
      // Handle response based on status
      switch processed.status {
      | Succeeded => 
        responseCallback(
          ~paymentStatus=LoadingContext.PaymentSuccess,
          ~status={status: "succeeded", message: "", code: "", type_: ""}
        )
      | Failed => 
        let errorMsg = processed.error->Option.mapOr("Payment failed", err => err.message)
        errorCallback(
          ~errorMessage={status: "failed", message: errorMsg, type_: "", code: ""},
          ~closeSDK=true,
          ()
        )
      | RequiresCustomerAction =>
        // Handle redirect if needed
        switch processed.nextAction {
        | Some(action) when action.redirectToUrl != "" =>
          responseCallback(
            ~paymentStatus=LoadingContext.ProcessingPayments(None),
            ~status={status: "requires_customer_action", message: "", code: "", type_: ""}
          )
        | _ =>
          responseCallback(
            ~paymentStatus=LoadingContext.ProcessingPayments(None),
            ~status={status: "requires_customer_action", message: "", code: "", type_: ""}
          )
        }
      | Processing | RequiresCapture | RequiresConfirmation | RequiresMerchantAction =>
        responseCallback(
          ~paymentStatus=LoadingContext.ProcessingPayments(None),
          ~status={status: processed.status->paymentStatusToString, message: "", code: "", type_: ""}
        )
      | Cancelled =>
        errorCallback(
          ~errorMessage={status: "cancelled", message: "", type_: "", code: ""},
          ~closeSDK=false,
          ()
        )
      | Unknown(status) =>
        errorCallback(
          ~errorMessage={status, message: "", type_: "", code: ""},
          ~closeSDK=true,
          ()
        )
      }
      Promise.resolve()
    })
    ->Promise.catch(err => {
      errorCallback(
        ~errorMessage={status: "failed", message: "Network error", type_: "", code: ""},
        ~closeSDK=true,
        ()
      )
      Promise.resolve()
    })
    ->ignore
  }
}

/**
 * Hook replacement for useRetrieveHook
 * Provides the same interface as the original hook but uses shared API
 */
let useRetrievePayment = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let baseUrl = GlobalHooks.useGetBaseUrl()()
  
  (type_, clientSecret, publishableKey, ~isForceSync=false) => {
    switch type_ {
    | Types.Payment =>
      retrievePayment(
        ~clientSecret,
        ~publishableKey,
        ~endpoint=baseUrl,
        ~isForceSync,
        ~appId=?nativeProp.hyperParams.appId,
      )
      ->Promise.then(processed => {
        Promise.resolve(processed.rawResponse)
      })
    | Types.List =>
      fetchPaymentMethods(
        ~clientSecret,
        ~publishableKey,
        ~endpoint=baseUrl,
        ~appId=?nativeProp.hyperParams.appId,
      )
      ->Promise.then(response => {
        Promise.resolve(response.data)
      })
    }
  }
}

/**
 * Hook replacement for useSessionToken
 * Provides the same interface as the original hook but uses shared API
 */
let useSessionToken = () => {
  let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
  let baseUrl = GlobalHooks.useGetBaseUrl()()
  
  (~wallet=[], ()) => {
    createSessionTokens(
      ~clientSecret=nativeProp.clientSecret,
      ~publishableKey=nativeProp.publishableKey,
      ~endpoint=baseUrl,
      ~wallets=wallet,
      ~appId=?nativeProp.hyperParams.appId,
    )
    ->Promise.then(response => {
      Promise.resolve(response.data)
    })
    ->Promise.catch(_ => {
      Promise.resolve(JSON.Encode.null)
    })
  }
}

// ============================================================================
// LOGGING INTEGRATION
// ============================================================================

/**
 * Integrates shared API logging with existing logger
 * @param logData - Structured log data from shared API
 * @param logger - Platform-specific logger function
 */
let logApiCall = (logData: logData, logger) => {
  // Convert shared log data to platform-specific format
  logger(
    ~logType=logData.logType,
    ~value=logData.value,
    ~internalMetadata=logData.internalMetadata,
    ~category="API",
    ~eventName=logData.eventName,
    (),
  )
}
