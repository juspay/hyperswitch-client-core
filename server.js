const express = require('express');
const cors = require('cors');
const app = express();
app.use(cors());
app.use(express.static('./dist'));
app.use(express.json());

require('dotenv').config({ path: './.env' });

try {
  var hyper = require('@juspay-tech/hyperswitch-node')(
    process.env.HYPERSWITCH_SECRET_KEY,
  );
} catch (err) {
  console.error('process.env.HYPERSWITCH_SECRET_KEY not found, ', err.message);
  process.exit(0);
}

app.get('/create-payment-intent', async (req, res) => {
  try {
    var paymentIntent = await hyper.paymentIntents.create(
      {
        amount: 6540,
        currency: 'USD',
        // confirm: false,
        // capture_method: 'automatic',
        // capture_on: '2022-09-10T10:11:12Z',
        // amount_to_capture: 6540,
        customer_id: 'StripeCustomer',
        // email: 'guest@example.com',
        // name: 'John Doe',
        // phone: '999999999',
        // profile_id: 'pro_1PEZIEJyHhhZ3WJTVIVM',
        // phone_country_code: '+65',
        // description: 'Its my first payment request',
        // authentication_type: 'three_ds',
        // return_url: 'https://duck.com',
        profile_id: "pro_E6k4XxWE3fVzTIYDMzJa",
        //setup_future_usage: "off_session"
        // billing: {
        //   address: {
        //     line1: '1467',
        //     line2: 'Harrison Street',
        //     line3: 'Harrison Street',
        //     city: 'San Fransico',
        //     state: 'California',
        //     zip: '94122',
        //     country: 'US',
        //     first_name: 'PiX',
        //   },
        // },
        // shipping: {
        //   address: {
        //     line1: '1467',
        //     line2: 'Harrison Street',
        //     line3: 'Harrison Street',
        //     city: 'San Fransico',
        //     state: 'California',
        //     zip: '94122',
        //     country: 'US',
        //     first_name: 'PiX',
        //   },
        // },
        // request_external_three_ds_authentication: true,
        // statement_descriptor_name: 'joseph',
        // statement_descriptor_suffix: 'JS',
        // metadata: {
        //   udf1: 'value1',
        //   new_customer: 'true',
        //   login_date: '2019-09-10T10:11:12Z',
        // }

      });

    // Send publishable key and PaymentIntent details to client
    res.send({
      publishableKey: process.env.HYPERSWITCH_PUBLISHABLE_KEY,
      clientSecret: paymentIntent.client_secret,
    });
  } catch (err) {
    return res.status(400).send({
      error: {
        message: err.message,
      },
    });
  }
});

app.get('/create-ephemeral-key', async (req, res) => {
  try {
    const response = await fetch(
      `https://sandbox.hyperswitch.io/ephemeral_keys`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'api-key': process.env.HYPERSWITCH_SECRET_KEY,
        },
        body: JSON.stringify({ customer_id: "hyperswitch_sdk_demo_id" }),
      },
    );
    const ephemeralKey = await response.json();

    res.send({
      ephemeralKey: ephemeralKey.secret,
    });
  } catch (err) {
    return res.status(400).send({
      error: {
        message: err.message,
      },
    });
  }
});

app.listen(5252, () =>
  console.log(`Node server listening at http://localhost:5252`),
);
