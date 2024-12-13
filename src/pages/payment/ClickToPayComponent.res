open ReactNative

type authenticationMethodType = {authenticationMethodType: string}

type authenticationMethods = array<authenticationMethodType>

type digitalCardData = {
  presentationName?: string,
  descriptorName: string,
  artUri: string,
  authenticationMethods?: authenticationMethods,
  isCoBranded: bool,
  coBrandedName?: string,
  status: string,
}

type dcf = {
  \"type": string,
  uri: string,
  logoUri: string,
  name: string,
}

type maskedBillingAddress = {country?: string}

type cards = {
  srcDigitalCardId: string,
  panBin: string,
  panLastFour: string,
  tokenLastFour?: string,
  digitalCardData: digitalCardData,
  digitalCardFeatures: array<string>,
  panExpirationMonth: string,
  panExpirationYear: string,
  countryCode: string,
  dcf: dcf,
  dateOfCardCreated: string,
  dateOfCardLastUsed?: string,
  paymentCardDescriptor: string,
  paymentCardType: string,
  maskedBillingAddress: maskedBillingAddress,
}

type clickToPayData = {
  cards: array<cards>,
  recognitionToken: string,
}

@react.component
let make = (~cardData: clickToPayData) => {
  let intervalId = React.useRef(Nullable.null)
  let token = "eyJraWQiOiIyMDIzMDIwODA4NTE1Ny1zYW5kYm94LWlkZW50aXR5LXZlcmlmaWNhdGlvbi1zcmMtbWFzdGVyY2FyZC1pbnQiLCJ0eXAiOiJKV1QrZXh0LnJlY29nbml0aW9uX3Rva2VuIiwiYWxnIjoiUlMyNTYifQ.eyJhcHBJbnN0YW5jZUlkIjoiODJkOTIyYmItNTE0Zi00NWZlLWE3MTItMGQyNDg5Mzc2MTFkIiwiYXVkIjoiaHR0cHM6XC9cL21hc3RlcmNhcmQuY29tIiwiY29uc3VtZXJJZCI6Ijk0MmM4ZGUyLTFjZjItNDBmYy1hZDk0LTk5OTc3YWYxYzU4OCIsInNyY2lDbGllbnRJZCI6IjU0NGVmODFhLWRhZTAtNGYyNi05NTExLWJmYmRiYTNkNjJiNSIsImlzcyI6Imh0dHBzOlwvXC9tYXN0ZXJjYXJkLmNvbSIsInNjb3BlcyI6WyJERUZBVUxUIl0sImV4cCI6MTc0OTU0Mzg1MywiaWF0IjoxNzMzOTkxODUzLCJqdGkiOiIyYWY5YTk0ZS1jZTIzLTRkODctODU2OC1kYjAyNWQ2ODlmZjMiLCJwcm9ncmFtSWQiOiJTUkMifQ.VFzQG8_60Z2hpb3cEZzFrXW_Vm-5UZQpn-ic6J4_jpm7CkN2bFBu3R7KvMIe6t5-KY4IuX5Isq1EZj8wRKr6fvR5eOuuVydKg9Pb9TUrxzLHo-PG66NL6kWmXRswsIWjQeTUnz7PmVtRv_8D9KjBVesEDufCNR58uqstMev2n9NJoDtD3NMuanmz-K0FxvS37uFvTScuKpPpoIHIKRRGLMB11nr5EO2WGhtAMojsLVDKAukL0RzO5Wo3TwGnZ4TLZzSaDPx7Fc4_s8RVBcqu4H4RjmbSSMprmzf6crcv6iYM4AlNXZYnMvm3CXlqXdZwPhksn7JXPcLxO7MalBUysQ"
  let cardId = "S6s1eQSoQKaNYobMFPhSNA000000000000US"

  <>
    {cardData.cards
    ->Array.mapWithIndex((item, i) => {
      <Text key={item.srcDigitalCardId ++ i->Int.toString}>
        {(item.panBin ++ "******" ++ item.panLastFour)->React.string}
      </Text>
    })
    ->React.array}
    //S6s1eQSoQKaNYobMFPhSNA000000000000US
    <Button
      title="Pay with ClickToPay"
      onPress={_ =>
        BrowserHook.openUrl(
          `https://glittery-kitsune-34d325.netlify.app/test2.html?recognitionToken=${token}&srcDigitalCardId=${cardId}&appScheme=appId`,
          Some("appId"),
          intervalId,
        )
        ->Promise.then(res => {Promise.resolve()})
        ->ignore}
    />
  </>
}
