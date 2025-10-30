const express = require('express');
const logger = require('./logger');
const {makeHyperswitchRequest} = require('./utils');
const router = express.Router();

router.get('/create-ephemeral-key', async (req, res) => {
  try {
    logger.debug('Creating ephemeral key');

    const response = await makeHyperswitchRequest('/ephemeral_keys', {
      method: 'POST',
      body: JSON.stringify({customer_id: 'hyperswitch_sdk_demo_id'}),
    });

    logger.info('Ephemeral key created successfully');
    res.json({
      ephemeralKey: response.data.secret,
    });
  } catch (error) {
    logger.error(
      'Error creating ephemeral key',
      error.response?.data || error.message,
    );

    res.status(error.response?.status || 500).json({
      error: 'Failed to create ephemeral key',
      details: error.response?.data || error.message,
      timestamp: new Date().toISOString(),
    });
  }
});

router.get('/payment_methods', async (req, res) => {
  try {
    logger.debug('Fetching payment methods');

    const response = await makeHyperswitchRequest('/payment_methods', {
      method: 'POST',
      body: JSON.stringify({customer_id: 'hyperswitch_sdk_demo_id'}),
    });

    logger.info('Payment methods fetched successfully', {
      payment_method_id: response.data.payment_method_id,
    });

    res.json({
      customerId: response.data.customer_id,
      paymentMethodId: response.data.payment_method_id,
      clientSecret: response.data.client_secret,
      publishableKey: process.env.HYPERSWITCH_PUBLISHABLE_KEY,
    });
  } catch (error) {
    logger.error(
      'Error fetching payment methods',
      error.response?.data || error.message,
    );

    res.status(error.response?.status || 500).json({
      error: 'Failed to fetch payment methods',
      details: error.response?.data || error.message,
      timestamp: new Date().toISOString(),
    });
  }
});

module.exports = router;
