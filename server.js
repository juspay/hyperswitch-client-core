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
const paymentData = {
  currency: "GBP",
  amount: 2999,
  order_details: [
    {
      product_name: "Apple iPhone 15",
      quantity: 1,
      amount: 2999,
    },
  ],
  confirm: false,
  capture_method: "automatic",
  authentication_type: "three_ds",
  customer_id: "hyperswitch_sdk_demo_id232432",
  // setup_future_usage: "off_session",
  email: "hyperswitch_sdk_demo_id@gmail.com",
  request_external_three_ds_authentication: false,
  description: "Hello this is description",
  shipping: {
    address: {
      line1: "1467",
      line2: "Harrison Street",
      line3: "Harrison Street",
      city: "Sydney",
      state: "Sydney",
      zip: "94122",
      country: "FR",
      first_name: "joseph",
      last_name: "Doe",
    },
    phone: {
      number: "8056594427",
      country_code: "+91",
    },
  },
  metadata: {
    udf1: "value1",
    new_customer: "true",
    login_date: "2019-09-10T10:11:12Z",
  },
  billing: {
    address: {
      line1: "1467",
      line2: "Harrison Street",
      line3: "Harrison Street",
      city: "Sydney",
      state: "Sydney",
      zip: "94122",
      country: "FR",
      first_name: "joseph",
      last_name: "Doe",
    },
    phone: {
      number: "8056594427",
      country_code: "+91",
    },
  },
}

const profileId = process.env.HYPERSWITCH_PROFILE_ID;
if (profileId) {
  paymentData.profile_id = profileId;
}


app.get('/create-payment-intent', async (req, res) => {
  try {
    var paymentIntent = await hyper.paymentIntents.create({
      amount: 2999,
      currency: 'USD',
      authentication_type: 'no_three_ds',
      customer_id: 'hyperswitch_demo_id',
      capture_method: 'automatic',
      email: 'pradeepkumar@gmail.com',
      profile_id: process.env.HYPERSWITCH_PROFILE_ID,
      billing: {
        address: {
          line1: '1467',
          line2: 'Harrison Street',
          line3: 'Harrison Street',
          city: 'San Fransico',
          state: 'California',
          zip: '94122',
          country: 'US',
          first_name: 'joseph',
          last_name: 'Doe',
        },
        phone: {
          number: '8056594427',
          country_code: '+91',
        },

        email: 'pradeepKumar@gmail.com',
      },
      shipping: {
        address: {
          line1: '1467',
          line2: 'Harrison Street',
          line3: 'Harrison Street',
          city: 'San Fransico',
          state: 'California',
          zip: '94122',
          country: 'US',
          first_name: 'joseph',
          last_name: 'Doe',
        }
      },
    });

    res.send({
      publishableKey: process.env.HYPERSWITCH_PUBLISHABLE_KEY,
      clientSecret: paymentIntent.client_secret,
    });
  } catch (err) {
    console.log(err)

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

app.get('/payment_methods', async (req, res) => {
  try {
    const response = await fetch(
      `https://sandbox.hyperswitch.io/payment_methods`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'api-key': process.env.HYPERSWITCH_SECRET_KEY,
        },
        body: JSON.stringify({ customer_id: 'hyperswitch_sdk_demo_id' }),
      },
    );
    const json = await response.json();

    res.send({
      customerId: json.customer_id,
      paymentMethodId: json.payment_method_id,
      clientSecret: json.client_secret,
      publishableKey: process.env.HYPERSWITCH_PUBLISHABLE_KEY,
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
