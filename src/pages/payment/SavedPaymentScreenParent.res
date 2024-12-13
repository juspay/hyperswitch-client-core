open ReactNative
open Style
open WebView

external toClickToPayData: JSON.t => ClickToPayComponent.clickToPayData = "%identity"

@react.component
let make = (~setConfirmButtonDataRef, ~savedPaymentMethordContextObj) => {
  let (
    clickToPayCards: option<ClickToPayComponent.clickToPayData>,
    setClickToPayCards,
  ) = React.useState(() => None)

  React.useEffect1(() => {
    Console.log2(">>>>>>>>>>>>>>>>", clickToPayCards)
    None
  }, [clickToPayCards])

  let token = "eyJraWQiOiIyMDIzMDIwODA4NTE1Ny1zYW5kYm94LWlkZW50aXR5LXZlcmlmaWNhdGlvbi1zcmMtbWFzdGVyY2FyZC1pbnQiLCJ0eXAiOiJKV1QrZXh0LnJlY29nbml0aW9uX3Rva2VuIiwiYWxnIjoiUlMyNTYifQ.eyJhcHBJbnN0YW5jZUlkIjoiODJkOTIyYmItNTE0Zi00NWZlLWE3MTItMGQyNDg5Mzc2MTFkIiwiYXVkIjoiaHR0cHM6XC9cL21hc3RlcmNhcmQuY29tIiwiY29uc3VtZXJJZCI6Ijk0MmM4ZGUyLTFjZjItNDBmYy1hZDk0LTk5OTc3YWYxYzU4OCIsInNyY2lDbGllbnRJZCI6IjU0NGVmODFhLWRhZTAtNGYyNi05NTExLWJmYmRiYTNkNjJiNSIsImlzcyI6Imh0dHBzOlwvXC9tYXN0ZXJjYXJkLmNvbSIsInNjb3BlcyI6WyJERUZBVUxUIl0sImV4cCI6MTc0OTU0Mzg1MywiaWF0IjoxNzMzOTkxODUzLCJqdGkiOiIyYWY5YTk0ZS1jZTIzLTRkODctODU2OC1kYjAyNWQ2ODlmZjMiLCJwcm9ncmFtSWQiOiJTUkMifQ.VFzQG8_60Z2hpb3cEZzFrXW_Vm-5UZQpn-ic6J4_jpm7CkN2bFBu3R7KvMIe6t5-KY4IuX5Isq1EZj8wRKr6fvR5eOuuVydKg9Pb9TUrxzLHo-PG66NL6kWmXRswsIWjQeTUnz7PmVtRv_8D9KjBVesEDufCNR58uqstMev2n9NJoDtD3NMuanmz-K0FxvS37uFvTScuKpPpoIHIKRRGLMB11nr5EO2WGhtAMojsLVDKAukL0RzO5Wo3TwGnZ4TLZzSaDPx7Fc4_s8RVBcqu4H4RjmbSSMprmzf6crcv6iYM4AlNXZYnMvm3CXlqXdZwPhksn7JXPcLxO7MalBUysQ"

  switch clickToPayCards {
  | Some(cardData) =>
    <SavedPaymentScreen setConfirmButtonDataRef savedPaymentMethordContextObj cardData />
  | None =>
    <WebView
      style={viewStyle(~backgroundColor="transparent", ~height=400.->dp, ())}
      domStorageEnabled=true
      geolocationEnabled=true
      javaScriptEnabled=true
      sharedCookiesEnabled=true
      thirdPartyCookiesEnabled=true
      onMessage={event =>
        setClickToPayCards(_ => event.nativeEvent.data->JSON.parseExn->toClickToPayData->Some)}
      injectedJavaScript={`window.postMessage('{"clickToPayInitialised": true, "recognitionToken": "${token}"}','*')`}
      source={Source.uri(~uri="https://glittery-kitsune-34d325.netlify.app/test1.html", ())}
    />
  }
}
