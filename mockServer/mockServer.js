const express = require('express');
const cors = require('cors');
require('dotenv').config();
const authRoutes = require('./authenticationRoutes');
const paymentMethodRoutes = require('./paymentMethodRoutes');
const logger = require('./logger');
const {
  makeHyperswitchRequest,
  HYPERSWITCH_BASE_URL
} = require('./utils');

const app = express();
const PORT = process.env.PORT || 5252;

let mockData;
try {
  mockData = require("./mockData.js");
} catch (_) {
  mockData = {
    paymentIntentBody: {}
  };
}

app.use(cors());
app.use(express.json());
app.use(authRoutes);
app.use(paymentMethodRoutes);

const HYPERSWITCH_SECRET_KEY = process.env.HYPERSWITCH_SECRET_KEY;
const HYPERSWITCH_PUBLISHABLE_KEY = process.env.HYPERSWITCH_PUBLISHABLE_KEY;
const PROFILE_ID = process.env.PROFILE_ID;

if (!HYPERSWITCH_SECRET_KEY || !HYPERSWITCH_PUBLISHABLE_KEY) {
  logger.warn('Missing required environment variables');
  logger.warn('HYPERSWITCH_PUBLISHABLE_KEY: ' + !!HYPERSWITCH_PUBLISHABLE_KEY);
  logger.warn('HYPERSWITCH_SECRET_KEY: ' + !!HYPERSWITCH_SECRET_KEY);
  logger.warn('PROFILE_ID: ' + !!PROFILE_ID);
  // logger.warn('NETCETERA_SDK_API_KEY: ' + !!process.env.NETCETERA_SDK_API_KEY);
  process.exit(1);
}

app.get('/health', (req, res) => {
  res.json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    environment: {
      baseUrl: HYPERSWITCH_BASE_URL,
      hasSecretKey: !!HYPERSWITCH_SECRET_KEY,
      hasPublishableKey: !!HYPERSWITCH_PUBLISHABLE_KEY,
    },
  });
});

app.get('/create-payment-intent', async (req, res) => {
  try {
    const paymentData = {
      ...mockData.paymentIntentBody,
      amount: 100,
      currency: 'USD',
    };

    if (process.env.PROFILE_ID) {
      paymentData.profile_id = process.env.PROFILE_ID;
    }

    logger.debug('Creating payment intent with data', paymentData);

    const response = await makeHyperswitchRequest('/payments', {
      method: 'POST',
      body: JSON.stringify(paymentData),
    });

    logger.debug('Payment intent created successfully', {
      payment_id: response.data.payment_id,
    });

    res.json({
      publishableKey: HYPERSWITCH_PUBLISHABLE_KEY,
      clientSecret: response.data.client_secret,
    });
  } catch (error) {
    logger.error(
      'Error creating payment intent',
      error.response?.data || error.message,
    );

    res.status(error.response?.status || 500).json({
      error: 'Failed to create payment intent',
      details: error.response?.data || error.message,
      timestamp: new Date().toISOString(),
    });
  }
});

app.post('/create-payment-intent', async (req, res) => {
  try {
    const paymentData = {
      ...mockData.paymentIntentBody,
      ...req.body,
    };

    if (process.env.PROFILE_ID) {
      paymentData.profile_id = process.env.PROFILE_ID;
    }

    logger.debug('Creating payment intent with data', paymentData);

    const response = await makeHyperswitchRequest('/payments', {
      method: 'POST',
      body: JSON.stringify(paymentData),
    });

    logger.debug('Payment intent created successfully', {
      payment_id: response.data.payment_id,
    });

    res.json({
      publishableKey: HYPERSWITCH_PUBLISHABLE_KEY,
      clientSecret: response.data.client_secret,
    });
  } catch (error) {
    logger.error(
      'Error creating payment intent',
      error.response?.data || error.message,
    );

    res.status(error.response?.status || 500).json({
      error: 'Failed to create payment intent',
      details: error.response?.data || error.message,
      timestamp: new Date().toISOString(),
    });
  }
});

app.use((req, res) => {
  res.status(404).json({
    error: 'Endpoint not found',
    path: req.path,
    method: req.method,
    timestamp: new Date().toISOString(),
  });
});

app.use((error, req, res, next) => {
  logger.error('Unhandled error', error);
  res.status(500).json({
    error: 'Internal server error',
    timestamp: new Date().toISOString(),
  });
});

app
  .listen(PORT, '0.0.0.0', () => {
    logger.info(`🚀 Hyperswitch server running on port ${PORT}`);
    logger.info(`📋 Health check: http://localhost:${PORT}/health`);
    logger.info(
      `💳 Create payment: POST http://localhost:${PORT}/create-payment-intent`,
    );
    logger.info(`🌐 Environment: ${HYPERSWITCH_BASE_URL}`);
    logger.info(
      `📱 Server accessible from Android simulator via 10.0.2.2:${PORT}`,
    );
  })
  .on('error', err => {
    if (err.code === 'EADDRINUSE') {
      logger.error(`❌ Port ${PORT} is already in use!`);
      process.exit(1);
    } else {
      logger.error('Server error:', err);
      process.exit(1);
    }
  });

module.exports = app;
