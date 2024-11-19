// // open ReactNative
// // open PaymentMethodListType
// // open CustomPicker
// // open Redirect
// // //open CustomPicker
// // open UIUtils
// open ReactNative
// open Redirect
// @react.component
// let make = (
//   ~redirectProp: PaymentMethodListType.payment_method,
//   ~fields: Types.redirectTypeJson,
//   ~isScreenFocus,
//   ~setConfirmButtonDataRef: React.element => unit,
//   ~sessionObject: SessionsType.sessions=SessionsType.defaultToken,
// ) => {
//   let (accountnum, setaccountnum) = React.useState(_ => None)
//   let (isaccountnumValid, setisaccountnumValid) = React.useState(_ => None)
//   let (routingnum, setroutingnum) = React.useState(_ => None)
//   let (isroutingnumValid, setisroutingnumValid) = React.useState(_ => None)
//   let (address, setaddress) = React.useState(_ => None)
//   let (address2, setaddress2) = React.useState(_ => None)
//   let (isAddressValid, setIsAddressValid) = React.useState(_ => None)
//   let (isAddress2Valid, setIsAddress2Valid) = React.useState(_ => None)
//   let (account, setaccount) = React.useState(_ => None)
//   let (isNicknameSelected, setIsNicknameSelected) = React.useState(_ => false)
//   //let (AddressIsFocus, setAddressIsFocus) = React.useState(_ => false)

//   let (name, setName) = React.useState(_ => None)
//   let (isNameValid, setIsNameValid) = React.useState(_ => None)
//   let (nameIsFocus, setNameIsFocus) = React.useState(_ => false)
//   let (city, setcity) = React.useState(_ => None)
//   let (iscityValid, setIscityValid) = React.useState(_ => None)
//   let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
//   let (country, setCountry) = React.useState(_ => Some(nativeProp.hyperParams.country))
//   let (state, setState) = React.useState(_ => Some(nativeProp.hyperParams.state))

//   let (blikCode, setBlikCode) = React.useState(_ => None)
//   let (postalCode, setpostalCode) = React.useState(_ => None)
//   let showAlert = AlertHook.useAlerts()
//   let accounts = ["savings", "current"] // Hard Coded The Account_Type Fields in ACHBankDebi

//   let accountTypesList = accounts->Js.Array.sortInPlace

//   let accountItems = Bank.bankNameConverter(accountTypesList)

//   // let accountTypes: array<customPickerType> = accountItems->Array.map(item => {
//   //     {
//   //       name: item.displayName,
//   //       value: item.hyperSwitch,
//   //     }
//   //   })
//   let (statesJson, setStatesJson) = React.useState(_ => None)

//   React.useEffect0(() => {
//     // Dynamically import/download Postal codes and states JSON
//     RequiredFieldsTypes.importStates("./../../utility/reusableCodeFromWeb/States.json")
//     ->Promise.then(res => {
//       setStatesJson(_ => Some(res.states))
//       Promise.resolve()
//     })
//     ->Promise.catch(_ => {
//       setStatesJson(_ => None) // W1
//       Promise.resolve()
//     })
//     ->ignore

//     None
//   })

//   let getStateData = states => {
//     states
//     ->Utils.getStateNames(country->Option.getOr(""))
//     ->Array.map((item): CustomPicker.customPickerType => {
//       {
//         name: item,
//         value: item,
//       }
//     })
//   }
//   let onChangeCountry = val => {
//     setCountry(val)
//     logger(
//       ~logType=INFO,
//       ~value=country->Option.getOr(""),
//       ~category=USER_EVENT,
//       ~eventName=COUNTRY_CHANGED,
//       ~paymentMethod,
//       ~paymentExperience?,
//       (),
//     )
//   }
//   let onChangeState = val => {
//     setState(val)
//     logger(
//       ~logType=INFO,
//       ~value=country->Option.getOr(""),
//       ~category=USER_EVENT,
//       ~eventName=STATE_CHANGED,
//       ~paymentMethod,
//       ~paymentExperience?,
//       (),
//     )
//   }

//   let onChangeBank = val => {
//     setSelectedBank(val)
//   }
//   let onChangeAccountType = val => {
//     setaccount(val)
//   }

//   //   let (accountnum, setaccountnum) = React.useState(_ => None)
//   //   let (isaccountnumValid, setisaccountnumValid) = React.useState(_ => None)
//   //   let (routingnum, setroutingnum) = React.useState(_ => None)
//   //   let (isroutingnumValid, setisroutingnumValid) = React.useState(_ => None)
//   //   let (address, setaddress) = React.useState(_ => None)
//   //   let (address2, setaddress2) = React.useState(_ => None)
//   //   let (isAddressValid, setIsAddressValid) = React.useState(_ => None)
//   //   let (isAddress2Valid, setIsAddress2Valid) = React.useState(_ => None)
//   //   //let (account, setaccount) = React.useState(_ => None)
//   //   let (account, setaccount) = React.useState((): option<string> => None)

//   //   let (isNicknameSelected, setIsNicknameSelected) = React.useState(_ => false)
//   //   let (nativeProp, _) = React.useContext(NativePropContext.nativePropContext)
//   //   let (country, setCountry) = React.useState(_ => Some(nativeProp.hyperParams.country))
//   //   let (postalCode, setpostalCode) = React.useState(_ => None)
//   //   let (name, setName) = React.useState(_ => None)
//   //   let (statesJson, setStatesJson) = React.useState(_ => None)
//   //   let (allApiData, _) = React.useContext(AllApiDataContext.allApiDataContext)
//   //   let (iscityValid, setIscityValid) = React.useState(_ => None)
//   //   let (city, setcity) = React.useState(_ => None)

//   //   let {component, borderWidth, borderRadius} = ThemebasedStyle.useThemeBasedStyle()

//   //   let accounts = ["savings", "current"] // Hard Coded The Account_Type Fields in ACHBankDebi

//   //   let accountTypesList = accounts->Js.Array.sortInPlace

//   //   let accountItems = Bank.bankNameConverter(accountTypesList)

//   //   let accountTypes: array<customPickerType> = accountItems->Array.map(item => {
//   //     {
//   //       name: item.displayName,
//   //       value: item.hyperSwitch,
//   //     }
//   //   })

//   //   React.useEffect0(() => {
//   //     // Dynamically import/download Postal codes and states JSON
//   //     RequiredFieldsTypes.importStates("./../../utility/reusableCodeFromWeb/States.json")
//   //     ->Promise.then(res => {
//   //       setStatesJson(_ => Some(res.states))
//   //       Promise.resolve()
//   //     })
//   //     ->Promise.catch(_ => {
//   //       setStatesJson(_ => None)
//   //       Promise.resolve()
//   //     })
//   //     ->ignore

//   //     None
//   //   })

//   //   let getStateData = states => {
//   //     states
//   //     ->Utils.getStateNames(country->Option.getOr(""))
//   //     ->Array.map((item): CustomPicker.customPickerType => {
//   //       {
//   //         name: item,
//   //         value: item,
//   //       }
//   //     })
//   //   }

//   //   let onChangeAccountType = val => {
//   //     setaccount(val)
//   //   }
//   //   let onChangePostalCode = (val: string) => {
//   //     let onlyNumerics = val->String.replaceRegExp(%re("/\D+/g"), "")
//   //     let firstPart = onlyNumerics->String.slice(~start=0, ~end=3)
//   //     let secondPart = onlyNumerics->String.slice(~start=3, ~end=6)

//   //     let finalVal = if onlyNumerics->String.length <= 3 {
//   //       firstPart
//   //     } else if onlyNumerics->String.length > 3 && onlyNumerics->String.length <= 6 {
//   //       `${firstPart}-${secondPart}`
//   //     } else {
//   //       onlyNumerics
//   //     }
//   //     setpostalCode(_ => Some(finalVal))
//   //   }

//   //   // let processRequest = (
//   //   //   ~payment_method_data,
//   //   //   ~payment_method,
//   //   //   ~payment_method_type,
//   //   //   ~payment_experience_type="redirect_to_url",
//   //   //   ~eligible_connectors=?,
//   //   //   (),
//   //   // ) => {
//   //   //   let body: redirectType = {
//   //   //     client_secret: nativeProp.clientSecret,
//   //   //     return_url: ?Utils.getReturnUrl(nativeProp.hyperParams.appId),
//   //   //     payment_method,
//   //   //     payment_method_type,
//   //   //     payment_experience: payment_experience_type,
//   //   //     connector: ?eligible_connectors,
//   //   //     payment_method_data,
//   //   //     billing: ?nativeProp.configuration.defaultBillingDetails,
//   //   //     shipping: ?nativeProp.configuration.shippingDetails,
//   //   //     setup_future_usage: ?(
//   //   //       allApiData.additionalPMLData.mandateType == NORMAL ? Some("off_session") : None
//   //   //     ),
//   //   //     payment_type: ?allApiData.additionalPMLData.paymentType,
//   //   //     browser_info: {
//   //   //       user_agent: ?nativeProp.hyperParams.userAgent,
//   //   //       language: ?nativeProp.configuration.appearance.locale,
//   //   //     },
//   //   //   }
//   //   // }

//   //   // let processRequestBankDebit = (prop: payment_method_types_ach_bank_debit) => {
//   //   //   let payment_method_data =
//   //   //     [
//   //   //       (
//   //   //         prop.payment_method,
//   //   //         [
//   //   //           (
//   //   //             "ach_bank_debit",
//   //   //             [
//   //   //               ("account_number", accountnum->Option.getOr("")->JSON.Encode.string),
//   //   //               ("routing_number", routingnum->Option.getOr("")->JSON.Encode.string),
//   //   //               // ("name", name->Option.getOr("")->JSON.Encode.string),
//   //   //             ]
//   //   //             ->Dict.fromArray
//   //   //             ->JSON.Encode.object,
//   //   //           ),
//   //   //         ]
//   //   //         ->Dict.fromArray
//   //   //         ->JSON.Encode.object,
//   //   //       ),
//   //   //       (
//   //   //         "billing",
//   //   //         [
//   //   //           (
//   //   //             "address",
//   //   //             [
//   //   //               (
//   //   //                 "first_name",
//   //   //                 switch name {
//   //   //                 | Some(text) => text->String.split(" ")->Array.get(0)
//   //   //                 | _ => Some("")
//   //   //                 }
//   //   //                 ->Option.getOr("")
//   //   //                 ->JSON.Encode.string,
//   //   //               ),
//   //   //               (
//   //   //                 "last_name",
//   //   //                 switch name {
//   //   //                 | Some(text) => text->String.split(" ")->Array.get(1)
//   //   //                 | _ => Some("")
//   //   //                 }
//   //   //                 ->Option.getOr("")
//   //   //                 ->JSON.Encode.string,
//   //   //               ),
//   //   //             ]
//   //   //             ->Dict.fromArray
//   //   //             ->JSON.Encode.object,
//   //   //           ),
//   //   //         ]
//   //   //         ->Dict.fromArray
//   //   //         ->JSON.Encode.object,
//   //   //       ),
//   //   //     ]
//   //   //     ->Dict.fromArray
//   //   //     ->JSON.Encode.object

//   //   //   processRequest(
//   //   //     ~payment_method_data,
//   //   //     ~payment_method=prop.payment_method,
//   //   //     ~payment_method_type=prop.payment_method_type,
//   //   //     //setup_future_usage:"off_session",
//   //   //     (),
//   //   //   )
//   //   // }
//   //   let handlecity = text => {
//   //     let y = if text->String.length >= 3 {
//   //       Some(true)
//   //     } else {
//   //       None
//   //     }
//   //     setIscityValid(_ => y)
//   //     setcity(_ => Some(text))
//   //   }
//   //   let handleAddress1 = text => {
//   //     let y = if text->String.length >= 5 {
//   //       Some(true)
//   //     } else {
//   //       None
//   //     }
//   //     setIsAddressValid(_ => y)
//   //     setaddress(_ => Some(text))
//   //   }
//   //   let handleAddress2 = text => {
//   //     let y = if text->String.length >= 5 {
//   //       Some(true)
//   //     } else {
//   //       None
//   //     }
//   //     setIsAddress2Valid(_ => y)
//   //     setaddress2(_ => Some(text))
//   //   }
//   //   let handlePressAccNum = text => {
//   //     let y = if text->String.length >= 10 {
//   //       Some(true)
//   //     } else {
//   //       None
//   //     }
//   //     setisaccountnumValid(_ => y)
//   //     setaccountnum(_ => Some(text))
//   //   }

//   //   let handlePressRouNum = number => {
//   //     let y = if number->String.length >= 9 {
//   //       Some(true)
//   //     } else {
//   //       None
//   //     }
//   //     setisroutingnumValid(_ => y)
//   //     setroutingnum(_ => Some(number))
//   //   }

//   //   <>
//   //     <Space />
//   //     <ErrorBoundary level={FallBackScreen.Screen} rootTag=nativeProp.rootTag>
//   //       <UIUtils.RenderIf condition={fields.header->String.length > 0}>
//   //         <TextWrapper text={fields.header} textType=Subheading />
//   //       </UIUtils.RenderIf>
//   //       {<>
//   //         <TextWrapper text="Bank Details" textType={SubheadingBold} />
//   //         {fields.fields
//   //         ->Array.mapWithIndex((field, index) =>
//   //           <View key={`field-${fields.text}${index->Int.toString}`}>
//   //             <Space />
//   //             {switch field {
//   //             // | "email" =>
//   //             //   <CustomInput
//   //             //     state={email->Option.getOr("")}
//   //             //     setState={handlePressEmail}
//   //             //     placeholder=localeObject.emailLabel
//   //             //     keyboardType=#"email-address"
//   //             //     borderBottomLeftRadius=borderRadius
//   //             //     borderBottomRightRadius=borderRadius
//   //             //     borderTopLeftRadius=borderRadius
//   //             //     borderTopRightRadius=borderRadius
//   //             //     borderTopWidth=borderWidth
//   //             //     borderBottomWidth=borderWidth
//   //             //     borderLeftWidth=borderWidth
//   //             //     borderRightWidth=borderWidth
//   //             //     isValid=isEmailValidForFocus
//   //             //     onFocus={_ => {
//   //             //       setEmailIsFocus(_ => true)
//   //             //     }}
//   //             //     onBlur={_ => {
//   //             //       setEmailIsFocus(_ => false)
//   //             //     }}
//   //             //     textColor=component.color
//   //             //   />

//   //             // | "name" =>
//   //             //   <CustomInput
//   //             //     state={name->Option.getOr("")}
//   //             //     setState={handlePressName}
//   //             //     placeholder=localeObject.fullNameLabel
//   //             //     keyboardType=#default
//   //             //     isValid=isNameValidForFocus
//   //             //     onFocus={_ => {
//   //             //       setNameIsFocus(_ => true)
//   //             //     }}
//   //             //     onBlur={_ => {
//   //             //       setNameIsFocus(_ => false)
//   //             //     }}
//   //             //     textColor=component.color
//   //             //     borderBottomLeftRadius=borderRadius
//   //             //     borderBottomRightRadius=borderRadius
//   //             //     borderTopLeftRadius=borderRadius
//   //             //     borderTopRightRadius=borderRadius
//   //             //     borderTopWidth=borderWidth
//   //             //     borderBottomWidth=borderWidth
//   //             //     borderLeftWidth=borderWidth
//   //             //     borderRightWidth=borderWidth
//   //             //   />
//   //             | "Address_Line_1" =>
//   //               <CustomInput
//   //                 state={address->Option.getOr("")}
//   //                 setState={handleAddress1}
//   //                 placeholder="Address Line 1"
//   //                 keyboardType=#default
//   //                 // isValid=isAddressValid
//   //                 // onFocus={_ => {
//   //                 //   setAddressIsFocus(_ => true)
//   //                 // }}
//   //                 // onBlur={_ => {
//   //                 //   setAddressIsFocus(_ => false)
//   //                 // }}
//   //                 textColor=component.color
//   //                 borderBottomLeftRadius=borderRadius
//   //                 borderBottomRightRadius=borderRadius
//   //                 borderTopLeftRadius=borderRadius
//   //                 borderTopRightRadius=borderRadius
//   //                 borderTopWidth=borderWidth
//   //                 borderBottomWidth=borderWidth
//   //                 borderLeftWidth=borderWidth
//   //                 borderRightWidth=borderWidth
//   //               />

//   //             | "Address_Line_2" =>
//   //               <CustomInput
//   //                 state={address2->Option.getOr("")}
//   //                 setState={handleAddress2}
//   //                 placeholder="Address Line 2"
//   //                 keyboardType=#default
//   //                 textColor=component.color
//   //                 borderBottomLeftRadius=borderRadius
//   //                 borderBottomRightRadius=borderRadius
//   //                 borderTopLeftRadius=borderRadius
//   //                 borderTopRightRadius=borderRadius
//   //                 borderTopWidth=borderWidth
//   //                 borderBottomWidth=borderWidth
//   //                 borderLeftWidth=borderWidth
//   //                 borderRightWidth=borderWidth
//   //               />
//   //             | "City" =>
//   //               <CustomInput
//   //                 state={city->Option.getOr("")}
//   //                 setState={handlecity}
//   //                 placeholder="City"
//   //                 keyboardType=#default
//   //                 textColor=component.color
//   //                 borderBottomLeftRadius=borderRadius
//   //                 borderBottomRightRadius=borderRadius
//   //                 borderTopLeftRadius=borderRadius
//   //                 borderTopRightRadius=borderRadius
//   //                 borderTopWidth=borderWidth
//   //                 borderBottomWidth=borderWidth
//   //                 borderLeftWidth=borderWidth
//   //                 borderRightWidth=borderWidth
//   //               />
//   //             // | "country" =>
//   //             //   <CustomPicker
//   //             //     value=country
//   //             //     setValue=onChangeCountry
//   //             //     borderBottomLeftRadius=borderRadius
//   //             //     borderBottomRightRadius=borderRadius
//   //             //     borderBottomWidth=borderWidth
//   //             //     items=countryData
//   //             //     placeholderText=localeObject.countryLabel
//   //             //   />
//   //             // | "State" =>
//   //             //   switch statesJson {
//   //             //   | Some(states) =>
//   //             //     <CustomPicker
//   //             //       value=state
//   //             //       setValue=onChangeState
//   //             //       borderBottomLeftRadius=borderRadius
//   //             //       borderBottomRightRadius=borderRadius
//   //             //       borderBottomWidth=borderWidth
//   //             //       items={states->getStateData}
//   //             //       placeholderText=localeObject.stateLabel
//   //             //     />
//   //             //   | None => React.null
//   //             //   }
//   //             // | "bank" =>
//   //             //   <CustomPicker
//   //             //     value=selectedBank
//   //             //     setValue=onChangeBank
//   //             //     borderBottomLeftRadius=borderRadius
//   //             //     borderBottomRightRadius=borderRadius
//   //             //     borderBottomWidth=borderWidth
//   //             //     items=bankData
//   //             //     placeholderText=localeObject.bankLabel
//   //             //   />
//   //             | "account_type" =>
//   //               <>
//   //                 <CustomPicker
//   //                   value=account
//   //                   setValue=onChangeAccountType
//   //                   borderBottomLeftRadius=borderRadius
//   //                   borderBottomRightRadius=borderRadius
//   //                   borderBottomWidth=borderWidth
//   //                   items=accountTypes
//   //                   placeholderText="Account Type"
//   //                 />
//   //                 <Space />
//   //                 <ClickableTextElement
//   //                   disabled={false}
//   //                   initialIconName="checkboxClicked"
//   //                   updateIconName=Some("checkboxNotClicked")
//   //                   text="Bank Details"
//   //                   isSelected=isNicknameSelected
//   //                   setIsSelected=setIsNicknameSelected
//   //                   textType={ModalText}
//   //                   disableScreenSwitch=true
//   //                 />
//   //                 <Space />
//   //                 // <TextWrapper
//   //                 //   text="By providing your bank account details and confirming this payment, you agree to this Direct Debit Request and the Direct Debit Request service agreement and authorise Hyperswitch Payments Australia Pty Ltd."
//   //                 //   textType=ModalTextLight
//   //                 // />

//   //                 <Space />
//   //                 <TextWrapper text="Billing Address" textType=SubheadingBold />
//   //                 <Space />
//   //                 // <TextWrapper
//   //                 //   text="By Default it asks every time for billing details.?"
//   //                 //   textType=HeadingBold
//   //                 // />
//   //                 // <Space />
//   //                 // <TextWrapper text="Which country.?" textType=HeadingBold />
//   //                 // <Space />
//   //               </>
//   //             // | "blik_code" =>
//   //             //   <CustomInput
//   //             //     state={blikCode->Option.getOr("")}
//   //             //     setState={onChangeBlikCode}
//   //             //     borderBottomLeftRadius=borderRadius
//   //             //     borderBottomRightRadius=borderRadius
//   //             //     borderBottomWidth=borderWidth
//   //             //     placeholder="000-000"
//   //             //     keyboardType=#numeric
//   //             //     maxLength=Some(7)
//   //             //   />
//   //             | "postal_code" =>
//   //               <CustomInput
//   //                 state={postalCode->Option.getOr("")}
//   //                 setState={onChangePostalCode}
//   //                 borderBottomLeftRadius=borderRadius
//   //                 borderBottomRightRadius=borderRadius
//   //                 borderBottomWidth=borderWidth
//   //                 placeholder="Postal Code"
//   //                 keyboardType=#numeric
//   //                 maxLength=Some(7)
//   //               />

//   //             | "account_number" =>
//   //               <CustomInput
//   //                 state={accountnum->Option.getOr("")}
//   //                 setState={handlePressAccNum}
//   //                 placeholder="Account Number"
//   //                 borderBottomLeftRadius=borderRadius
//   //                 borderBottomRightRadius=borderRadius
//   //                 borderBottomWidth=borderWidth
//   //                 maxLength=Some(12)
//   //                 keyboardType=#numeric
//   //               />
//   //             | "routing_number" =>
//   //               <CustomInput
//   //                 state={routingnum->Option.getOr("")}
//   //                 setState={handlePressRouNum}
//   //                 placeholder="Routing Number"
//   //                 keyboardType=#numeric
//   //                 borderBottomLeftRadius=borderRadius
//   //                 borderBottomRightRadius=borderRadius
//   //                 borderBottomWidth=borderWidth
//   //                 maxLength=Some(9)
//   //               />

//   //             | _ => React.null
//   //             }}
//   //           </View>
//   //         )
//   //         ->React.array}
//   //         <Space />
//   //         //  <RedirectionText />
//   //       </>}
//   //     </ErrorBoundary>
//   //     <Space height=5. />
//   //   </>
//   // }

//   let paymentMethod = switch redirectProp {
//   | CARD(prop) => prop.payment_method_type
//   | WALLET(prop) => prop.payment_method_type
//   | PAY_LATER(prop) => prop.payment_method_type
//   | BANK_REDIRECT(prop) => prop.payment_method_type
//   | CRYPTO(prop) => prop.payment_method_type
//   | OPEN_BANKING(prop) => prop.payment_method_type
//   | BANK_DEBIT(prop) => prop.payment_method_type
//   }

//   <React.Fragment>
//     <Space />
//     {switch paymentMethod {
//     | "ach" => <TextWrapper text="Bank Details" textType={SubheadingBold} />
//     | _ => React.null
//     }}
//     {<>
//       <ErrorBoundary level={FallBackScreen.Screen} rootTag=nativeProp.rootTag>
//         <UIUtils.RenderIf condition={fields.header->String.length > 0}>
//           <TextWrapper text={fields.header} textType=Subheading />
//         </UIUtils.RenderIf>
//         {
//           let isKlarna = true /* or appropriate logic to determine if it's Klarna */
//           KlarnaModule.klarnaReactPaymentView->Option.isSome && fields.name == "klarna" && isKlarna
//             ? <>
//                 <Space />
//                 // <Klarna
//                 //   launchKlarna=true
//                 //   processRequest=processRequestPayLater
//                 //   return_url={Utils.getReturnUrl(nativeProp.hyperParams.appId)}
//                 //   klarnaSessionTokens=session_token
//                 // />
//                 // <ErrorText text=error />
//               </>
//             : <>
//                 {fields.fields
//                 ->Array.mapWithIndex((field, index) =>
//                   <View key={`field-${fields.text}${index->Int.toString}`}>
//                     <Space />
//                     {switch field {
//                     | "email" =>
//                       <CustomInput
//                         state={email->Option.getOr("")}
//                         setState={handlePressEmail}
//                         placeholder=localeObject.emailLabel
//                         keyboardType=#"email-address"
//                         borderBottomLeftRadius=borderRadius
//                         borderBottomRightRadius=borderRadius
//                         borderTopLeftRadius=borderRadius
//                         borderTopRightRadius=borderRadius
//                         borderTopWidth=borderWidth
//                         borderBottomWidth=borderWidth
//                         borderLeftWidth=borderWidth
//                         borderRightWidth=borderWidth
//                         isValid=isEmailValidForFocus
//                         onFocus={_ => {
//                           setEmailIsFocus(_ => true)
//                         }}
//                         onBlur={_ => {
//                           setEmailIsFocus(_ => false)
//                         }}
//                         textColor=component.color
//                       />

//                     | "name" =>
//                       <CustomInput
//                         state={name->Option.getOr("")}
//                         setState={handlePressName}
//                         placeholder=localeObject.fullNameLabel
//                         keyboardType=#default
//                         isValid=isNameValidForFocus
//                         onFocus={_ => {
//                           setNameIsFocus(_ => true)
//                         }}
//                         onBlur={_ => {
//                           setNameIsFocus(_ => false)
//                         }}
//                         textColor=component.color
//                         borderBottomLeftRadius=borderRadius
//                         borderBottomRightRadius=borderRadius
//                         borderTopLeftRadius=borderRadius
//                         borderTopRightRadius=borderRadius
//                         borderTopWidth=borderWidth
//                         borderBottomWidth=borderWidth
//                         borderLeftWidth=borderWidth
//                         borderRightWidth=borderWidth
//                       />

//                     | "country" =>
//                       <CustomPicker
//                         value=country
//                         setValue=onChangeCountry
//                         borderBottomLeftRadius=borderRadius
//                         borderBottomRightRadius=borderRadius
//                         borderBottomWidth=borderWidth
//                         items=countryData
//                         placeholderText=localeObject.countryLabel
//                       />

//                     | "State" =>
//                       switch statesJson {
//                       | Some(states) =>
//                         <CustomPicker
//                           value=state
//                           setValue=onChangeState
//                           borderBottomLeftRadius=borderRadius
//                           borderBottomRightRadius=borderRadius
//                           borderBottomWidth=borderWidth
//                           items={states->getStateData}
//                           placeholderText=localeObject.stateLabel
//                         />
//                       | None => React.null
//                       }

//                     | "bank" =>
//                       <CustomPicker
//                         value=selectedBank
//                         setValue=onChangeBank
//                         borderBottomLeftRadius=borderRadius
//                         borderBottomRightRadius=borderRadius
//                         borderBottomWidth=borderWidth
//                         items=bankData
//                         placeholderText=localeObject.bankLabel
//                       />

//                     | "blik_code" =>
//                       <CustomInput
//                         state={blikCode->Option.getOr("")}
//                         setState={onChangeBlikCode}
//                         borderBottomLeftRadius=borderRadius
//                         borderBottomRightRadius=borderRadius
//                         borderBottomWidth=borderWidth
//                         placeholder="000-000"
//                         keyboardType=#numeric
//                         maxLength=Some(7)
//                       />
//                     | "Address_Line_1" =>
//                       <CustomInput
//                         state={address->Option.getOr("")}
//                         setState={handleAddress1}
//                         placeholder="Address Line 1"
//                         keyboardType=#default
//                         textColor=component.color
//                         borderBottomLeftRadius=borderRadius
//                         borderBottomRightRadius=borderRadius
//                         borderTopLeftRadius=borderRadius
//                         borderTopRightRadius=borderRadius
//                         borderTopWidth=borderWidth
//                         borderBottomWidth=borderWidth
//                         borderLeftWidth=borderWidth
//                         borderRightWidth=borderWidth
//                       />

//                     | "Address_Line_2" =>
//                       <CustomInput
//                         state={address2->Option.getOr("")}
//                         setState={handleAddress2}
//                         placeholder="Address Line 2"
//                         keyboardType=#default
//                         textColor=component.color
//                         borderBottomLeftRadius=borderRadius
//                         borderBottomRightRadius=borderRadius
//                         borderTopLeftRadius=borderRadius
//                         borderTopRightRadius=borderRadius
//                         borderTopWidth=borderWidth
//                         borderBottomWidth=borderWidth
//                         borderLeftWidth=borderWidth
//                         borderRightWidth=borderWidth
//                       />
//                     | "City" =>
//                       <CustomInput
//                         state={city->Option.getOr("")}
//                         setState={handlecity}
//                         placeholder="City"
//                         keyboardType=#default
//                         textColor=component.color
//                         borderBottomLeftRadius=borderRadius
//                         borderBottomRightRadius=borderRadius
//                         borderTopLeftRadius=borderRadius
//                         borderTopRightRadius=borderRadius
//                         borderTopWidth=borderWidth
//                         borderBottomWidth=borderWidth
//                         borderLeftWidth=borderWidth
//                         borderRightWidth=borderWidth
//                       />
//                     | "account_type" =>
//                       <>
//                         <CustomPicker
//                           value=account
//                           setValue=onChangeAccountType
//                           borderBottomLeftRadius=borderRadius
//                           borderBottomRightRadius=borderRadius
//                           borderBottomWidth=borderWidth
//                           items=accountTypes
//                           placeholderText="Account Type"
//                         />
//                         <Space />
//                         <ClickableTextElement
//                           disabled={false}
//                           initialIconName="checkboxClicked"
//                           updateIconName=Some("checkboxNotClicked")
//                           text=" Save this bank Details for faster payments"
//                           isSelected=isNicknameSelected
//                           setIsSelected=setIsNicknameSelected
//                           textType={ModalText}
//                           disableScreenSwitch=true
//                         />
//                         <Space />
//                         <Space />
//                         <TextWrapper text="Billing Address" textType=SubheadingBold />
//                         <Space />
//                       </>

//                     | "postal_code" =>
//                       <CustomInput
//                         state={postalCode->Option.getOr("")}
//                         setState={onChangePostalCode}
//                         borderBottomLeftRadius=borderRadius
//                         borderBottomRightRadius=borderRadius
//                         borderBottomWidth=borderWidth
//                         placeholder="Postal Code"
//                         keyboardType=#numeric
//                         maxLength=Some(120)
//                       />

//                     | "account_number" =>
//                       <CustomInput
//                         state={accountnum->Option.getOr("")}
//                         setState={handlePressAccNum}
//                         placeholder="Account Number"
//                         borderBottomLeftRadius=borderRadius
//                         borderBottomRightRadius=borderRadius
//                         borderBottomWidth=borderWidth
//                         maxLength=Some(12)
//                         keyboardType=#numeric
//                       />
//                     | "routing_number" =>
//                       <CustomInput
//                         state={routingnum->Option.getOr("")}
//                         setState={handlePressRouNum}
//                         placeholder="Routing Number"
//                         keyboardType=#numeric
//                         borderBottomLeftRadius=borderRadius
//                         borderBottomRightRadius=borderRadius
//                         borderBottomWidth=borderWidth
//                         maxLength=Some(9)
//                       />

//                     | _ => React.null
//                     }}
//                   </View>
//                 )
//                 ->React.array}
//                 <Space />
//                 // <RedirectionText />
//                 {switch paymentMethod {
//                 | "ach" => React.null
//                 | _ => <RedirectionText />
//                 }}
//               </>
//         }
//       </ErrorBoundary>
//       <Space height=5. />
//     </>}
//   </React.Fragment>
// }

// let mandate_data =
//   [
//     (
//       "customer_acceptance",
//       [
//         ("acceptance_type", "online"->JSON.Encode.string),
//         ("accepted_at", Date.now()->Date.fromTime->Date.toISOString->JSON.Encode.string),
//         (
//           "online",
//           [
//             (
//               "ip_address",
//               nativeProp.hyperParams.ip->Option.getOr("0.0.0.0")->JSON.Encode.string,
//             ),
//             (
//               "user_agent",
//               nativeProp.hyperParams.userAgent->Option.getOr("Unknown")->JSON.Encode.string,
//             ),
//           ]
//           ->Dict.fromArray
//           ->JSON.Encode.object,
//         ),
//       ]
//       ->Dict.fromArray
//       ->JSON.Encode.object,
//     ),
//     (
//       "mandate_type",
//       [
//         (
//           "multi_use",
//           [
//             ("amount", 1000->JSON.Encode.int),
//             ("currency", "USD"->JSON.Encode.string),
//             ("start_date", "2024-04-21T00:00:00Z"->JSON.Encode.string),
//             ("end_date", "2024-05-21T00:00:00Z"->JSON.Encode.string),
//             (
//               "metadata",
//               [("frequency", "13"->JSON.Encode.string)]
//               ->Dict.fromArray
//               ->JSON.Encode.object,
//             ),
//           ]
//           ->Dict.fromArray
//           ->JSON.Encode.object,
//         ),
//       ]
//       ->Dict.fromArray
//       ->JSON.Encode.object,
//     ),
//   ]
//   ->Dict.fromArray
//   ->JSON.Encode.object
// Console.log2("mandate_data", mandate_data)

