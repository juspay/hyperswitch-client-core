// Backend for the Maestro end-to-end suite. It stands in front of the repo's mockServer.js, which it
// starts unchanged on an internal port:
//   - POST/GET/DELETE /scenario, GET /scenarios, GET /scenario/last-payment: select and inspect a
//     test scenario (scenarios.js)
//   - GET /create-payment-intent while a scenario with a `body` is active: creates that scenario's
//     payment intent
//   - every other request: forwarded to mockServer.js as it is
// With no scenario selected the demo apps get exactly what `yarn server` gives them.
//
// Usage (repo root): yarn e2e:server
//   E2E_PORT          port the demo apps call (default 5252, the port they are configured for)
//   E2E_BACKEND_PORT  internal port for mockServer.js (default E2E_PORT + 10)
// Reads the same .env as mockServer.js (HYPERSWITCH_SECRET_KEY, HYPERSWITCH_PUBLISHABLE_KEY,
// PROFILE_ID, HYPERSWITCH_SANDBOX_URL).
const path = require('path');
const {spawn} = require('child_process');
const express = require('express');
const cors = require('cors');

const ROOT = path.resolve(__dirname, '../..');
require('dotenv').config({path: path.join(ROOT, '.env')});

const scenarios = require('./scenarios.js');

const PORT = Number(process.env.E2E_PORT || 5252);
const BACKEND_PORT = Number(process.env.E2E_BACKEND_PORT || PORT + 10);
const BACKEND = `http://127.0.0.1:${BACKEND_PORT}`;

const HYPERSWITCH_SECRET_KEY = process.env.HYPERSWITCH_SECRET_KEY;
const HYPERSWITCH_PUBLISHABLE_KEY = process.env.HYPERSWITCH_PUBLISHABLE_KEY;
const PROFILE_ID = process.env.PROFILE_ID;
// Same base URL rule as mockServer.js.
const HYPERSWITCH_BASE_URL =
  process.env.HYPERSWITCH_SANDBOX_URL ||
  process.env.HYPERSWITCH_INTEG_URL ||
  'https://sandbox.hyperswitch.io';

const log = (...args) => console.log('[e2e-server]', ...args);
const logError = (...args) => console.error('[e2e-server]', ...args);

let activeScenario = null; // {name, customerId, lastPaymentId}

const makeHyperswitchRequest = async (endpoint, options, apiKey) => {
  const response = await fetch(`${HYPERSWITCH_BASE_URL}${endpoint}`, {
    ...options,
    headers: {'Content-Type': 'application/json', 'api-key': apiKey},
  });
  const data = await response.json();
  if (!response.ok) {
    const error = new Error(`HTTP ${response.status}`);
    error.response = {status: response.status, data};
    throw error;
  }
  return {data};
};

// DEFAULT is the .env account. Another account needs HS_<NAME>_PROFILE_ID, plus its own
// HS_<NAME>_SECRET_KEY / HS_<NAME>_PUBLISHABLE_KEY when it lives in a different merchant account.
const scenarioAccount = name => {
  if (name === 'DEFAULT') {
    return {
      secretKey: HYPERSWITCH_SECRET_KEY,
      publishableKey: HYPERSWITCH_PUBLISHABLE_KEY,
      profileId: PROFILE_ID,
      missing: [],
    };
  }
  const prefix = `HS_${name}_`;
  const ownSecret = process.env[`${prefix}SECRET_KEY`];
  const ownPublishable = process.env[`${prefix}PUBLISHABLE_KEY`];
  const profileId = process.env[`${prefix}PROFILE_ID`];
  const missing = [];
  if (!profileId) missing.push(`${prefix}PROFILE_ID`);
  if (ownSecret && !ownPublishable) missing.push(`${prefix}PUBLISHABLE_KEY`);
  if (ownPublishable && !ownSecret) missing.push(`${prefix}SECRET_KEY`);
  return {
    secretKey: ownSecret || HYPERSWITCH_SECRET_KEY,
    publishableKey: ownPublishable || HYPERSWITCH_PUBLISHABLE_KEY,
    profileId,
    missing,
  };
};

const scenarioMissingVars = scenario => {
  const missing = [...scenarioAccount(scenario.account || 'DEFAULT').missing];
  if (scenario.customerEnv && !process.env[scenario.customerEnv]) {
    missing.push(scenario.customerEnv);
  }
  return missing;
};

// Deletes a dotted path from the intent body. Own properties only, so a path can never reach
// Object.prototype.
const removePath = (obj, dottedPath) => {
  const keys = dottedPath.split('.');
  if (keys.some(key => ['__proto__', 'constructor', 'prototype'].includes(key))) {
    return;
  }
  const last = keys.pop();
  const parent = keys.reduce(
    (node, key) =>
      node &&
      typeof node === 'object' &&
      Object.prototype.hasOwnProperty.call(node, key)
        ? node[key]
        : undefined,
    obj,
  );
  if (
    parent &&
    typeof parent === 'object' &&
    Object.prototype.hasOwnProperty.call(parent, last)
  ) {
    delete parent[last];
  }
};

const describeScenario = () => ({
  name: activeScenario ? activeScenario.name : null,
  account: activeScenario
    ? scenarios[activeScenario.name].account || 'DEFAULT'
    : 'DEFAULT',
  customerId: activeScenario ? activeScenario.customerId || null : null,
});

// Saves `cards` for `customerId` by confirming one no-3DS test payment per card with customer
// acceptance, so the customer's next intent lists them as saved payment methods.
// A card with `setupOnly: true` is saved with a zero-amount setup mandate instead, so a card that
// only declines on charge can still be saved.
const seedSavedCards = async (account, customerId, cards) => {
  for (const {setupOnly, ...card} of cards) {
    const payment = setupOnly
      ? {
          amount: 0,
          payment_type: 'setup_mandate',
          setup_future_usage: 'off_session',
          payment_method_type: 'credit',
        }
      : {amount: 100, capture_method: 'automatic', setup_future_usage: 'on_session'};
    const response = await makeHyperswitchRequest(
      '/payments',
      {
        method: 'POST',
        body: JSON.stringify({
          ...payment,
          currency: 'USD',
          confirm: true,
          authentication_type: 'no_three_ds',
          customer_id: customerId,
          profile_id: account.profileId,
          payment_method: 'card',
          payment_method_data: {
            card: {
              card_exp_month: '04',
              card_exp_year: '44',
              card_holder_name: 'Maestro Test',
              ...card,
            },
          },
          customer_acceptance: {
            acceptance_type: 'online',
            accepted_at: new Date().toISOString(),
            online: {ip_address: '127.0.0.1', user_agent: 'maestro-e2e'},
          },
        }),
      },
      account.secretKey,
    );
    if (response.data.status !== 'succeeded') {
      const error = new Error(`Seed payment ${response.data.status}`);
      error.response = {status: 502, data: response.data};
      throw error;
    }
  }
};

// Marks the customer's saved card ending in `last4` as their default payment method.
const setDefaultSavedCard = async (account, customerId, last4) => {
  const list = await makeHyperswitchRequest(
    `/customers/${customerId}/payment_methods`,
    {method: 'GET'},
    account.secretKey,
  );
  const target = (list.data.customer_payment_methods || []).find(
    pm => pm.card && pm.card.last4_digits === last4,
  );
  if (!target) {
    const error = new Error(`No saved card ending in ${last4}`);
    error.response = {status: 502, data: list.data};
    throw error;
  }
  if (target.default_payment_method_set) return; // the API rejects re-setting it (IR_16)
  await makeHyperswitchRequest(
    `/customers/${customerId}/payment_methods/${target.payment_method_id}/default`,
    {method: 'POST'},
    account.secretKey,
  );
};

// Forwards a request to mockServer.js and relays its answer. Returns the response body so a
// caller can inspect it.
const HOP_BY_HOP = new Set([
  'host',
  'connection',
  'keep-alive',
  'transfer-encoding',
  'upgrade',
  'proxy-connection',
  'te',
  'trailer',
  'expect',
  'content-length',
]);
const forward = async (req, res) => {
  const headers = Object.fromEntries(
    Object.entries(req.headers).filter(([name]) => !HOP_BY_HOP.has(name)),
  );
  const hasBody =
    !['GET', 'HEAD'].includes(req.method) && Buffer.isBuffer(req.body) && req.body.length > 0;
  try {
    const response = await fetch(`${BACKEND}${req.originalUrl}`, {
      method: req.method,
      headers,
      body: hasBody ? req.body : undefined,
    });
    const body = Buffer.from(await response.arrayBuffer());
    const type = response.headers.get('content-type');
    if (type) res.set('content-type', type);
    res.status(response.status).send(body);
    return {status: response.status, body};
  } catch (error) {
    res.status(502).json({error: 'mockServer.js is not reachable', details: error.message});
    return null;
  }
};

const createScenarioPaymentIntent = async res => {
  const state = activeScenario;
  const {name, customerId} = state;
  const scenario = scenarios[name];
  const account = scenarioAccount(scenario.account || 'DEFAULT');

  try {
    if (scenario.intentError) {
      log(`Scenario ${name}: returning a simulated error`);
      return res.status(scenario.intentError.status).json(scenario.intentError.body);
    }

    const paymentData = {amount: 100};
    if (process.env.HYPERSWITCH_CUSTOMER_ID) {
      paymentData.customer_id = process.env.HYPERSWITCH_CUSTOMER_ID;
    }
    const body = typeof scenario.body === 'function' ? scenario.body({customerId}) : scenario.body;
    Object.assign(paymentData, structuredClone(body));

    if (scenario.customer === 'fresh') {
      paymentData.customer_id = customerId;
    }
    if (scenario.customerEnv) {
      paymentData.customer_id = process.env[scenario.customerEnv];
    }
    if (scenario.customer === 'none') {
      delete paymentData.customer_id;
    }
    (scenario.removeKeys || []).forEach(dottedPath => removePath(paymentData, dottedPath));
    if (account.profileId) {
      paymentData.profile_id = account.profileId;
    }

    const response = await makeHyperswitchRequest(
      '/payments',
      {method: 'POST', body: JSON.stringify(paymentData)},
      account.secretKey,
    );
    state.lastPaymentId = response.data.payment_id;

    if (scenario.afterCreate === 'cancel') {
      try {
        await makeHyperswitchRequest(
          `/payments/${response.data.payment_id}/cancel`,
          {method: 'POST', body: JSON.stringify({cancellation_reason: 'requested_by_customer'})},
          account.secretKey,
        );
      } catch (error) {
        logError(
          `Scenario ${name}: failed to cancel ${response.data.payment_id}`,
          error.response?.data || error.message,
        );
        return res.status(502).json({
          error: 'Failed to cancel payment intent',
          scenario: name,
          paymentId: response.data.payment_id,
          details: error.response?.data || error.message,
        });
      }
    }

    log(
      `Scenario ${name}: created ${response.data.payment_id}${
        paymentData.customer_id ? ` for ${paymentData.customer_id}` : ''
      }`,
    );
    res.json({
      publishableKey: account.publishableKey,
      sdkAuthorization: response.data.sdk_authorization,
      paymentId: response.data.payment_id,
      profileId: account.profileId,
      scenario: name,
    });
  } catch (error) {
    logError(`Scenario ${name}: creating the payment intent failed`, error.response?.data || error.message);
    res.status(error.response?.status || 500).json({
      error: 'Failed to create payment intent',
      scenario: name,
      details: error.response?.data || error.message,
    });
  }
};

const app = express();
app.use(cors());
// Bodies are kept raw so forwarded requests reach mockServer.js byte for byte.
app.use(express.raw({type: () => true, limit: '1mb'}));

app.post('/scenario', async (req, res) => {
  let name;
  try {
    name = JSON.parse(req.body.toString('utf8') || '{}').name;
  } catch {
    name = undefined;
  }
  if (typeof name !== 'string') {
    return res
      .status(400)
      .json({error: 'Body must be {"name": "<scenario>"}', available: Object.keys(scenarios)});
  }
  const scenario = Object.prototype.hasOwnProperty.call(scenarios, name) ? scenarios[name] : null;
  if (!scenario) {
    return res
      .status(404)
      .json({error: `Unknown scenario: ${name}`, available: Object.keys(scenarios)});
  }
  const missing = scenarioMissingVars(scenario);
  if (missing.length > 0) {
    return res.status(412).json({error: `Scenario ${name} needs these .env variables`, missing});
  }
  const customerId =
    scenario.customer === 'fresh'
      ? `maestro_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`
      : undefined;
  const account = scenarioAccount(scenario.account || 'DEFAULT');
  try {
    if (scenario.seedCards && customerId) {
      await seedSavedCards(account, customerId, scenario.seedCards);
    }
    if (scenario.defaultLast4 && customerId) {
      await setDefaultSavedCard(account, customerId, scenario.defaultLast4);
    }
  } catch (error) {
    logError(`Scenario ${name}: preparing saved cards failed`, error.response?.data || error.message);
    return res.status(502).json({
      error: `Scenario ${name}: preparing saved cards failed`,
      details: error.response?.data || error.message,
    });
  }
  activeScenario = {name, customerId};
  log(`Scenario set: ${name}${customerId ? ` (customer ${customerId})` : ''}`);
  res.json(describeScenario());
});

app.get('/scenario', (req, res) => {
  res.json(describeScenario());
});

app.delete('/scenario', (req, res) => {
  activeScenario = null;
  log('Scenario cleared');
  res.json(describeScenario());
});

app.get('/scenarios', (req, res) => {
  res.json(
    Object.entries(scenarios).map(([name, scenario]) => {
      const missing = scenarioMissingVars(scenario);
      return {
        name,
        account: scenario.account || 'DEFAULT',
        description: scenario.description,
        available: missing.length === 0,
        missing,
      };
    }),
  );
});

// Backend view of the latest intent created for the active scenario, so flows can check what the
// SDK actually did (status, which card was charged) and not only what the host app displays.
app.get('/scenario/last-payment', async (req, res) => {
  if (!activeScenario || !activeScenario.lastPaymentId) {
    return res.status(404).json({error: 'No payment created for the active scenario'});
  }
  const account = scenarioAccount(scenarios[activeScenario.name].account || 'DEFAULT');
  try {
    const {data} = await makeHyperswitchRequest(
      `/payments/${activeScenario.lastPaymentId}`,
      {method: 'GET'},
      account.secretKey,
    );
    const card = data.payment_method_data?.card || {};
    res.json({
      paymentId: data.payment_id,
      status: data.status,
      connector: data.connector,
      paymentMethod: data.payment_method,
      paymentMethodType: data.payment_method_type,
      authenticationType: data.authentication_type,
      captureMethod: data.capture_method,
      customerId: data.customer_id,
      cardLast4: card.last4 || null,
      cardNetwork: card.card_network || null,
      cardExpMonth: card.card_exp_month || card.expiry_month || null,
      cardExpYear: card.card_exp_year || card.expiry_year || null,
      amount: data.amount,
      currency: data.currency,
      errorCode: data.error_code || null,
      errorMessage: data.error_message || null,
    });
  } catch (error) {
    res.status(error.response?.status || 500).json({
      error: 'Failed to retrieve payment',
      details: error.response?.data || error.message,
    });
  }
});

app.get('/create-payment-intent', async (req, res) => {
  if (activeScenario && scenarios[activeScenario.name].body) {
    return createScenarioPaymentIntent(res);
  }
  // No scenario, or one without a body: mockServer.js creates the intent. Remember its id so
  // /scenario/last-payment also works for such scenarios.
  const state = activeScenario;
  const result = await forward(req, res);
  if (state && result && result.status === 200) {
    try {
      state.lastPaymentId = JSON.parse(result.body.toString('utf8')).paymentId;
    } catch {
      // not JSON: leave lastPaymentId as it was
    }
  }
});

// Payment method sessions use the v2 API, whose customers are separate from the v1 customers that
// payment intents and scenarios use. With PMM_CUSTOMER_ID (a v2 customer id) in .env, sessions are
// created for that customer, so payment method management has saved methods to list. A customer_id
// sent by the caller still wins, as in mockServer.js.
app.post('/create-payment-method-session', (req, res) => {
  const customerId = process.env.PMM_CUSTOMER_ID;
  if (customerId) {
    let body = {};
    try {
      body = JSON.parse(req.body.toString('utf8') || '{}');
    } catch {
      body = {};
    }
    req.body = Buffer.from(JSON.stringify({customer_id: customerId, ...body}));
    req.headers['content-type'] = 'application/json';
  }
  return forward(req, res);
});

app.use(forward);

// loopback-only.js keeps mockServer.js off the network (it listens on 0.0.0.0 by itself).
const backend = spawn(
  process.execPath,
  ['-r', path.join(__dirname, 'loopback-only.js'), path.join(ROOT, 'mockServer.js')],
  {
    cwd: ROOT,
    env: {...process.env, PORT: String(BACKEND_PORT)},
    stdio: ['ignore', 'pipe', 'pipe'],
  },
);
const prefixLines = (stream, target) => {
  let pending = '';
  stream.on('data', chunk => {
    const lines = (pending + chunk.toString()).split('\n');
    pending = lines.pop();
    lines.forEach(line => target.write(`[mockServer] ${line}\n`));
  });
};
prefixLines(backend.stdout, process.stdout);
prefixLines(backend.stderr, process.stderr);
backend.on('exit', code => {
  logError(`mockServer.js exited (${code}); stopping`);
  process.exit(code || 1);
});
const stop = () => {
  backend.kill();
  process.exit(0);
};
process.on('SIGINT', stop);
process.on('SIGTERM', stop);

// Loopback only, so nothing else on the network can reach it; the Android emulator reaches the host's
// loopback as 10.0.2.2.
app
  .listen(PORT, '127.0.0.1', () => {
    log(`listening on 127.0.0.1:${PORT} (Android emulator: 10.0.2.2:${PORT}); mockServer.js on ${BACKEND_PORT}`);
  })
  .on('error', error => {
    logError(error.code === 'EADDRINUSE' ? `port ${PORT} is already in use` : error.message);
    backend.kill();
    process.exit(1);
  });
