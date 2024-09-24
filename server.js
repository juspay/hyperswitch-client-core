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
      amount: 2999,
      currency: 'USD',
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
        body: JSON.stringify({customer_id: "hyperswitch_sdk_demo_id"}),
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
