@val
external importStatesAndCountries: string => promise<JSON.t> = "import"

type addressCountry = UseContextData | UseBackEndData(array<string>)
type payment_method_types_in_bank_debit = BECS | BACS | Other

type paymentMethodsFields =
  | Email
  | FullName
  | InfoElement
  | Country
  | Bank
  | SpecialField(React.element)
  | UnKnownField(string)
  | BillingName
  | ShippingName
  | PhoneNumber
  | AddressLine1
  | AddressLine2
  | AddressCity
  | StateAndCity
  | CountryAndPincode(array<string>)
  | AddressPincode
  | AddressState
  | AddressCountry(addressCountry)
  | BlikCode
  | Currency(array<string>)
  | AccountNumber
  | BSBNumber
  | PhoneCountryCode
  | SortCode

type requiredField =
  | StringField(string)
  | FullNameField(string, string)

type required_fields_type = {
  required_field: requiredField,
  display_name: string,
  field_type: paymentMethodsFields,
  value: string,
}

type required_fields = array<required_fields_type>

let getRequiredFieldName = (requiredField: requiredField) => {
  switch requiredField {
  | StringField(name) => name
  | FullNameField(firstName, _lastName) => firstName
  }
}

let getPaymentMethodsFieldTypeFromString = str => {
  switch str {
  | "user_email_address" => Email
  | "user_full_name" => FullName
  | "user_country" | "country" => Country
  | "user_bank" => Bank
  | "user_phone_number" => PhoneNumber
  | "user_phone_number_country_code" => PhoneCountryCode
  | "user_address_line1" | "user_shipping_address_line1" => AddressLine1
  | "user_address_line2" | "user_shipping_address_line2" => AddressLine2
  | "user_address_city" | "user_shipping_address_city" => AddressCity
  | "user_address_pincode" | "user_shipping_address_pincode" => AddressPincode
  | "user_address_state" | "user_shipping_address_state" => AddressState
  | "user_blik_code" => BlikCode
  | "user_billing_name" => BillingName
  | "user_shipping_name" => ShippingName
  | "user_bank_account_number" => AccountNumber
  | "user_bsb_number" => BSBNumber
  | "user_bank_sort_code" => SortCode
  | var => UnKnownField(var)
  }
}

let getArrayValFromJsonDict = (dict, key) => {
  dict
  ->JSON.Decode.object
  ->Option.getOr(Dict.make())
  ->Dict.get(key)
  ->Option.flatMap(JSON.Decode.array)
  ->Option.getOr([])
  ->Array.filterMap(JSON.Decode.string)
}

let getPaymentMethodsFieldTypeFromDict = (dict: Dict.t<JSON.t>) => {
  switch (
    dict->Dict.get("user_currency"),
    dict->Dict.get("user_address_country"),
    dict->Dict.get("user_country"),
    dict->Dict.get("user_shipping_address_country"),
  ) {
  | (Some(user_currency), _, _, _) =>
    let options = user_currency->getArrayValFromJsonDict("options")
    Currency(options)
  | (_, Some(user_address_country), _, _)
  | (_, _, Some(user_address_country), _) =>
    let options = user_address_country->getArrayValFromJsonDict("options")
    switch options->Array.get(0)->Option.getOr("") {
    | "" => UnKnownField("empty_list")
    | "ALL" => AddressCountry(UseContextData)
    | _ => AddressCountry(UseBackEndData(options))
    }
  | (_, _, _, Some(user_shipping_address_country)) =>
    let options = user_shipping_address_country->getArrayValFromJsonDict("options")
    switch options->Array.get(0)->Option.getOr("") {
    | "" => UnKnownField("empty_list")
    | "ALL" => AddressCountry(UseContextData)
    | _ => AddressCountry(UseBackEndData(options))
    }
  | _ => UnKnownField("empty_list")
  }
}
let getFieldType = dict => {
  let fieldClass =
    dict->Dict.get("field_type")->Option.getOr(JSON.Encode.null)->JSON.Classify.classify
  switch fieldClass {
  | String(val) => val->getPaymentMethodsFieldTypeFromString
  | Object(dict) => dict->getPaymentMethodsFieldTypeFromDict
  | _ => UnKnownField("unknown_field_type")
  }
}
let getPaymentMethodsFieldsOrder = paymentMethodField => {
  switch paymentMethodField {
  | AccountNumber => 1
  | BSBNumber => 2
  | SortCode => 3
  | FullName | ShippingName | BillingName => 4
  | Email => 5
  | AddressLine1 => 6
  | AddressLine2 => 7
  | AddressCity => 8
  | AddressCountry(_) => 9
  | AddressState => 10
  | StateAndCity => 11
  | CountryAndPincode(_) => 12
  | AddressPincode => 13
  | InfoElement => 99
  | _ => 0
  }
}

let sortRequirFields = (
  firstPaymentMethodField: required_fields_type,
  secondPaymentMethodField: required_fields_type,
) => {
  if firstPaymentMethodField.field_type === secondPaymentMethodField.field_type {
    let requiredFieldsPath =
      firstPaymentMethodField.required_field->getRequiredFieldName->String.split(".")
    let fieldName =
      requiredFieldsPath
      ->Array.get(requiredFieldsPath->Array.length - 1)
      ->Option.getOr("")
    switch fieldName {
    | "first_name" => -1
    | "last_name" => 1
    | _ => 0
    }
  } else {
    firstPaymentMethodField.field_type->getPaymentMethodsFieldsOrder -
      secondPaymentMethodField.field_type->getPaymentMethodsFieldsOrder
  }
}

let mergeNameFields = (arr, ~fieldType, ~displayName=?) => {
  let nameFields = arr->Array.filter(requiredField => {
    requiredField.field_type === fieldType &&
      displayName
      ->Option.map(displayName => requiredField.display_name === displayName)
      ->Option.getOr(true)
  })

  switch (nameFields[0], nameFields[1]) {
  | (Some(firstNameField), Some(lastNameField)) =>
    let value = switch (firstNameField.value, lastNameField.value) {
    | (firstNameValue, "") => firstNameValue
    | ("", lastNameValue) => lastNameValue
    | (firstNameValue, lastNameValue) => [firstNameValue, lastNameValue]->Array.join(" ")
    }

    arr->Array.filterMap(x => {
      if x === firstNameField {
        {
          ...x,
          required_field: FullNameField(
            firstNameField.required_field->getRequiredFieldName,
            lastNameField.required_field->getRequiredFieldName,
          ),
          value,
        }->Some
      } else if x === lastNameField {
        None
      } else {
        Some(x)
      }
    })
  | _ => arr
  }
}

let getRequiredFieldsFromDict = dict => {
  let requiredFields = dict->Dict.get("required_fields")->Option.flatMap(JSON.Decode.object)
  switch requiredFields {
  | Some(val) =>
    let arr =
      val
      ->Dict.valuesToArray
      ->Array.map(item => {
        let itemToObj = item->JSON.Decode.object->Option.getOr(Dict.make())
        {
          required_field: Utils.getString(itemToObj, "required_field", "")->StringField,
          display_name: Utils.getString(itemToObj, "display_name", ""),
          field_type: itemToObj->getFieldType,
          value: Utils.getString(itemToObj, "value", ""),
        }
      })
      ->Belt.SortArray.stableSortBy(sortRequirFields)

    arr
    ->mergeNameFields(~fieldType=FullName)
    ->mergeNameFields(~fieldType=FullName, ~displayName="card_holder_name")
    ->mergeNameFields(~fieldType=Email)
    ->mergeNameFields(~fieldType=BillingName)
    ->mergeNameFields(~fieldType=ShippingName)

  | _ => []
  }
}

let getErrorMsg = (
  ~field_type: paymentMethodsFields,
  ~localeObject: LocaleDataType.localeStrings,
) => {
  switch field_type {
  | AddressLine1 => localeObject.line1EmptyText
  | AddressCity => localeObject.cityEmptyText
  | AddressPincode => localeObject.postalCodeEmptyText
  | Email => localeObject.emailEmptyText
  | _ => localeObject.requiredText
  }
}
let numberOfDigitsValidation = (
  ~text,
  ~localeObject: LocaleDataType.localeStrings,
  ~digits,
  ~display_name,
) => {
  if text->Validation.containsOnlyDigits && text->Validation.clearSpaces->String.length > 0 {
    if text->String.length == digits {
      None
    } else {
      Some(
        localeObject.enterValidDigitsText ++
        digits->Int.toString ++
        localeObject.digitsText ++
        display_name->Option.getOr("")->Utils.toCamelCase,
      )
    }
  } else {
    Some(localeObject.enterValidDetailsText)
  }
}

let checkIsValid = (
  ~text: string,
  ~field_type: paymentMethodsFields,
  ~localeObject: LocaleDataType.localeStrings,
  ~paymentMethodType: option<payment_method_types_in_bank_debit>,
  ~display_name=?,
) => {
  if text == "" {
    getErrorMsg(~field_type, ~localeObject)->Some
  } else {
    switch field_type {
    | Email =>
      switch text->Validation.isValidEmail {
      | Some(false) => Some(localeObject.emailInvalidText)
      | Some(true) => None
      | None => Some(localeObject.emailEmptyText)
      }
    | AccountNumber =>
      switch paymentMethodType {
      | Some(BECS) => numberOfDigitsValidation(~text, ~localeObject, ~digits=9, ~display_name)
      | Some(BACS) => numberOfDigitsValidation(~text, ~localeObject, ~digits=8, ~display_name)
      | _ => None
      }
    | BSBNumber => numberOfDigitsValidation(~text, ~localeObject, ~digits=6, ~display_name)
    | SortCode => numberOfDigitsValidation(~text, ~localeObject, ~digits=6, ~display_name)
    | _ => None
    }
  }
}

let validateDigits = (
  ~text,
  ~fieldType,
  ~prev,
  ~paymentMethodType: option<payment_method_types_in_bank_debit>,
) => {
  let val = text->Option.getOr("")->Validation.clearSpaces
  switch fieldType {
  | AccountNumber =>
    switch paymentMethodType {
    | Some(BECS) =>
      if val->String.length <= 9 {
        Some(val)
      } else {
        prev
      }
    | Some(BACS) =>
      if val->String.length <= 8 {
        Some(val)
      } else {
        prev
      }
    | _ => None
    }
  | BSBNumber
  | SortCode =>
    if val->String.length <= 6 {
      Some(val)
    } else {
      prev
    }
  | _ => text
  }
}

let getKeyboardType = (~field_type: paymentMethodsFields) => {
  switch field_type {
  | Email => #"email-address"
  | _ => #default
  }
}

let toCamelCase = str => {
  str
  ->String.split("_")
  ->Array.map(item => {
    let arr = item->String.split("")
    let firstChar = arr->Array.get(0)->Option.getOr("")->String.toUpperCase
    [firstChar]->Array.concat(arr->Array.sliceToEnd(~start=1))->Array.join("")
  })
  ->Array.join(" ")
}

let useGetPlaceholder = (
  ~field_type: paymentMethodsFields,
  ~display_name: string,
  ~required_field: requiredField,
) => {
  let localeObject = GetLocale.useGetLocalObj()

  let getName = placeholder => {
    let requiredFieldsPath = required_field->getRequiredFieldName->String.split(".")
    let fieldName =
      requiredFieldsPath
      ->Array.get(requiredFieldsPath->Array.length - 1)
      ->Option.getOr("")
    switch field_type {
    | FullName =>
      if display_name === "card_holder_name" {
        localeObject.cardHolderName
      } else {
        switch fieldName {
        | "first_name" => localeObject.fullNameLabel
        | "last_name" => localeObject.fullNameLabel
        | "card_holder_name" => localeObject.cardHolderName
        | _ => placeholder
        }
      }
    | BillingName => localeObject.billingNameLabel
    | ShippingName => localeObject.fullNamePlaceholder
    | _ => placeholder
    }
  }

  () =>
    switch field_type {
    | Email => localeObject.emailLabel
    | FullName => localeObject.fullNamePlaceholder->getName
    | ShippingName => localeObject.fullNamePlaceholder->getName
    | Country => localeObject.countryLabel
    | Bank => localeObject.bankLabel
    | BillingName => localeObject.fullNamePlaceholder->getName
    | AddressLine1 => localeObject.line1Placeholder
    | AddressLine2 => localeObject.line2Placeholder
    | AddressCity => localeObject.cityLabel
    | AddressPincode => localeObject.postalCodeLabel
    | AddressState => localeObject.stateLabel
    | AddressCountry(_) => localeObject.countryLabel
    | Currency(_) => localeObject.currencyLabel
    | InfoElement => localeObject.requiredText
    // | ShippingCountry(_) => localeObject.countryLabel
    // | ShippingAddressLine1 => localeObject.line1Placeholder
    // | ShippingAddressLine2 => localeObject.line2Placeholder
    // | ShippingAddressCity => localeObject.cityLabel
    // | ShippingAddressPincode => localeObject.postalCodeLabel
    // | ShippingAddressState => localeObject.stateLabel
    | PhoneCountryCode
    | SpecialField(_)
    | AccountNumber
    | BSBNumber
    | UnKnownField(_)
    | PhoneNumber
    | StateAndCity
    | CountryAndPincode(_)
    | SortCode
    | BlikCode =>
      display_name->toCamelCase
    }
}

let rec flattenObject = (obj, addIndicatorForObject) => {
  let newDict = Dict.make()
  switch obj->JSON.Decode.object {
  | Some(obj) =>
    obj
    ->Dict.toArray
    ->Array.forEach(entry => {
      let (key, value) = entry

      if value === JSON.Null {
        Dict.set(newDict, key, value)
      } else {
        switch value->JSON.Decode.object {
        | Some(_valueObj) => {
            if addIndicatorForObject {
              Dict.set(newDict, key, JSON.Encode.object(Dict.make()))
            }

            let flattenedSubObj = flattenObject(value, addIndicatorForObject)

            flattenedSubObj
            ->Dict.toArray
            ->Array.forEach(subEntry => {
              let (subKey, subValue) = subEntry
              Dict.set(newDict, `${key}.${subKey}`, subValue)
            })
          }

        | None => Dict.set(newDict, key, value)
        }
      }
    })
  | _ => ()
  }
  newDict
}

let rec setNested = (dict, keys, value) => {
  switch keys->Array.get(0) {
  | Some(currKey) =>
    if keys->Array.length === 1 {
      Dict.set(dict, currKey, value)
    } else {
      let subDict = switch Dict.get(dict, currKey) {
      | Some(json) =>
        switch json->JSON.Decode.object {
        | Some(obj) => obj
        | None => dict
        }
      | None => {
          let subDict = Dict.make()
          Dict.set(dict, currKey, subDict->JSON.Encode.object)
          subDict
        }
      }
      let remainingKeys = keys->Array.sliceToEnd(~start=1)
      setNested(subDict, remainingKeys, value)
    }
  | None => ()
  }
}

let unflattenObject = obj => {
  let newDict = Dict.make()

  switch obj->JSON.Decode.object {
  | Some(dict) =>
    dict
    ->Dict.toArray
    ->Array.forEach(entry => {
      let (key, value) = entry
      setNested(newDict, key->String.split("."), value)
    })
  | None => ()
  }
  newDict
}

let getArrayOfTupleFromDict = dict => {
  dict
  ->Dict.keysToArray
  ->Array.map(key => (key, Dict.get(dict, key)->Option.getOr(JSON.Encode.null)))
}

let mergeTwoFlattenedJsonDicts = (dict1, dict2) => {
  let dict1Entries =
    dict1
    ->Dict.toArray
    ->Array.filter(((_, val)) => {
      //to remove undefined values
      val->JSON.stringifyAny->Option.isSome && val->JSON.Classify.classify != Null
    })
  let dict2Entries =
    dict2
    ->Dict.toArray
    ->Array.filter(((_, val)) => {
      //to remove undefined values
      val->JSON.stringifyAny->Option.isSome && val->JSON.Classify.classify != Null
    })
  dict1Entries->Array.concat(dict2Entries)->Dict.fromArray->JSON.Encode.object->unflattenObject
}

let getIsBillingField = requiredFieldType => {
  switch requiredFieldType {
  | AddressLine1
  | AddressLine2
  | AddressCity
  | AddressPincode
  | AddressState
  | AddressCountry(_) => true
  | _ => false
  }
}

let getIsAnyBillingDetailEmpty = (requiredFields: array<required_fields_type>) => {
  requiredFields->Array.reduce(false, (acc, requiredField) => {
    if getIsBillingField(requiredField.field_type) {
      requiredField.value === "" || acc
    } else {
      acc
    }
  })
}

let filterDynamicFieldsFromRendering = (
  requiredFields: array<required_fields_type>,
  finalJson: dict<(JSON.t, option<string>)>,
) => {
  let isAnyBillingDetailEmpty = requiredFields->getIsAnyBillingDetailEmpty
  requiredFields->Array.filter(requiredField => {
    let isShowBillingField = getIsBillingField(requiredField.field_type) && isAnyBillingDetailEmpty

    let isRenderRequiredField = switch requiredField.required_field {
    | StringField(_) => requiredField.value === ""
    | FullNameField(firstNameVal, lastNameVal) =>
      switch (finalJson->Dict.get(firstNameVal), finalJson->Dict.get(lastNameVal)) {
      | (Some((_, Some(_))), Some((_, Some(_))))
      | (Some((_, Some(_))), _)
      | (_, Some((_, Some(_)))) => true
      | _ => false
      }
    }

    isRenderRequiredField || isShowBillingField
  })
}

let getRequiredFieldPath = (~isSaveCardsFlow, ~requiredField: required_fields_type) => {
  let isFieldTypeName =
    requiredField.field_type === FullName || requiredField.field_type === BillingName
  let isDisplayNameCardHolderName = requiredField.display_name === "card_holder_name"
  let isRequiedFieldCardHolderName =
    requiredField.required_field === StringField("payment_method_data.card.card_holder_name")

  isSaveCardsFlow && isFieldTypeName && isDisplayNameCardHolderName && isRequiedFieldCardHolderName
    ? StringField("payment_method_data.card_token.card_holder_name")
    : requiredField.required_field
}

let getIsSaveCardHaveName = (saveCardData: SdkTypes.savedDataType) => {
  switch saveCardData {
  | SAVEDLISTCARD(savedCard) => savedCard.cardHolderName->Option.getOr("") !== ""
  | SAVEDLISTWALLET(_) => false
  | NONE => false
  }
}

let filterRequiredFields = (
  requiredFields: array<required_fields_type>,
  isSaveCardsFlow,
  saveCardsData: option<SdkTypes.savedDataType>,
) => {
  switch (isSaveCardsFlow, saveCardsData) {
  | (true, Some(saveCardsData)) => {
      let isSavedCardHaveName = saveCardsData->getIsSaveCardHaveName
      if isSavedCardHaveName {
        let val = requiredFields->Array.filter(requiredField => {
          requiredField.display_name !== "card_holder_name"
        })
        val
      } else {
        requiredFields
      }
    }
  | _ => requiredFields
  }
}

let filterRequiredFieldsForShipping = (
  requiredFields: array<required_fields_type>,
  shouldRenderShippingFields: bool,
) => {
  if shouldRenderShippingFields {
    requiredFields
  } else {
    requiredFields->Array.filter(requiredField => {
      !(requiredField.required_field->getRequiredFieldName->String.includes("shipping"))
    })
  }
}

let getKey = (path, value) => {
  if path == "" {
    path
  } else {
    let arr = path->String.split(".")
    let key =
      arr->Array.slice(~start=0, ~end=arr->Array.length - 1)->Array.join(".") ++ "." ++ value
    key
  }
}

let getKeysValArray = (requiredFields, isSaveCardsFlow, clientCountry, countries) => {
  requiredFields->Array.reduce(Dict.make(), (acc, requiredField) => {
    let (value, isValid) = switch (requiredField.value, requiredField.field_type) {
    | ("", AddressCountry(values)) => {
        let values = switch values {
        | UseContextData => countries
        | UseBackEndData(a) => a
        }
        (
          values->Array.includes(clientCountry)
            ? clientCountry->JSON.Encode.string
            : values->Array.length === 1
            ? values->Array.get(0)->Option.getOr("")->JSON.Encode.string
            : JSON.Encode.null,
          None,
        )
      }

    | ("", _) => (JSON.Encode.null, Some("Required"))
    | (value, _) => (value->JSON.Encode.string, None)
    }

    let requiredFieldPath = getRequiredFieldPath(~isSaveCardsFlow, ~requiredField)

    switch requiredFieldPath {
    | StringField(fieldPath) => acc->Dict.set(fieldPath, (value, isValid))

    | FullNameField(firstName, lastName) =>
      let arr = requiredField.value->String.split(" ")
      let firstNameVal = arr->Array.get(0)->Option.getOr("")
      let lastNameVal = arr->Array.filterWithIndex((_, index) => index !== 0)->Array.join(" ")

      let (firstNameVal, isFirstNameValid) =
        firstNameVal === ""
          ? (JSON.Encode.null, Some("First Name is required"))
          : (JSON.Encode.string(firstNameVal), None)
      let (lastNameVal, isLastNameValid) =
        lastNameVal === ""
          ? (JSON.Encode.null, Some("Last Name is required"))
          : (JSON.Encode.string(lastNameVal), None)

      acc->Dict.set(firstName, (firstNameVal, isFirstNameValid))
      acc->Dict.set(lastName, (lastNameVal, isLastNameValid))
    }

    acc
  })
}
