type options = {to: string}
@module("./zip-utils/pako")
external inflate: (Fetch.arrayBuffer, options) => string = "inflate"

let extractZipFromResp = resp => {
  resp
  ->Promise.then(response => response->Fetch.Response.arrayBuffer)
  ->Promise.then(async arrayBuffer =>
    arrayBuffer->inflate({
      to: "string",
    })
  )
  ->Promise.then(async data => data)
}

// let fetchAndExtractZip = link => {
//   Fetch.fetchWithInit(link, Fetch.RequestInit.make(~method_=Get, ()))->extractZipFromResp
// }

let extractJson = async resp => {
  try {
    JSON.parseExn(await extractZipFromResp(resp))
  } catch {
  | _ => JSON.Encode.null
  }
}

// let fetchAndExtractJson = async link => {
//   try {
//     JSON.parseExn(await fetchAndExtractZip(link))
//   } catch {
//   | _ => JSON.Encode.null
//   }
// }
