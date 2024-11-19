type redirectTypeJson = {
  name: string,
  text: string,
  header: string,
  fields: array<string>,
}
type retrieve = Payment | List

let defaultRedirectType = {
  name: "",
  text: "",
  header: "",
  fields: [],
}

type config = {
  priorityArr: array<string>,
  redirectionList: array<redirectTypeJson>,
}

let defaultConfig = {
  priorityArr: {
    let priorityArr = [
      "card",
      "klarna",
      "afterpay_clearpay",
      "ach",
      "becs",
      "sepa",
      "bacs",
      "crypto",
      "paypal",
      "google_pay",
    ]
    priorityArr->Array.reverse
    priorityArr
  },
  redirectionList: [
    {
      name: "klarna",
      text: "Klarna",
      header: "",
      fields: ["email", "country"],
    },
    {
      name: "afterpay_clearpay",
      text: "AfterPay",
      header: "",
      fields: ["email", "name"],
    },
    {
      name: "affirm",
      text: "Affirm",
      header: "",
      fields: ["email"],
    },
    {
      name: "ali_pay",
      text: "Alipay",
      header: "",
      fields: [],
    },
    {
      name: "eps",
      text: "EPS",
      header: "",
      fields: ["bank"],
    },
    {
      name: "we_chat_pay",
      text: "WeChat Pay",
      header: "",
      fields: [],
    },
    {
      name: "blik",
      text: "Blik",
      header: "",
      fields: ["blik_code"],
    },
    {
      name: "ideal",
      text: "iDEAL",
      header: "",
      fields: [],
    },
    {
      name: "crypto",
      text: "Crypto",
      header: "",
      fields: ["name"],
    },
    {
      name: "trustly",
      text: "Trustly",
      header: "",
      fields: ["country"],
    },
    {
      name: "sofort",
      text: "Sofort",
      header: "",
      fields: [],
    },
    {
      name: "open_banking_pis",
      text: "Open Banking",
      header: "",
      fields: [],
    },
    {
      name: "ach",
      text: "ACH Debit",
      header: "",
      fields: [
        "name",
        "routing_number",
        "account_number",
        "account_type",
        "Address_Line_1",
        "Address_Line_2",
        "country",
        "State",
        "City",
        "postal_code",
      ],
    },
    {
      name: "becs",
      text: "BECS Debit",
      header: "",
      fields: [
        "name",
        "email",
        "account_number",
        "bsb_number",
        // "Address_Line_1",
        // "Address_Line_2",
        // "country",
        // "State",
        // "City",
        // "postal_code",
        // "phone",
      ],
    },
    {
      name: "sepa",
      text: "SEPA Debit",
      header: "",
      fields: ["name", "email", "iban"],
    },
    {
      name: "bacs",
      text: "BACS Debit",
      header: "",
      fields: [
        "country",
        "State",
        "city",
        "name",
        "line1",
        "zip",
        "email",
        "account_number",
        "sort_code",
      ],
    },
    // {
    //   name: "google_pay",
    //   text: "Google Pay",
    //   header: "",
    //   fields: ["name"],
    // },
    // {
    //   name: "apple_pay",
    //   text: "Apple Pay",
    //   header: "",
    //   fields: ["name"],
    // },
  ],
}
