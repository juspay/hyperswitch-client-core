/**
 * End-to-end-ish verification of the native tokenise chain, simulating what
 * happens on BOTH platforms when a merchant calls
 * HyperswitchVault.tokenise(completion):
 *
 *   HyperVaultModule.onVaultTokenise — codegen typed EventEmitter
 *   (the vault twin of the main SDK's triggerWidgetAction channel)
 *     → CVC-surface listener (VaultTokenise.subscribe)
 *     → verify (HyperVaultStore.collectableState: card+expiry+cvc mounted&valid)
 *     → collect raw values from HyperVaultStore (the ONE global registry)
 *     → VaultConfirm.confirmPaymentMethodSession (the vault package's call)
 *     → answer JSON through HyperVaultModule.returnTokenizedValue
 *     → (native: TokeniseDispatcher resolves VaultTokeniseResult.fromJson)
 */

/* The typed channel shim (the Rescript layer's ONLY bridge dep). The real
 * module wraps TurboModule codegen: answers go through returnTokenizedValue,
 * the request is the codegen-typed onVaultTokenise EventEmitter — the vault
 * twin of the main SDK's HyperModule.triggerWidgetAction. */
jest.mock('../src/vault/HyperVaultNative', () => ({
  __esModule: true,
  returnTokenizedValue: jest.fn(),
  subscribeVaultTokenise: handler => {
    capturedTokeniseHandler = handler;
    return jest.fn();
  },
}));

let capturedTokeniseHandler = null;

const mockConfirm = jest.fn();
jest.mock('react-native-hyperswitch-vault/src/VaultConfirm.bs.js', () => ({
  __esModule: true,
  ...jest.requireActual('react-native-hyperswitch-vault/src/VaultConfirm.bs.js'),
  confirmPaymentMethodSession: (...args) => mockConfirm(...args),
}));

/* THE global registry — client-core's. The widget package's HyperNativeVault
 * pushes single-field state over the TurboModule and writes through this
 * exact store object (its globalThis.HyperVaultStore interface). */
const HyperVaultStore = require('../src/vault/HyperVaultStore.bs.js');
const HyperNativeVault = require('react-native-hyperswitch-vault/src/HyperNativeVault.bs.js');

/* vault.js's two registrations — the flag and THE global store — mirrored so
 * the widget package's HyperNativeVault can dereference globalThis.HyperVaultStore. */
globalThis.__useHyperswitchNativeFeaturesFlag__ = true;
globalThis.HyperVaultStore = HyperVaultStore;

const VaultTokenise = require('../src/vault/VaultTokenise.bs.js');
const VaultChannel = require('../src/vault/HyperVaultNative');
const {TurboModuleRegistry} = require('react-native');

/* HyperVaultNative binds TurboModuleRegistry.get('HyperVaultModule') lazily —
 * these two channels are what the hook actually calls at runtime. */
const turbo = {
  updateFieldState: jest.fn(),
  updateVaultFieldStates: jest.fn(),
};

const FIELD = {card: 'card_number', expiry: 'exp_date', cvc: 'cvc'};

const wire = (fieldType, over = {}) => ({
  fieldType,
  isValid: true,
  isEmpty: false,
  isFocused: false,
  ...over,
});

/* Wire + raw in one update — the exact pair a widget's hook writes per change. */
const pushValid = (fieldType, rawValue) =>
  HyperVaultStore.update(1, fieldType, rawValue, wire(fieldType));

const readyAllFields = () => {
  pushValid(FIELD.card, '4242424242424242');
  pushValid(FIELD.expiry, '12 / 30');
  pushValid(FIELD.cvc, '123');

  // Base64 JSON the SDK authorization is expected to embed.
  const sdkAuthorization = Buffer.from(
    JSON.stringify({payment_method_session_id: 'pms_123'}),
  ).toString('base64');
  return {sdkAuthorization};
};

const dropAll = () => {
  [FIELD.card, FIELD.expiry, FIELD.cvc, 'card_holder'].forEach(ft =>
    HyperVaultStore.dropFieldType(1, ft),
  );
  HyperVaultStore.dropFieldType(2, FIELD.cvc);
};

let getSpy;
beforeAll(() => {
  getSpy = jest
    .spyOn(TurboModuleRegistry, 'get')
    .mockImplementation(name => (name === 'HyperVaultModule' ? turbo : null));
});

afterAll(() => getSpy.mockRestore());

beforeEach(() => {
  jest.clearAllMocks();
  dropAll();
});

const emitTokenise = body => {
  // The CVC surface claims the broadcast with THE store's own thunks —
  // the same wiring HsVaultEntry installs at mount time.
  VaultTokenise.subscribe(
    undefined,
    undefined,
    HyperVaultStore.collectableState,
    HyperVaultStore.collectCard,
  );
  expect(capturedTokeniseHandler).toBeInstanceOf(Function);
  capturedTokeniseHandler(body);
  // Flush the promise chain (runTokenise → confirm → returnTokenizedValue).
  return new Promise(r => setTimeout(r, 30));
};

test('bin contract: emitted only at >= 6 digits, only card_number type, stripped of raw formatting', () => {
  /* The hook path itself: pushFieldState stores the raw and emits the wire. */
  const raw = '4242 4'; // five digits — bin NOT sent yet
  HyperNativeVault.pushFieldState(1, FIELD.card, raw, {
    isValid: false,
    isEmpty: false,
    isFocused: true,
    bin: HyperNativeVault.binOfRawCard(raw),
    brand: 'visa',
  });

  const fiveDigits = JSON.parse(turbo.updateFieldState.mock.calls.at(-1)[1]);
  expect(fiveDigits.bin).toBeUndefined();

  const full = '4242 4242 4242 4242';
  HyperNativeVault.pushFieldState(1, FIELD.card, full, {
    isValid: true,
    isEmpty: false,
    isFocused: true,
    bin: HyperNativeVault.binOfRawCard(full),
    brand: 'visa',
  });

  const sixteen = JSON.parse(turbo.updateFieldState.mock.calls.at(-1)[1]);
  expect(sixteen.bin).toBe('424242');
  expect(sixteen.cardBrand).toBeUndefined(); /* JS ships 'brand'; native maps the wire key. */
  expect(sixteen.brand).toBe('visa');

  /* The AGGREGATE channel fires on cell registration — a pure value change in
   * an existing cell must NEVER re-broadcast every field. */
  expect(turbo.updateVaultFieldStates.mock.calls).toHaveLength(1);
  const batch = JSON.parse(turbo.updateVaultFieldStates.mock.calls.at(-1)[0]);
  expect(batch.find(s => s.fieldType === 'card_number')?.bin).toBeUndefined();

  /* Other field types never receive a bin, regardless of card presence. */
  HyperNativeVault.pushFieldState(2, FIELD.cvc, '12', {
    isValid: false,
    isEmpty: false,
    isFocused: false,
    bin: undefined,
    brand: undefined,
  });
  const cvc = JSON.parse(turbo.updateFieldState.mock.calls.at(-1)[1]);
  expect(cvc.bin).toBeUndefined();

  dropAll();
});

test('happy path: verify → collect → confirm → returnTokenizedValue(success)', async () => {
  const {sdkAuthorization} = readyAllFields();
  mockConfirm.mockResolvedValue({
    status: 'success',
    result: {
      token: 'tok_1',
      card: {last4Digits: '4242', expiryMonth: '12', expiryYear: '2030'},
    },
  });

  await emitTokenise({sdkAuthorization, environment: 'sandbox'});

  expect(mockConfirm).toHaveBeenCalledTimes(1);
  const req = mockConfirm.mock.calls[0][0];
  expect(req.sdkAuthorization).toBe(sdkAuthorization);
  expect(req.card).toEqual({
    cardNumber: '4242424242424242',
    expiryMonth: '12',
    /* The store keeps the display raw ("12 / 30"); the 2-digit year is expanded
     * INSIDE the real VaultConfirm (requestExpiryYear) — the mock sits before it. */
    expiryYear: '30',
    cvc: '123',
  });
  expect(req.vaultBaseUrl).toContain('http');

  const answered = JSON.parse(
    VaultChannel.returnTokenizedValue.mock.calls[0][0],
  );
  expect(answered).toEqual({status: 'success', token: 'tok_1'});
});

test('verify gate: nothing mounted → not_ready without any network call', async () => {
  await emitTokenise({sdkAuthorization: 'e30=', environment: 'sandbox'});

  expect(mockConfirm).not.toHaveBeenCalled();
  const answered = JSON.parse(
    VaultChannel.returnTokenizedValue.mock.calls[0][0],
  );
  expect(answered.status).toBe('not_ready');
  expect(answered.error.code).toBe('not_ready');
});

test('verify gate: mounted but invalid → validation_error without network call', async () => {
  [FIELD.card, FIELD.expiry, FIELD.cvc].forEach(ft =>
    HyperVaultStore.update(1, ft, 'x', wire(ft, {isValid: false})),
  );

  await emitTokenise({sdkAuthorization: 'e30=', environment: 'sandbox'});

  expect(mockConfirm).not.toHaveBeenCalled();
  const answered = JSON.parse(
    VaultChannel.returnTokenizedValue.mock.calls[0][0],
  );
  expect(answered.status).toBe('validation_error');
  expect(answered.error.code).toBe('invalid_card_data');
});

test('transport failure maps through the package taxonomy (http_error → server_error)', async () => {
  readyAllFields();
  mockConfirm.mockResolvedValue({
    status: 'failure',
    error: {
      code: 'http_error',
      message: 'boom',
      httpStatus: 500,
      retryable: true,
      unknownOutcome: false,
    },
  });

  await emitTokenise({
    sdkAuthorization: Buffer.from(
      JSON.stringify({payment_method_session_id: 'pms_123'}),
    ).toString('base64'),
    environment: 'sandbox',
  });

  const answered = JSON.parse(
    VaultChannel.returnTokenizedValue.mock.calls[0][0],
  );
  expect(answered.status).toBe('error');
  expect(answered.error.code).toBe('server_error');
});
