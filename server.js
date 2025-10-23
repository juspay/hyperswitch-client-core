const express = require('express');
const cors = require('cors');
const app = express();
app.use(cors());
app.use(express.static('./dist'));
app.use(express.json());

require('dotenv').config({path: './.env'});

const PORT = 5252;
let cachedResponseForAutomation = null;

async function createPaymentIntent(request) {
  try {
    const url =
      process.env.HYPERSWITCH_SERVER_URL || process.env.HYPERSWITCH_SANDBOX_URL;
    const apiResponse = await fetch(`${url}/payments`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Accept: 'application/json',
        'api-key': process.env.HYPERSWITCH_SECRET_KEY,
      },
      body: JSON.stringify(request),
    });

    const paymentIntent = await apiResponse.json();

    if (paymentIntent.error) {
      console.error('Error - ', paymentIntent.error);
      throw new Error(paymentIntent.error.message ?? 'Something went wrong.');
    }

    return paymentIntent;
  } catch (error) {
    console.error('Failed to create payment intent:', error);
    throw new Error(
      error.message ||
        'Unexpected error occurred while creating payment intent.',
    );
  }
}

async function createPaymentHandler(req, res, createPaymentBody) {
  if (req.method === 'GET' && cachedResponseForAutomation) {
    return res.json(cachedResponseForAutomation);
  }
  try {
    const profileId = process.env.PROFILE_ID;
    if (profileId) createPaymentBody.profile_id = profileId;

    const paymentIntent = await createPaymentIntent(createPaymentBody);

    let payload = {
      publishableKey: process.env.HYPERSWITCH_PUBLISHABLE_KEY,
      clientSecret: paymentIntent.client_secret,
    };

    if (req.method === 'POST') cachedResponseForAutomation = payload;

    return res.json(payload);
  } catch (err) {
    console.error(err);
    return res.status(400).json({error: {message: err.message}});
  }
}

app.get('/create-payment-intent', async (req, res) => {
  const createPaymentBody = {
    amount: 2999,
    currency: 'USD',
    authentication_type: 'no_three_ds',
    customer_id: 'hyperswitch_demo_customer_id',
    capture_method: 'automatic',
    email: 'abc@gmail.com',
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
      },
    },
  };

  createPaymentHandler(req, res, createPaymentBody);
});

app.post('/create-payment-intent', async (req, res) => {
  const createPaymentBody = req.body;
  createPaymentHandler(req, res, createPaymentBody);
});

app.get('/create-ephemeral-key', async (req, res) => {
  try {
    const response = await fetch(
      `${process.env.HYPERSWITCH_SANDBOX_URL}/ephemeral_keys`,
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
      `${process.env.HYPERSWITCH_SANDBOX_URL}/payment_methods`,
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

app.listen(PORT, () =>
  console.info(`Node server listening at http://localhost:${PORT}`),
);
