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

app.get('/create-auth-intent', async (req, res) => {
  let payload = {
    publishableKey: process.env.HYPERSWITCH_PUBLISHABLE_KEY,
    clientSecret: 'set_client_secret_from_create_auth_intent',
  };

  res.json(payload);
});

app.get('/authentication', async (req, res) => {
  let payload = {
    amount: 2999,
    currency: 'EUR',
    acquirer_details: {
      acquirer_merchant_id: '12134',
      acquirer_bin: '438309',
      merchant_country_code: '004',
    },
    authentication_connector: 'juspaythreedsserver',
  };

  const url =
    process.env.HYPERSWITCH_SERVER_URL || process.env.HYPERSWITCH_SANDBOX_URL;

  const apiResponse = await fetch(`${url}/authentication`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Accept: 'application/json',
      'X-Profile-Id': process.env.PROFILE_ID,
      'api-key': process.env.HYPERSWITCH_SECRET_KEY,
    },
    body: JSON.stringify(payload),
  });

  const authIntent = await apiResponse.json();

  if (authIntent.error) {
    console.error('Error - ', authIntent.error);
    throw new Error(authIntent.error.message ?? 'Something went wrong.');
  }

  let response = {
    authentication_id: authIntent.authentication_id,
  };

  res.json(response);
});

app.get('/authentication/:authSession_id/eligibility', async (req, res) => {
  let authSessionId = req.params.authSession_id;

  let payload = {
    payment_method: 'card',
    payment_method_data: {
      card: {
        card_number: '5306889942833340',
        card_exp_month: '10',
        card_exp_year: '24',
        card_holder_name: 'joseph Doe',
        card_cvc: '123',
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
        first_name: 'PiX',
      },
      phone: {
        number: '123456789',
        country_code: '12',
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
        first_name: 'PiX',
      },
      phone: {
        number: '123456789',
        country_code: '12',
      },
    },
    email: 'sahkasssslplanet@gmail.com',
    browser_information: {
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
      ip_address: '115.99.183.2',
    },
  };

  const url =
    process.env.HYPERSWITCH_SERVER_URL || process.env.HYPERSWITCH_SANDBOX_URL;

  const apiResponse = await fetch(
    `${url}/authentication/${authSessionId}/eligibility`,
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        accept: 'application/json',
        'api-key': process.env.HYPERSWITCH_SECRET_KEY,
      },
      body: JSON.stringify(payload),
    },
  );

  const authEligibility = await apiResponse.json();

  if (authEligibility.error) {
    let response = {
      authentication_id: authSessionId,
      success: false,
      error: authEligibility.error.message ?? 'Something went wrong.',
    };
    res.json(response);
    return;
  }

  let response = {
    authentication_id: authEligibility.authentication_id,
    success: true,
  };

  res.json(response);
});

app.post('/authentication/:authSession_id/authenticate', async (req, res) => {
  let authSessionId = req.params.authSession_id;

  let payload = req.body;

  const url =
    process.env.HYPERSWITCH_SERVER_URL || process.env.HYPERSWITCH_SANDBOX_URL;

  const apiResponse = await fetch(
    `${url}/authentication/${authSessionId}/authenticate`,
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        accept: 'application/json',
        'api-key': process.env.HYPERSWITCH_SECRET_KEY,
      },
      body: JSON.stringify(payload),
    },
  );

  const authResult = await apiResponse.json();

  if (authResult.error) {
    let response = {
      authentication_id: authSessionId,
      success: false,
      error: authResult.error.message ?? 'Something went wrong.',
    };
    res.json(response);
    return;
  }

  res.json(authResult);
});

app.listen(PORT, () =>
  console.info(`Node server listening at http://localhost:${PORT}`),
);
