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
    var paymentIntent = await hyper.paymentIntents.create({
      amount: 12999,
      currency: 'USD',
      profile_id: 'pro_iwkbcjQlzbckggkI4vpN',
      customer_id: 'cus_x2elbRbuiRyQfEO1ae2B',
      setup_future_usage: 'off_session',
      authentication_type: 'no_three_ds',
      request_external_three_ds_authentication: true,
      billing: {
        address: {
          line1: '1467',
          line2: 'Harrison Street',
          line3: 'Harrison Street',
          city: 'San Fransico',
          state: 'California',
          zip: '94122',
          country: 'US',
          // first_name: 'PiX',
          // last_name: "grgv",
        },
      },
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

app.listen(5252, () =>
  console.log(`Node server listening at http://localhost:5252`),
);
