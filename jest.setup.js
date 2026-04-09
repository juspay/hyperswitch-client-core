// jest.setup.js — React Native mock setup for hyperswitch-client-core
//
// This file is loaded before each test suite via setupFiles in jest.config.js.
// It mocks native modules, platform APIs, and other globals that are unavailable
// in the Jest Node.js test environment.

// --- Global fetch mock ---
global.fetch = jest.fn(() =>
  Promise.resolve({
    ok: true,
    status: 200,
    json: () => Promise.resolve({}),
    text: () => Promise.resolve(''),
  })
);

// --- React Native module mocks ---

// Mock react-native Linking
jest.mock('react-native/Libraries/Linking/Linking', () => ({
  openURL: jest.fn(() => Promise.resolve()),
  canOpenURL: jest.fn(() => Promise.resolve(true)),
  getInitialURL: jest.fn(() => Promise.resolve(null)),
  addEventListener: jest.fn(),
  removeEventListener: jest.fn(),
}));

// Mock react-native Alert
jest.mock('react-native/Libraries/Alert/Alert', () => ({
  alert: jest.fn(),
}));

// Mock react-native Animated
jest.mock('react-native/Libraries/Animated/Animated', () => {
  const ActualAnimated = jest.requireActual(
    'react-native/Libraries/Animated/Animated'
  );
  return {
    ...ActualAnimated,
    timing: jest.fn(() => ({
      start: jest.fn((cb) => cb && cb({ finished: true })),
      stop: jest.fn(),
    })),
    spring: jest.fn(() => ({
      start: jest.fn((cb) => cb && cb({ finished: true })),
      stop: jest.fn(),
    })),
    Value: ActualAnimated.Value,
  };
});

// --- Optional native module mocks (graceful degradation) ---

// Netcetera 3DS
jest.mock('@juspay-tech/react-native-hyperswitch-netcetera-3ds', () => ({
  initialise: jest.fn(() => Promise.resolve()),
  authenticate: jest.fn(() => Promise.resolve({})),
}), { virtual: true });

// Scan Card
jest.mock('@juspay-tech/react-native-hyperswitch-scancard', () => ({
  startCardScan: jest.fn(() => Promise.resolve(null)),
}), { virtual: true });

// Samsung Pay
jest.mock('@juspay-tech/react-native-hyperswitch-samsung-pay', () => ({
  isAvailable: false,
  startPayment: jest.fn(),
}), { virtual: true });

// PayPal
jest.mock('@juspay-tech/react-native-hyperswitch-paypal', () => ({
  isAvailable: false,
  startPayment: jest.fn(),
}), { virtual: true });

// Click to Pay
jest.mock('@juspay-tech/react-native-hyperswitch-click-to-pay', () => ({
  isAvailable: false,
}), { virtual: true });

// Klarna
jest.mock('react-native-klarna-inapp-sdk', () => ({
  default: jest.fn(),
}), { virtual: true });

// Sentry
jest.mock('@sentry/react-native', () => ({
  init: jest.fn(),
  captureException: jest.fn(),
  captureMessage: jest.fn(),
  addBreadcrumb: jest.fn(),
}), { virtual: true });

// InAppBrowser
jest.mock('react-native-inappbrowser-reborn', () => ({
  open: jest.fn(() => Promise.resolve({ type: 'cancel' })),
  close: jest.fn(),
  isAvailable: jest.fn(() => Promise.resolve(true)),
}), { virtual: true });

// --- Silence React Native warnings in test output ---
const originalConsoleWarn = console.warn;
console.warn = (...args) => {
  // Suppress known noisy warnings
  if (
    typeof args[0] === 'string' &&
    (args[0].includes('Animated: `useNativeDriver`') ||
     args[0].includes('componentWillReceiveProps') ||
     args[0].includes('componentWillMount'))
  ) {
    return;
  }
  originalConsoleWarn.call(console, ...args);
};
