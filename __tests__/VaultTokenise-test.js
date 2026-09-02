/**
 * End-to-end-ish verification of the native tokenise chain, simulating what
 * happens on BOTH platforms when a merchant calls
 * HyperswitchCollect.tokenise(completion):
 *
 *   DeviceEventEmitter "hsVaultTokenise" (the broadcast both SDKs emit)
 *     → CVC-surface listener (VaultTokenise.subscribe)
 *     → verify (registry collectableState: card+expiry+cvc mounted&valid)
 *     → collect raw values from the widget package's registry raw store
 *     → VaultConfirm.confirmPaymentMethodSession (the vault package's call)
 *     → answer JSON through HyperVaultModule.returnTokenizedValue
 *     → (native: TokeniseDispatcher resolves VaultTokeniseResult.fromJson)
 */

jest.mock('../src/specs/NativeHyperVaultModule', () => ({
  __esModule: true,
  default: {
    returnTokenizedValue: jest.fn(),
  },
}));

const mockConfirm = jest.fn();
jest.mock('react-native-hyperswitch-vault/src/VaultConfirm.bs.js', () => ({
  __esModule: true,
  ...jest.requireActual('react-native-hyperswitch-vault/src/VaultConfirm.bs.js'),
  confirmPaymentMethodSession: (...args) => mockConfirm(...args),
}));

/* The registry lives in the WIDGET package now — NativeHyperswitchVault
 * resolves the HyperVaultModule singleton lazily itself. */
const Registry = require('react-native-hyperswitch-vault/src/NativeHyperswitchVault.bs.js');
const VaultTokenise = require('../src/vault/VaultTokenise.bs.js');
const NativeHyperVaultModuleAnswer =
  require('../src/specs/NativeHyperVaultModule').default;
const {DeviceEventEmitter, TurboModuleRegistry} = require('react-native');

/* HyperVaultNative binds TurboModuleRegistry.get('HyperVaultModule') lazily —
 * these two channels are what the registry actually calls at runtime. */
const turbo = {
  updateFieldState: jest.fn(),
  updateVaultFieldStates: jest.fn(),
};

const FIELD = {card: 'card_number', expiry: 'exp_date', cvc: 'cvc'};

const pushValid = fieldType =>
  Registry.pushFieldState(1, fieldType, {
    field: fieldType,
    status: 'complete',
    valid: true,
    isEmpty: false,
    isFocused: false,
    error: undefined,
    brand: undefined,
  });

const readyAllFields = () => {
  [FIELD.card, FIELD.expiry, FIELD.cvc].forEach(pushValid);

  Registry.putRawValue(FIELD.card, '4242424242424242');
  Registry.putRawValue(FIELD.expiry, {month: '12', year: '2030'});
  Registry.putRawValue(FIELD.cvc, '123');

  // Base64 JSON the SDK authorization is expected to embed.
  const sdkAuthorization = Buffer.from(
    JSON.stringify({payment_method_session_id: 'pms_123'}),
  ).toString('base64');
  return {sdkAuthorization};
};

const dropAll = () => {
  [FIELD.card, FIELD.expiry, FIELD.cvc, 'card_holder'].forEach(ft =>
    Registry.dropSurface(ft),
  );
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
  let captured = null;
  const spy = jest
    .spyOn(DeviceEventEmitter, 'addListener')
    .mockImplementation((name, listener) => {
      if (name === 'hsVaultTokenise') captured = listener;
      return {remove: jest.fn()};
    });

  // The CVC surface claims the broadcast with THE registry's own thunks —
  // the same wiring HsVaultEntry installs at mount time.
  VaultTokenise.subscribe(
    undefined,
    undefined,
    Registry.collectableState,
    Registry.collectCard,
  );
  captured(body);
  // Flush the promise chain (runTokenise → confirm → returnTokenizedValue).
  return new Promise(r => setTimeout(r, 30)).finally(() => spy.mockRestore());
};

test('bin contract: emitted only at >= 6 digits, only card_number type, stripped of raw formatting', () => {
  /* Raw value stored first — the emit paths read the raw store at push time. */
  Registry.putRawValue(FIELD.card, '4242 4'); // five digits — bin NOT sent yet
  Registry.pushFieldState(1, FIELD.card, {
    field: FIELD.card,
    status: 'incomplete',
    valid: false,
    isEmpty: false,
    isFocused: true,
    error: undefined,
    brand: 'visa',
  });

  const fiveDigits = JSON.parse(turbo.updateFieldState.mock.calls.at(-1)[1]);
  expect(fiveDigits.bin).toBeUndefined();

  Registry.putRawValue(FIELD.card, '4242 4242 4242 4242');
  Registry.pushFieldState(1, FIELD.card, {
    field: FIELD.card,
    status: 'valid',
    isEmpty: false,
    isFocused: true,
    error: undefined,
    brand: 'visa',
  });

  const sixteen = JSON.parse(turbo.updateFieldState.mock.calls.at(-1)[1]);
  expect(sixteen.bin).toBe('424242');
  expect(sixteen.cardBrand).toBeUndefined(); /* JS ships 'brand'; native maps the wire key. */
  expect(sixteen.brand).toBe('visa');

  const batch = JSON.parse(turbo.updateVaultFieldStates.mock.calls.at(-1)[0]);
  const card = batch.find(s => s.fieldType === 'card_number');
  expect(card?.bin).toBe('424242');

  /* Other field types never receive a bin, regardless of card presence. */
  Registry.pushFieldState(2, FIELD.cvc, {
    field: FIELD.cvc,
    status: 'complete',
    valid: true,
    isEmpty: false,
    isFocused: false,
    error: undefined,
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
    expiryYear: '2030',
    cvc: '123',
  });
  expect(req.vaultBaseUrl).toContain('http');

  const answered = JSON.parse(
    NativeHyperVaultModuleAnswer.returnTokenizedValue.mock.calls[0][0],
  );
  expect(answered).toEqual({status: 'success', token: 'tok_1'});

  /*
   * Native decoder contract lock: BOTH push channels carry the canonical keys
   * the SDK FieldState decoders parse (fieldType/isValid/isEmpty/isFocused).
   * Missing keys mean every state lands as the INFO fallback row there.
   */
  const single = JSON.parse(turbo.updateFieldState.mock.calls.at(-1)[1]);
  expect(single).toMatchObject({fieldType: 'cvc', isValid: true});
  const batch = JSON.parse(turbo.updateVaultFieldStates.mock.calls.at(-1)[0]);
  expect(batch).toHaveLength(3);
  batch.forEach(state => {
    expect(state.fieldType).toMatch(/^(card_number|exp_date|cvc)$/);
    expect(state.isValid).toBe(true);
    expect(typeof state.isEmpty).toBe('boolean');
  });
});

test('verify gate: nothing mounted → not_ready without any network call', async () => {
  await emitTokenise({sdkAuthorization: 'e30=', environment: 'sandbox'});

  expect(mockConfirm).not.toHaveBeenCalled();
  const answered = JSON.parse(
    NativeHyperVaultModuleAnswer.returnTokenizedValue.mock.calls[0][0],
  );
  expect(answered.status).toBe('not_ready');
  expect(answered.error.code).toBe('not_ready');
});

test('verify gate: mounted but invalid → validation_error without network call', async () => {
  [FIELD.card, FIELD.expiry, FIELD.cvc].forEach(ft =>
    Registry.pushFieldState(1, ft, {
      field: ft,
      status: 'incomplete',
      valid: false,
      isEmpty: false,
      isFocused: false,
      error: undefined,
      brand: undefined,
    }),
  );

  await emitTokenise({sdkAuthorization: 'e30=', environment: 'sandbox'});

  expect(mockConfirm).not.toHaveBeenCalled();
  const answered = JSON.parse(
    NativeHyperVaultModuleAnswer.returnTokenizedValue.mock.calls[0][0],
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
    NativeHyperVaultModuleAnswer.returnTokenizedValue.mock.calls[0][0],
  );
  expect(answered.status).toBe('error');
  expect(answered.error.code).toBe('server_error');
});
