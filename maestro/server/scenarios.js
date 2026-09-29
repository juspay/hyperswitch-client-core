// Payment-intent scenarios for the Maestro end-to-end suite, served by e2e-server.js. Committed; must
// never hold secrets.
//
// Activate one with `POST /scenario {"name": "<key>"}` on the e2e server. `GET /create-payment-intent`
// then builds the intent in this order (later steps win; objects are replaced, not deep-merged):
//   amount 100 (+ HYPERSWITCH_CUSTOMER_ID) -> `body` -> customer (`customer` / `customerEnv`)
//   -> `removeKeys` -> `account`'s profile id
// and signs it with `account`'s keys. A scenario without `body` leaves the intent to mockServer.js,
// unchanged.
//
//   account     DEFAULT uses HYPERSWITCH_SECRET_KEY / HYPERSWITCH_PUBLISHABLE_KEY / PROFILE_ID.
//               Any other name reads HS_<NAME>_PROFILE_ID, and HS_<NAME>_SECRET_KEY /
//               HS_<NAME>_PUBLISHABLE_KEY when the profile lives in a different merchant account.
//   body        Object (or function of {customerId}) merged over the defaults.
//   removeKeys  Dotted paths deleted after merging, e.g. 'billing' or 'billing.email'.
//   customer    'fresh': a new customer id is generated each time the scenario is set and reused for
//               every intent until the next POST /scenario (save a card, relaunch, pay with it).
//               'none': guest checkout (customer_id removed).
//   customerEnv Name of a .env variable holding a customer id to use instead.
//   seedCards   With customer 'fresh': cards saved for that customer when the scenario is set, by
//               confirming one server-side test payment per card (connector test cards only).
//               `setupOnly: true` on a card saves it with a zero-amount setup mandate instead.
//   defaultLast4 After seeding, marks the saved card with these last 4 digits as the default.
//   afterCreate 'cancel': cancel the intent before handing it to the app.
//   intentError {status, body}: GET /create-payment-intent fails with this instead of calling the API.

// Everything the suite relies on, so it does not depend on each machine's gitignored mockData.js.
const base = {
  currency: 'USD',
  confirm: false,
  capture_method: 'automatic',
  authentication_type: 'no_three_ds',
  setup_future_usage: 'on_session',
  email: 'user@gmail.com',
  description: 'Maestro E2E',
  order_details: [{product_name: 'Test product', quantity: 1, amount: 100}],
  billing: {
    address: {
      line1: '1467',
      line2: 'Harrison Street',
      line3: 'Harrison Street',
      city: 'San Fransico',
      state: 'California',
      zip: '94122',
      country: 'GB',
      first_name: 'joseph',
      last_name: 'Doe',
    },
    phone: {number: '8056594427', country_code: '+91'},
  },
  shipping: {
    address: {
      line1: 'sdsdfsdf',
      line2: 'hsgdbhd',
      line3: 'alsksoe',
      city: 'Banglore',
      state: 'California',
      zip: '571201',
      country: 'US',
      first_name: 'John',
      last_name: 'Doe',
    },
    phone: {number: '123456789', country_code: '+1'},
  },
};

module.exports = {
  default: {
    account: 'DEFAULT',
    description: 'No changes: mockServer.js creates the intent (mockData and .env), as with yarn server.',
  },
  guest: {
    account: 'DEFAULT',
    customer: 'none',
    body: base,
    removeKeys: ['setup_future_usage'],
    description: 'Guest checkout: no customer, so no saved methods and no save checkbox.',
  },
  saved_card: {
    account: 'DEFAULT',
    customer: 'fresh',
    body: base,
    seedCards: [{card_number: '4242424242424242', card_cvc: '123'}],
    description: 'Fresh customer with one saved Visa 4242 (saved-methods screen first).',
  },
  saved_card_multiple: {
    account: 'DEFAULT',
    customer: 'fresh',
    body: base,
    seedCards: [
      {card_number: '4242424242424242', card_cvc: '123'},
      {card_number: '5555555555554444', card_cvc: '123'},
    ],
    defaultLast4: '4242',
    description: 'Fresh customer with a saved Visa 4242 (default) and Mastercard 4444 (last used).',
  },
  no_three_ds: {
    account: 'DEFAULT',
    customer: 'fresh',
    body: base,
    description: 'Card payment without 3DS.',
  },
  three_ds: {
    account: 'DEFAULT',
    customer: 'fresh',
    body: {...base, authentication_type: 'three_ds'},
    description: '3DS requested; the connector test card decides frictionless vs challenge.',
  },
};
