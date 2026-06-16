open ParentElement

type category =
  | Card
  | Email
  | Name
  | Phone
  | Crypto
  | Date
  | Generic

let classify = (field: SuperpositionTypes.fieldConfig): category =>
  switch field.fieldRenderType {
  | CardNumber | Cvc | CardExpiryMonth | CardExpiryYear | CardNetwork => Card
  | Email => Email
  | FirstName | LastName | CardHolderName => Name
  | Phone | PhoneCountryCode => Phone
  | CryptoCurrency | CryptoNetwork => Crypto
  | Date | DateOfBirth => Date
  | Generic | Dropdown | Country | State => Generic
  }

let toElement = (cat: category, fields): elementType =>
  switch cat {
  | Card => CARD(fields)
  | Email => EMAIL(fields)
  | Name => FULLNAME(fields)
  | Phone => PHONE(fields)
  | Crypto => CRYPTO(fields)
  | Date => DATE(fields)
  | Generic => GENERIC(fields)
  }

let isCombineCluster = (cat: category) =>
  switch cat {
  | Card | Email | Name | Phone | Crypto => true
  | Date | Generic => false
  }

let groupFields = (fields: array<SuperpositionTypes.fieldConfig>): array<elementType> => {
  let count = fields->Array.length
  let catAt = index => fields->Array.get(index)->Option.mapOr(Generic, classify)
  let firstIndexOfCat = cat => fields->Array.findIndex(f => classify(f) === cat)

  let rec runEnd = (cat, index) =>
    index < count && catAt(index) === cat ? runEnd(cat, index + 1) : index

  let rec walk = (start, acc) =>
    if start >= count {
      acc
    } else {
      let cat = catAt(start)
      if isCombineCluster(cat) {
        walk(
          start + 1,
          start === firstIndexOfCat(cat)
            ? acc->Array.concat([toElement(cat, fields->Array.filter(f => classify(f) === cat))])
            : acc,
        )
      } else {
        let stop = runEnd(cat, start + 1)
        walk(stop, acc->Array.concat([toElement(cat, fields->Array.slice(~start, ~end=stop))]))
      }
    }

  walk(0, [])
}

let keyOf = (element: elementType): string =>
  switch element {
  | CARD(fs)
  | CRYPTO(fs)
  | FULLNAME(fs)
  | PHONE(fs)
  | EMAIL(fs)
  | DATE(fs)
  | GENERIC(fs) =>
    fs->Array.get(0)->Option.map(f => f.confirmRequestWritePath)->Option.getOr("empty-group")
  }
