type fieldType = Email | Country | Name | Bank | BlikCode

type redirectTypeJson = {
  name: string,
  text: string,
  header: string,
  fields: array<fieldType>,
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
    let priorityArr = ["card", "klarna", "afterpay_clearpay", "crypto", "paypal", "google_pay"]
    priorityArr->Array.reverse
    priorityArr
  },
  redirectionList: [
    {
      name: "klarna",
      text: "Klarna",
      header: "",
      fields: [Email, Country],
    },
    {
      name: "afterpay_clearpay",
      text: "AfterPay",
      header: "",
      fields: [Email, Name],
    },
    {
      name: "affirm",
      text: "Affirm",
      header: "",
      fields: [Email],
    },
    {
      name: "ali_pay",
      text: "Alipay",
      header: "",
      fields: [],
    },
    {
      name: "we_chat_pay",
      text: "WeChat Pay",
      header: "",
      fields: [],
    },
    {
      name: "crypto",
      text: "Crypto",
      header: "",
      fields: [Name],
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
