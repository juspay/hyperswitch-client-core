const express = require('express');
const cors = require('cors');
const app = express();
app.use(cors());
app.use(express.static('./dist'));
app.use(express.json());

require('dotenv').config({path: './.env'});

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
    const createPaymentBody = {
      amount: 2999,
      currency: 'USD',
      authentication_type: 'no_three_ds',
      customer_id: 'hyperswitch_demo_id',
      capture_method: 'automatic',
      email: 'abc@gmail.com',
      business_country: 'US',
      billing: {
        address: {
          line1: '1467',
          line2: 'Harrison Street',
          line3: 'Harrison Street',
          city: 'San Fransico',
          state: 'California',
          zip: '94122',
          country: 'PL',
          first_name: 'joseph',
          last_name: 'Doe',
        },
      },
      shipping: {
        address: {
          line1: '1467',
          line2: 'Harrison Street',
          line3: 'Harrison Street',
          city: 'San Fransico',
          state: 'California',
          zip: '94122',
          country: 'PL',
          first_name: 'joseph',
          last_name: 'Doe',
        },
      },
    };

    const profileId = process.env.PROFILE_ID;
    if (profileId) {
      createPaymentBody.profile_id = profileId;
    }

    var paymentIntent = await hyper.paymentIntents.create(createPaymentBody);

    // Send publishable key and PaymentIntent details to client
    res.send({
      publishableKey: process.env.HYPERSWITCH_PUBLISHABLE_KEY,
      clientSecret: paymentIntent.client_secret,
    });
  } catch (err) {
    console.log(err);

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
        body: JSON.stringify({customer_id: 'hyperswitch_sdk_demo_id'}),
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
        body: JSON.stringify({customer_id: 'hyperswitch_sdk_demo_id'}),
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

app.get('/netcetera-sdk-api-key', (req, res) => {
  const apiKey = process.env.NETCETERA_SDK_API_KEY;
  if (apiKey) {
    res.status(200).send({netceteraApiKey: apiKey});
  } else {
    res.status(500).send({error: 'Netcetera SDK API key is missing'});
  }
});

app.listen(5252, () =>
  console.log(`Node server listening at http://localhost:5252`),
);
