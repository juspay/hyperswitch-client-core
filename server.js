const express = require('express');
const cors = require('cors');
const app = express();
app.use(cors());
app.use(express.static('./dist'));
app.use(express.json());

require('dotenv').config({path: './.env'});

const PORT = 5252;

async function createPaymentIntent(request) {
  try {
    const url =
      process.env.HYPERSWITCH_SERVER_URL || 'https://sandbox.hyperswitch.io';
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

app.get('/create-payment-intent', async (req, res) => {
  try {
    const createPaymentBody = {
      amount: 2999,
      currency: 'USD',
      authentication_type: 'no_three_ds',
      customer_id: 'hyperswitch_demo_id',
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

    var paymentIntent = await createPaymentIntent(createPaymentBody);

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

app.get('/authenticate', async (req, res) => {
  try {
    const response = await fetch(
      `https://auth.app.hyperswitch.io/api/authenticate`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'api-key': process.env.HYPERSWITCH_SECRET_KEY,
        },
        body: JSON.stringify({
          amount: 100,
          currency: 'PLN',
          return_url: 'https://google.com',
          payment_method: 'card',
          payment_method_data: {
            card: {
              card_number: '5512459816707531',
              card_exp_month: '04',
              card_exp_year: '2029',
              card_holder_name: 'John Smith',
              card_cvc: '238',
              card_network: 'Visa',
            },
          },
          billing: {
            address: {
              line1: '1467',
              line2: 'Harrison Street',
              line3: 'Harrison Street',
              city: 'San Fransico',
              state: 'CA',
              zip: '94122',
              country: 'US',
              first_name: 'John',
              last_name: 'Doe',
            },
            phone: {
              number: '8056594427',
              country_code: '+91',
            },
          },
          browser_info: {
            user_agent:
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.110 Safari/537.36',
            accept_header:
              'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8',
            language: 'nl-NL',
            color_depth: 24,
            screen_height: 723,
            screen_width: 1536,
            time_zone: 0,
            java_enabled: true,
            java_script_enabled: true,
            ip_address: '125.0.0.1',
          },
        }),
      },
    );
    const resp = await response.json();

    res.send({
      publishableKey: process.env.HYPERSWITCH_PUBLISHABLE_KEY,
      clientSecret: resp.client_secret,
    });
  } catch (err) {
    return res.status(400).send({
      error: {
        message: err.message,
      },
    });
  }
});

app.listen(PORT, () =>
  console.log(`Node server listening at http://localhost:${PORT}`),
);
