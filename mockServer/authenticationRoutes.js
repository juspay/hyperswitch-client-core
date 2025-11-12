const express = require('express');
const logger = require('./logger');
const {makeHyperswitchRequest} = require('./utils');
const router = express.Router();

const PROFILE_ID = process.env.PROFILE_ID;

router.get('/netcetera-sdk-api-key', (req, res) => {
  const apiKey = process.env.NETCETERA_SDK_API_KEY;

  if (!!apiKey) {
    logger.info('Netcetera SDK API key retrieved successfully');
    res.status(200).json({
      netceteraApiKey: apiKey,
      timestamp: new Date().toISOString(),
    });
  } else {
    logger.error('Netcetera SDK API key is missing from environment variables');
    res.status(500).json({
      error: 'Not Configured',
      timestamp: new Date().toISOString(),
    });
  }
});

router.post('/create-authentication', async (req, res) => {
  try {
    const authenticationData = {
      amount: 1000,
      currency: 'USD',
      customer_details: {
        id: process.env.CTP_CUSTOMER_ID,
        email: process.env.CTP_CUSTOMER_EMAIL,
      },
      authentication_connector: 'ctp_visa',
      profile_id: process.env.PROFILE_ID,
      ...req.body,
    };

    logger.debug('Creating authentication with data', authenticationData);

    const response = await makeHyperswitchRequest('/authentication', {
      method: 'POST',
      body: JSON.stringify(authenticationData),
      headers: {
        'x-feature': 'router-custom-be',
        'x-profile-id': process.env.PROFILE_ID,
      },
    });

    logger.debug('Authentication created successfully', {
      authentication_id: response.data.authentication_id,
    });

    res.json({
      publishableKey: process.env.HYPERSWITCH_PUBLISHABLE_KEY,
      clientSecret: response.data.client_secret,
      profileId: response.data.profile_id,
      authenticationId: response.data.authentication_id,
      merchantId: response.data.merchant_id,
    });
  } catch (error) {
    logger.error('Error creating authentication', error.message);

    res.status(500).json({
      error: 'Failed to create authentication',
      details: error.message,
      timestamp: new Date().toISOString(),
    });
  }
});

router.get('/create-auth-intent', async (req, res) => {
  const payload = {
    publishableKey: process.env.HYPERSWITCH_PUBLISHABLE_KEY,
    clientSecret: 'set_client_secret_from_create_auth_intent',
  };

  logger.info('Auth intent created');
  res.json(payload);
});

router.get('/authentication', async (req, res) => {
  try {
    const authData = {
      amount: 2999,
      currency: 'EUR',
      acquirer_details: {
        acquirer_merchant_id: 'acquirer_merchant_id',
        acquirer_bin: 'acquirer_bin',
        merchant_country_code: 'merchant_country_code',
      },
      authentication_connector: 'authentication_connector',
    };

    logger.debug('Creating authentication session');

    const response = await makeHyperswitchRequest('/authentication', {
      method: 'POST',
      body: JSON.stringify(authData),
      headers: {
        ...(PROFILE_ID && {'X-Profile-Id': PROFILE_ID}),
      },
    });

    logger.info('Authentication session created successfully', {
      authentication_id: response.data.authentication_id,
    });

    res.json({
      authentication_id: response.data.authentication_id,
    });
  } catch (error) {
    logger.error(
      'Error creating authentication session',
      error.response?.data || error.message,
    );

    res.status(error.response?.status || 500).json({
      error: 'Failed to create authentication session',
      details: error.response?.data || error.message,
      timestamp: new Date().toISOString(),
    });
  }
});

router.get('/authentication/:auth-session-id/eligibility', async (req, res) => {
  try {
    const authSessionId = req.params['auth-session-id'];

    const eligibilityData = {
      payment_method: 'card',
      payment_method_data: {
        card: {
          card_number: 'card_number',
          card_exp_month: 'exp',
          card_exp_year: 'year',
          card_holder_name: 'Joseph Doe',
          card_cvc: 'cvc',
        },
      },
    };

    logger.debug('Checking authentication eligibility', {authSessionId});

    const response = await makeHyperswitchRequest(
      `/authentication/${authSessionId}/eligibility`,
      {
        method: 'POST',
        body: JSON.stringify(eligibilityData),
      },
    );

    logger.info('Authentication eligibility check successful', {
      authentication_id: response.data.authentication_id,
    });

    res.json({
      authentication_id: response.data.authentication_id,
      success: true,
    });
  } catch (error) {
    logger.error(
      'Error checking authentication eligibility',
      error.response?.data || error.message,
    );

    res.status(error.response?.status || 500).json({
      error: 'Failed to check authentication eligibility',
      details: error.response?.data || error.message,
      timestamp: new Date().toISOString(),
    });
  }
});

router.post(
  '/authentication/:auth-session-id/authenticate',
  async (req, res) => {
    try {
      const authSessionId = req.params['auth-session-id'];
      const payload = req.body;

      logger.debug('Authenticating session', {authSessionId});

      const response = await makeHyperswitchRequest(
        `/authentication/${authSessionId}/authenticate`,
        {
          method: 'POST',
          body: JSON.stringify(payload),
        },
      );

      logger.info('Authentication successful', {
        authentication_id: authSessionId,
      });

      res.json(response.data);
    } catch (error) {
      logger.error(
        'Error authenticating session',
        error.response?.data || error.message,
      );

      res.status(error.response?.status || 500).json({
        error: 'Failed to authenticate',
        details: error.response?.data || error.message,
        timestamp: new Date().toISOString(),
      });
    }
  },
);

module.exports = router;
