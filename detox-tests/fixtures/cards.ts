

export type CardDetails = {
    cardNumber: string;
    cardScheme: string;
    cvc: string;
    expiryMonth: string;
    expiryYear: string;
    expiryDate: string;
};

type ConnectorCards = {
    successCard: CardDetails;
    threeDSCard?: CardDetails;
    invalidCard: CardDetails;
    [key: string]: CardDetails | undefined;
};

// Helper to create card with computed expiryDate
const createCard = (
    cardNumber: string,
    cardScheme: string,
    cvc: string,
    expiryMonth: string,
    expiryYear: string,
): CardDetails => ({
    cardNumber,
    cardScheme,
    cvc,
    expiryMonth,
    expiryYear,
    expiryDate: `${expiryMonth}/${expiryYear}`,
});

// STRIPE CARDS
export const stripeCards: ConnectorCards = {
    successCard: createCard('4242424242424242', 'Visa', '123', '12', '30'),
    invalidCard: createCard('4000000000000002', 'Visa', '123', '12', '30'),
    threeDSCard: createCard('4000000000003220', 'Visa', '123', '12', '30'),
    unionPay19: createCard('6205500000000000004', 'UnionPay', '123', '12', '30'),
    masterCard16: createCard('5555555555554444', 'MasterCard', '123', '12', '30'),
    amexCard15: createCard('378282246310005', 'American Express', '1234', '12', '30'),
    dinersClubCard14: createCard('36227206271667', 'Diners Club', '123', '12', '30'),
    declinedCard: createCard('4000000000000002', 'Visa', '123', '12', '30'),
    insufficientFundsCard: createCard('4000000000009995', 'Visa', '123', '12', '30'),
};

// NETCETERA 3DS CARDS
export const netceteraCards: ConnectorCards = {
    successCard: createCard('5267648608924299', 'MasterCard', '123', '04', '44'),
    challengeTestCard: createCard('348638267931507', 'American Express', '1234', '12', '30'),
    frictionlessTestCard: createCard('4929251897047956', 'Visa', '123', '12', '30'),
    invalidCard: createCard('4000000000000002', 'Visa', '123', '12', '30'),
};

// TRUSTPAY CARDS
const trustpayCardsDefaultData = {
    cardScheme: 'Visa',
    cvc: '123',
    expiryMonth: '12',
    expiryYear: '30',
};

export const trustpayCards: ConnectorCards = {
    successCard: {
        cardNumber: '4200000000000000',
        ...trustpayCardsDefaultData,
        expiryDate: '12/30',
    },
    threeDSCard: {
        cardNumber: '4200000000000067',
        ...trustpayCardsDefaultData,
        expiryDate: '12/30',
    },
    invalidCard: {
        cardNumber: '4000000000000002',
        ...trustpayCardsDefaultData,
        expiryDate: '12/30',
    },
};

// CYBERSOURCE CARDS
const cybersourceCardsDefaultData = {
    cardScheme: 'Visa',
    cvc: '123',
    expiryMonth: '12',
    expiryYear: '30',
};

export const cybersourceCards: ConnectorCards = {
    successCard: {
        cardNumber: '4242424242424242',
        ...cybersourceCardsDefaultData,
        expiryDate: '12/30',
    },
    invalidCard: {
        cardNumber: '4000000000000002',
        ...cybersourceCardsDefaultData,
        expiryDate: '12/30',
    },
};

// BANK OF AMERICA CARDS
const bankOfAmericaCardsDefaultData = {
    cardScheme: 'Visa',
    cvc: '123',
    expiryMonth: '12',
    expiryYear: '30',
};

export const bankOfAmericaCards: ConnectorCards = {
    successCard: {
        cardNumber: '4242424242424242',
        ...bankOfAmericaCardsDefaultData,
        expiryDate: '12/30',
    },
    invalidCard: {
        cardNumber: '4000000000000002',
        ...bankOfAmericaCardsDefaultData,
        expiryDate: '12/30',
    },
};

// REDSYS CARDS (3DS specific)
const redsysCardsDefaultData = {
    cardScheme: 'Visa',
    cvc: '123',
    expiryMonth: '12',
    expiryYear: '30',
};

export const redsysCards = {
    threedsInvokeChallengeTestCard: {
        cardNumber: '4918019199883839',
        ...redsysCardsDefaultData,
        expiryDate: '12/30',
    },
    threedsInvokeFrictionlessTestCard: {
        cardNumber: '4918019160034602',
        ...redsysCardsDefaultData,
        expiryDate: '12/30',
    },
    challengeTestCard: {
        cardNumber: '4548817212493017',
        ...redsysCardsDefaultData,
        expiryDate: '12/30',
    },
    frictionlessTestCard: {
        cardNumber: '4548814479727229',
        ...redsysCardsDefaultData,
        expiryDate: '12/30',
    },
    successCard: {
        cardNumber: '4548814479727229',
        ...redsysCardsDefaultData,
        expiryDate: '12/30',
    },
    invalidCard: {
        cardNumber: '4000000000000002',
        ...redsysCardsDefaultData,
        expiryDate: '12/30',
    },
};

// ADYEN CARDS
export const adyenCards: ConnectorCards = {
    successCard: createCard('4917610000000000', 'Visa', '123', '12', '30'),
    invalidCard: createCard('4000000000000002', 'Visa', '123', '12', '30'),
    threeDSCard: createCard('4917610000000000', 'Visa', '123', '12', '30'),
};

// VALIDATION TEST CARDS (Generic)
export const validationTestCards = {
    invalidNumber: createCard('1234567890123456', 'Unknown', '123', '04', '44'),
    incompleteNumber: createCard('4242424242', 'Visa', '123', '04', '44'),
    pastExpiry: createCard('4242424242424242', 'Visa', '123', '01', '20'),
    invalidMonth: createCard('4242424242424242', 'Visa', '123', '13', '25'),
    incompleteCvv: createCard('4242424242424242', 'Visa', '12', '04', '44'),
    shortCvv: createCard('4242424242424242', 'Visa', '1', '04', '44'),
};

// QUICK ACCESS CARDS (for common tests)
export const testCards = {
    visa: stripeCards.successCard,
    mastercard: stripeCards.masterCard16,
    amex: stripeCards.amexCard15,
    netcetera3DS: netceteraCards.successCard,
    invalid: validationTestCards.invalidNumber,
    declined: stripeCards.declinedCard,
};

// CARD BRANDS ENUM
export enum CardBrand {
    VISA = 'Visa',
    MASTERCARD = 'MasterCard',
    AMEX = 'American Express',
    DISCOVER = 'Discover',
    DINERS = 'Diners Club',
    JCB = 'JCB',
    UNIONPAY = 'UnionPay',
}

// GET CARDS BY CONNECTOR
export enum ConnectorName {
    STRIPE = 'stripe',
    NETCETERA = 'netcetera',
    TRUSTPAY = 'trustpay',
    CYBERSOURCE = 'cybersource',
    BANK_OF_AMERICA = 'bank_of_america',
    REDSYS = 'redsys',
    ADYEN = 'adyen',
}

export const getCardsByConnector = (connector: ConnectorName): ConnectorCards => {
    const connectorCardsMap: Record<ConnectorName, ConnectorCards> = {
        [ConnectorName.STRIPE]: stripeCards,
        [ConnectorName.NETCETERA]: netceteraCards,
        [ConnectorName.TRUSTPAY]: trustpayCards,
        [ConnectorName.CYBERSOURCE]: cybersourceCards,
        [ConnectorName.BANK_OF_AMERICA]: bankOfAmericaCards,
        [ConnectorName.REDSYS]: redsysCards,
        [ConnectorName.ADYEN]: adyenCards,
    };
    
    return connectorCardsMap[connector] || stripeCards;
};
