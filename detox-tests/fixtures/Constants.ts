type card = {
    cardNumber: string,
    expiryDate: string,
    cvc: string,
}

export const profileId = process.env.PROFILE_ID
export const netceteraTestCard = { cardNumber: "5267648608924299", expiryDate: "04/44", cvc: "123" }
export const visaSandboxCard = { cardNumber: "4242424242424242", expiryDate: "04/44", cvc: "123" }
export const LAUNCH_PAYMENT_SHEET_BTN_TEXT = "Launch Payment Sheet"
export const SAVED_PAYMENT_SHEET_INDICATORS = {
    ADD_NEW_PAYMENT_METHOD_TEXT: "Add new payment method",
    TITLE_TEXT: "Payment methods",
    SAVED_CARD_PATTERN: "••••",
} as const;

export const NORMAL_PAYMENT_SHEET_INDICATORS = {
    CARD_DETAILS_TEXT: "Card Details",
    CARD_NUMBER_PLACEHOLDER: "1234 1234 1234 1234",
    TITLE_TEXT: "Select payment method",
    OR_PAY_USING_TEXT: "Or pay using",
} as const;

export const TIMEOUT_CONFIG = {
    IS_CI: process.env.CI === 'true' || process.env.GITHUB_ACTIONS === 'true',

    BASE: {
        DEFAULT: 15000,
        LONG: 30000,
        NAVIGATION_WAIT: 5000,
        UI_STABILIZATION: 3000,
        ELEMENT_SEARCH: 8000,
        PAYMENT_PROCESSING: 3000,
    },

    CI_MULTIPLIER: 1.5,

    get: function (timeoutKey: keyof typeof TIMEOUT_CONFIG.BASE): number {
        return this.BASE[timeoutKey];
    }
} as const;
