module Types = {
  type environment = [#sandbox | #production]
  type provider = [#visa | #mastercard]
  type brand = [#visa | #mastercard]
  type actionCode = [#SUCCESS | #PENDING_CONSUMER_IDV | #FAILED | #ERROR | #ADD_CARD | #CHANGE_CARD]

  type phoneValue = {
    phoneCode: string,
    phoneNumber: string,
  }

  type clickToPayConfig = {
    dpaId: string,
    environment: environment,
    provider: provider,
    locale?: string,
    cardBrands?: string,
    clientId?: string,
    transactionAmount?: string,
    transactionCurrency?: string,
    timeout?: int,
    debug?: bool,
    recognitionToken?: string,
  }

  type digitalCardData = {descriptorName: option<string>}

  type clickToPayCard = {
    id: string,
    maskedPan: string,
    brand: string,
    expiryMonth?: string,
    expiryYear?: string,
    digitalCardId: string,
    paymentCardDescriptor: string,
    digitalCardData: digitalCardData,
  }

  type userIdentity = {
    value: string,
    @as("type") type_: string,
  }

  type validateResult = {
    actionCode?: actionCode,
    cards?: array<clickToPayCard>,
    requiresOTP?: bool,
    requiresNewCard?: bool,
    maskedValidationChannel?: string,
  }

  type cardData = {
    primaryAccountNumber: string,
    panExpirationMonth: string,
    panExpirationYear: string,
    cardSecurityCode: string,
    cardHolderName?: string,
  }

  type checkoutParams = {
    srcDigitalCardId?: string,
    encryptedCard?: string,
    cardData?: cardData,
    amount: string,
    currency: string,
    orderId: string,
    rememberMe?: bool,
    mobileNumber?: string,
    mobileCountryCode?: string,
  }

  type clickToPayHook = {
    isLoading: bool,
    cards: array<clickToPayCard>,
    config: Nullable.t<clickToPayConfig>,
    initialize: clickToPayConfig => Promise.t<unit>,
    validate: userIdentity => Promise.t<validateResult>,
    authenticate: string => Promise.t<array<clickToPayCard>>,
    checkout: checkoutParams => Promise.t<JSON.t>,
  }
}

let clickToPayPackage = %raw(`
  (() => {
    try {
      return require("@juspay-tech/react-native-hyperswitch-click-to-pay");
    } catch (e) {
      return null;
    }
  })()
`)

module Provider = {
  @react.component
  let make = (~children, ~onCookiesExtracted=?, ~initialCookies=?) => {
    let renderProvider: (
      React.element,
      option<string => unit>,
      option<string>,
    ) => React.element = %raw(`
      (children, onCookiesExtracted, initialCookies) => {
        const pkg = clickToPayPackage;
        if (pkg && pkg.ClickToPayProvider) {
          const React = require('react');
          return React.createElement(
            pkg.ClickToPayProvider,
            {
              children: children,
              onCookiesExtracted: onCookiesExtracted,
              initialCookies: initialCookies,
            }
          );
        }
        return children;
      }
    `)
    renderProvider(children, onCookiesExtracted, initialCookies)
  }
}

let isClickToPayAvailable = %raw(`
  (() => {
    const pkg = clickToPayPackage;
    if (pkg) {
      return true;
    }
    return false;
  })()
`)

let useClickToPay = (): Types.clickToPayHook => {
  %raw(`
    (() => {
      const pkg = clickToPayPackage;
      if (pkg && pkg.useClickToPay) {
        return pkg.useClickToPay();
      }
      // Return a default/no-op implementation
      return {
        isLoading: false,
        cards: [],
        config: null,
        initialize: (_config) => Promise.resolve(),
        validate: (_identity) => Promise.resolve({
          actionCode: undefined,
          cards: undefined,
          requiresOTP: undefined,
          requiresNewCard: undefined,
          maskedValidationChannel: undefined,
        }),
        authenticate: (_otp) => Promise.resolve([]),
        checkout: (_params) => Promise.resolve(null),
      };
    })()
  `)
}
