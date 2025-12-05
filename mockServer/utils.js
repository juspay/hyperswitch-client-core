const HYPERSWITCH_SECRET_KEY = process.env.HYPERSWITCH_SECRET_KEY;
const HYPERSWITCH_BASE_URL =
  process.env.HYPERSWITCH_SERVER_URL ||
  process.env.HYPERSWITCH_SANDBOX_URL || 'https://sandbox.hyperswitch.io';

const makeHyperswitchRequest = async (endpoint, options = {}) => {
  const url = `${HYPERSWITCH_BASE_URL}${endpoint}`;
  const config = {
    headers: {
      'Content-Type': 'application/json',
      'api-key': HYPERSWITCH_SECRET_KEY,
    },
    ...options,
  };

  const response = await fetch(url, config);
  const data = await response.json();

  if (!response.ok) {
    const error = new Error(`HTTP ${response.status}`);
    error.response = {status: response.status, data};
    throw error;
  }

  return {data};
};

module.exports = {
  makeHyperswitchRequest,
  HYPERSWITCH_BASE_URL
};
