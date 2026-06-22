import { NativeModules } from 'react-native';
import { AppRegistry } from 'react-native';
import appJson from '../app.json';
import { HeadlessApp } from '../src/routes/AppExports.js';

const headlessName = appJson.headless;

// ── PostMessage bridge for HyperHeadless native module ──────────────────────

const callbackStore = new Map();
const TRUSTED_ORIGINS = ['*']; // In production, restrict to parent origin

const hyperHeadlessBridge = {
  getPaymentSession(rootTag, defaultPM, lastUsedPM, allPMs, callback) {
    callbackStore.set(rootTag, callback);
    console.log('Posting payment session request to parent', {
      rootTag,
      defaultPM,
      lastUsedPM,
      allPMs,
    });
    window.parent.postMessage(
      {
        type: 'headless:methods',
        default: defaultPM,
        lastUsed: lastUsedPM,
        all: allPMs,
      },
      '*',
    );
  },

  exitHeadless(rootTag, status) {
    window.parent.postMessage(
      {
        type: 'headless:result',
        status,
      },
      '*',
    );
    callbackStore.delete(rootTag);
  },
};

// Inject bridge BEFORE HeadlessApp module graph resolves
NativeModules.HyperHeadless = hyperHeadlessBridge;

// ── Register HeadlessApp (deferred bootstrap) ───────────────────────────────

AppRegistry.registerComponent(headlessName, () => HeadlessApp);

let booted = false;

function bootHeadless(props) {
  if (booted) return;
  booted = true;
  AppRegistry.runApplication(headlessName, {
    initialProps: { props },
    rootTag: document.getElementById('app-root'),
  });
}

// ── Message handlers ────────────────────────────────────────────────────────

window.addEventListener('message', (event) => {
  if (
    event.data.type === 'webpackOk' ||
    event.data.source === 'react-devtools-content-script'
  ) {
    return;
  }

  let data;
  try {
    data = typeof event.data === 'string' ? JSON.parse(event.data) : event.data;
  } catch {
    return;
  }

  if (data.type === 'headless:init') {
    bootHeadless(data.props);
    return;
  }

  if (data.type === 'headless:confirm') {
    const rootTag = data.rootTag ?? 0;
    const cb = callbackStore.get(rootTag);
    if (typeof cb === 'function') {
      cb({
        paymentToken: data.token,
        cvc: data.cvc ?? null,
      });
    }
    return;
  }
});

// Signal readiness to parent
window.parent.postMessage({ type: 'headless:sdkLoaded' }, '*');
