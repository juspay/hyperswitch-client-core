let autoRetryPromise = async (promise: promise<'a>, maxAttempts: int): promise<'a> => {
  let rec retryLoop = async (attempt: int): promise<'a> => {
    try {
      let resp = await promise
      Promise.resolve(resp)
    } catch {
    | error =>
      if attempt >= maxAttempts {
        Promise.reject(error)
      } else {
        await retryLoop(attempt + 1)
      }
    }
  }

  if maxAttempts <= 0 {
    Promise.reject(Exn.raiseError("Max attempts must be greater than 0"))
  } else {
    await retryLoop(1)
  }
}
