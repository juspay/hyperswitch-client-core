/**
 * DemoApp - Merchant Integration Example
 *
 * Mirrors the Android MainActivity flow exactly.
 */

let hs = null;
let session = null;
let handler = null;

function setResult(text) {
  const el = document.getElementById('result');
  if (el) el.textContent = text;
}

// ── Step 1: Merchant fetches from THEIR backend ────────────────────────────

async function fetchPaymentIntent() {
  const res = await fetch('http://localhost:5252/create-payment-intent');
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  return res.json();
}

// ── Step 2: Hyperswitch.init() ─────────────────────────────────────────────

window.initHyperswitch = async () => {
  try {
    const backend = await fetchPaymentIntent();

    hs = Hyperswitch.init({
      publishableKey: backend.publishableKey,
      profileId: backend.profileId,
      environment: 'sandbox',
    });

    session = await hs.initPaymentSession({
      sdkAuthorization: backend.sdkAuthorization,
    });

    setResult('Hyperswitch initialized. Session ready.');
  } catch (err) {
    console.error('[DemoApp] Init error:', err);
    setResult(`Error: ${err.message}`);
  }
};

// ── Step 3: Present Payment Sheet ──────────────────────────────────────────

window.presentPaymentSheet = async () => {
  try {
    if (!session) {
      setResult('Error: Initialize Hyperswitch first');
      return;
    }
    const result = await session.presentPaymentSheet();
    setResult(`Result: ${JSON.stringify(result, null, 2)}`);
  } catch (err) {
    console.error('[DemoApp] Payment sheet error:', err);
    setResult(`Error: ${err.message}`);
  }
};

// ── Step 4: Get Saved Methods & Confirm ────────────────────────────────────

window.getSavedMethods = async () => {
  try {
    if (!session) {
      setResult('Error: Initialize Hyperswitch first');
      return;
    }
    handler = await session.getCustomerSavedPaymentMethods();

    const all = await handler.getCustomerSavedPaymentMethods();
    const def = await handler.getCustomerDefaultSavedPaymentMethodData();
    const last = await handler.getCustomerLastUsedPaymentMethodData();
    setResult(
      `All (${all.length}): ${JSON.stringify(all, null, 2)}\n\nDefault: ${JSON.stringify(def, null, 2)}\n\nLast Used: ${JSON.stringify(last, null, 2)}`,
    );
  } catch (err) {
    console.error('[DemoApp] getSavedMethods error:', err);
    setResult(`Error: ${err.message}`);
  }
};

window.confirmWithDefault = async () => {
  try {
    if (!handler) {
      setResult('Error: Get saved methods first');
      return;
    }
    const cvc = document.getElementById('cvcInput')?.value;
    setResult('Confirming with default...');
    const result = await handler.confirmWithCustomerDefaultPaymentMethod(cvc || undefined);
    setResult(`Result: ${JSON.stringify(result, null, 2)}`);
  } catch (err) {
    console.error('[DemoApp] confirmWithDefault error:', err);
    setResult(`Error: ${err.message}`);
  }
};

window.confirmWithLastUsed = async () => {
  try {
    if (!handler) {
      setResult('Error: Get saved methods first');
      return;
    }
    const cvc = document.getElementById('cvcInput')?.value;
    setResult('Confirming with last used...');
    const result = await handler.confirmWithCustomerLastUsedPaymentMethod(cvc || undefined);
    setResult(`Result: ${JSON.stringify(result, null, 2)}`);
  } catch (err) {
    console.error('[DemoApp] confirmWithLastUsed error:', err);
    setResult(`Error: ${err.message}`);
  }
};

window.confirmWithToken = async () => {
  try {
    if (!handler) {
      setResult('Error: Get saved methods first');
      return;
    }
    const token = document.getElementById('tokenInput')?.value;
    const cvc = document.getElementById('cvcInput')?.value;
    if (!token) {
      setResult('Error: Enter a payment token');
      return;
    }
    setResult('Confirming...');
    const result = await handler.confirmWithCustomerPaymentToken(token, cvc || undefined);
    setResult(`Result: ${JSON.stringify(result, null, 2)}`);
  } catch (err) {
    console.error('[DemoApp] confirmWithToken error:', err);
    setResult(`Error: ${err.message}`);
  }
};

// ── Elements (Embedded) ────────────────────────────────────────────────────

let cardElement = null;

window.initElements = async () => {
  try {
    const backend = await fetchPaymentIntent();

    if (!hs) {
      hs = Hyperswitch.init({
        publishableKey: backend.publishableKey,
        profileId: backend.profileId,
        environment: 'sandbox',
      });
    }

    const elements = await hs.elements({
      sdkAuthorization: backend.sdkAuthorization,
    });

    cardElement = elements.create({ type: 'widgetPaymentSheet' });

    const container = document.getElementById('card-container');
    container.style.display = 'block';
    cardElement.mount('#card-container');

    setResult('Card element mounted in container below');
  } catch (err) {
    console.error('[DemoApp] Elements error:', err);
    setResult(`Error: ${err.message}`);
  }
};

window.confirmElement = async () => {
  try {
    if (!cardElement) {
      setResult('Error: Initialize card element first');
      return;
    }
    setResult('Confirming payment via element...');
    const result = await cardElement.confirmPayment({
      confirmParams: {
        returnUrl: window.location.href,
      },
    });
    setResult(`Result: ${JSON.stringify(result, null, 2)}`);
  } catch (err) {
    console.error('[DemoApp] Confirm element error:', err);
    setResult(`Error: ${err.message}`);
  }
};

window.initHyperswitch(); // Auto-init on page load