import * as API from '../../utility/logics/APIUtils.bs.js';
import * as SDK from '../sdk/SdkLogger.bs.js';
import * as Funnel from '../sdk/SdkFunnelLogger.bs.js';
import * as Startup from '../sdk/SdkStartupTracker.bs.js';
import * as Context from '../core/LoggerContext.bs.js';
import * as Config from '../core/LoggerConfig.bs.js';
import * as Queue from '../core/LoggerQueue.bs.js';

jest.mock('../../hooks/WebKit.bs.js', () => ({
  platform: 'android',
  platformString: 'android',
}));
jest.mock('../../types/SdkTypes.bs.js', () => ({
  sdkStateToStrMapper: () => 'PAYMENT_SHEET',
  defaultCustomEndpointsConfig: {},
}));
jest.mock('../../utility/logics/Utils.bs.js', () => ({
  getHeader: () => ({}),
  getDictFromJson: value => value,
  getJsonObjectFromRecord: value => value,
  getString: (value, key, fallback) =>
    typeof value[key] === 'string' ? value[key] : fallback,
  getBool: (value, key, fallback) =>
    typeof value[key] === 'boolean' ? value[key] : fallback,
}));
jest.mock('../../utility/constants/GlobalHooks.bs.js', () => ({
  getLoggingUrl: () => 'https://logs.example.test',
}));
jest.mock('../core/LoggerQueue.bs.js', () => ({
  push: jest.fn(),
  backfillContext: jest.fn(),
  droppedRows: {contents: 0},
  sendFailures: {contents: 0},
}));

const rows = (name?: string) =>
  (Queue.push as jest.Mock).mock.calls
    .map(([row]) => row)
    .filter(row => !name || row.event_name === name);
const details = (row: any) => JSON.parse(row.value).details;
const nativeProps = (sessionId: string) => ({
  hyperswitchConfig: {publishableKey: 'pk_test', environment: 'SANDBOX'},
  paymentSessionConfig: {
    paymentId: 'pay_test',
    sdkAuthorization: 'private-sdk-authorization',
    clientSecret: '',
  },
  sdkParams: {sessionId, sdkVersion: 'test', appId: 'app', userAgent: 'test'},
  sdkState: 'PaymentSheet',
});
const confirm = (call: () => any, failureOf = () => undefined) =>
  SDK.observeApi(
    'ConfirmCall',
    'https://api.example.test/payments/confirm',
    undefined,
    failureOf,
    result => [
      ['status_code', result.code],
      ['payment_status', result.status],
    ],
    'Card',
    undefined,
    call,
  );

describe('SDK funnel milestones', () => {
  let generation = 0;
  beforeEach(() => {
    jest.useFakeTimers();
    jest.setSystemTime(new Date('2026-01-01T00:00:00Z'));
    (Queue.push as jest.Mock).mockClear();
    Config.endpoint.contents = 'https://logs.example.test';
    Context.setSessionData(`funnel-${++generation}`, 'pk_test', 'pay_test');
  });
  afterEach(() => {
    jest.restoreAllMocks();
    SDK.stopIdleTracking();
    jest.useRealTimers();
  });

  it('records SDK auth receipt once per session without recording credentials', () => {
    const props = nativeProps(`native-${generation}`);
    SDK.adoptSessionFromNativeProp(props);
    SDK.adoptSessionFromNativeProp(props);
    expect(rows('lifecycle.sdk_init')).toHaveLength(1);
    expect(details(rows('lifecycle.sdk_init')[0]).credential_type).toBe(
      'SDK_AUTHORIZATION',
    );
    expect(JSON.stringify(rows())).not.toContain('private-sdk-authorization');
    SDK.adoptSessionFromNativeProp(nativeProps(`next-${generation}`));
    expect(rows('lifecycle.sdk_init')).toHaveLength(2);
  });

  it('does not initialize from empty credentials and preserves legacy client-secret flows', () => {
    Funnel.init('', '');
    expect(rows()).toHaveLength(0);
    Funnel.init('', 'private-client-secret');
    expect(details(rows('lifecycle.sdk_init')[0]).credential_type).toBe(
      'CLIENT_SECRET',
    );
    expect(JSON.stringify(rows())).not.toContain('private-client-secret');
  });

  it('deduplicates mounted/shimmer/rendered milestones and measures time since init', () => {
    Funnel.init('private', '');
    jest.advanceTimersByTime(50);
    Funnel.mounted();
    Funnel.shimmerShown();
    Funnel.shimmerShown();
    jest.advanceTimersByTime(150);
    Funnel.rendered(3, false);
    Funnel.rendered(3, false);
    expect(rows('lifecycle.sdk_mounted')).toHaveLength(1);
    expect(rows('lifecycle.sdk_shimmer_shown')).toHaveLength(1);
    expect(rows('lifecycle.sdk_rendered')).toHaveLength(1);
    expect(rows('lifecycle.sdk_rendered')[0].latency).toBe('200');
    expect(details(rows('lifecycle.sdk_rendered')[0])).toMatchObject({
      startup_api_count: 3,
      degraded: false,
      sdk_elapsed_ms: 200,
    });
  });

  it('uses one canonical mount event across legacy and funnel callers', () => {
    Funnel.mounted();
    SDK.logLifecycle('AppRendered');
    SDK.logLifecycle('AppRendered');
    expect(rows('lifecycle.sdk_mounted')).toHaveLength(1);
    expect(rows('lifecycle.app_rendered')).toHaveLength(0);
    jest.advanceTimersByTime(120000);
    expect(rows('lifecycle.customer_went_idle')).toHaveLength(1);
  });

  it('deduplicates confirm callbacks and terminal polling per attempt while retaining retries', () => {
    const respond = (context: any) => {
      Funnel.confirmStep(context, 'Card', {
        outcome: 'done', durationMs: 10, timeoutMs: 30000,
      }, [['status_code', 200], ['payment_status', 'succeeded']]);
      API.logPaymentOutcome({status: 'succeeded'}, 'ConfirmCall', context);
    };
    const first = Funnel.beginConfirm('Card');
    respond(first);
    jest.advanceTimersByTime(100);
    respond(first);
    expect(rows('lifecycle.payment_confirm_response')).toHaveLength(1);
    expect(rows('lifecycle.payment_succeeded')).toHaveLength(1);
    const second = Funnel.beginConfirm('Card');
    respond(second);
    expect(rows('lifecycle.payment_confirm_attempted')).toHaveLength(2);
    expect(rows('lifecycle.payment_confirm_response')).toHaveLength(2);
    expect(rows('lifecycle.payment_succeeded')).toHaveLength(2);
  });

  it('deduplicates authentication and DDC starts within each confirm attempt', async () => {
    const auth = () => SDK.observeApi('Authentication', 'https://api.example.test/3ds',
      undefined, () => undefined, () => [], 'Card', undefined,
      () => Promise.resolve({}));
    Funnel.beginConfirm('Card');
    await auth();
    await auth();
    SDK.logLifecycle('DdcStarted');
    SDK.logLifecycle('DdcStarted');
    expect(rows('lifecycle.authentication_started')).toHaveLength(1);
    expect(rows('lifecycle.ddc_started')).toHaveLength(1);
    Funnel.beginConfirm('Card');
    await auth();
    SDK.logLifecycle('DdcStarted');
    expect(rows('lifecycle.authentication_started')).toHaveLength(2);
    expect(rows('lifecycle.ddc_started')).toHaveLength(2);
  });

  it('does not mistake a later loading indicator for startup shimmer', () => {
    Funnel.rendered(0, false);
    Funnel.shimmerShown();
    expect(rows('lifecycle.sdk_shimmer_shown')).toHaveLength(0);
  });

  it('excludes autofocus and merchant-API calls from first genuine interaction', () => {
    SDK.logUser({TAG: 'FieldFocused', _0: {field: 'cardNumber'}});
    SDK.logUser({TAG: 'FieldBlurred', _0: {field: 'cardNumber'}});
    SDK.logUser({TAG: 'PaymentSubmitted', _0: {source: 'MerchantApi'}});
    expect(rows('lifecycle.first_user_interaction')).toHaveLength(0);
    Funnel.interaction('touch');
    SDK.logUser({TAG: 'PaymentMethodSelected', _0: {method: 'card'}});
    expect(rows('lifecycle.first_user_interaction')).toHaveLength(1);
    expect(
      details(rows('lifecycle.first_user_interaction')[0]).interaction,
    ).toBe('touch');
    expect(rows('user.payment_method_selected')).toHaveLength(1);
  });

  it('captures valid payment details without values and deduplicates completion', () => {
    SDK.logState({TAG: 'PaymentFormCompleted', _0: {savedMethod: false}});
    SDK.logState({TAG: 'PaymentFormCompleted', _0: {savedMethod: false}});
    expect(rows('lifecycle.payment_details_filled')).toHaveLength(1);
    expect(rows('state.payment_form_completed')).toHaveLength(0);
    expect(
      details(rows('lifecycle.payment_details_filled')[0]).saved_method,
    ).toBe(false);
  });

  it('correlates each actual confirm attempt and HTTP response, including declined HTTP results', async () => {
    const promise = Promise.resolve({
      code: 200,
      status: 'requires_customer_action',
    });
    expect(confirm(() => promise)).toBe(promise);
    expect(rows('lifecycle.payment_confirm_attempted')).toHaveLength(1);
    await promise;
    const first = details(
      rows('lifecycle.payment_confirm_attempted')[0],
    ).attempt_id;
    expect(
      details(rows('lifecycle.payment_confirm_response')[0]),
    ).toMatchObject({
      attempt_id: first,
      status_code: 200,
      status: 'requires_customer_action',
      outcome: 'done',
    });
    await confirm(
      () => Promise.resolve({code: 400, status: 'failed'}),
      () => ({name: 'HTTP_ERROR', details: []}),
    );
    expect(rows('lifecycle.payment_confirm_response')).toHaveLength(2);
    const second = details(
      rows('lifecycle.payment_confirm_attempted')[1],
    ).attempt_id;
    expect(second).not.toBe(first);
    expect(
      details(rows('lifecycle.payment_confirm_response')[1]),
    ).toMatchObject({attempt_id: second, status_code: 400, outcome: 'failed'});
  });

  it('does not invent an HTTP response for transport failure or timeout', async () => {
    const rejected = Promise.reject(new Error('network unavailable'));
    confirm(() => rejected);
    await expect(rejected).rejects.toThrow('network unavailable');
    expect(rows('lifecycle.payment_confirm_failed')).toHaveLength(1);
    expect(rows('lifecycle.payment_confirm_response')).toHaveLength(0);
    let resolve: (value: any) => void;
    const late = new Promise(done => {
      resolve = done;
    });
    confirm(() => late);
    jest.advanceTimersByTime(30000);
    expect(rows('lifecycle.payment_confirm_timed_out')).toHaveLength(1);
    expect(rows('lifecycle.payment_confirm_response')).toHaveLength(0);
    resolve({code: 200, status: 'succeeded'});
    await late;
    expect(
      details(rows('lifecycle.payment_confirm_response')[0])
        .settled_after_timeout,
    ).toBe(true);
  });

  it('keeps late responses attached to their original SDK session', async () => {
    let resolve: (value: any) => void;
    const pending = new Promise(done => {
      resolve = done;
    });
    confirm(() => pending);
    const original = rows('lifecycle.payment_confirm_attempted')[0].session_id;
    Context.setSessionData('another-session', 'pk_test', 'another-payment');
    resolve({code: 200, status: 'succeeded'});
    await pending;
    expect(rows('lifecycle.payment_confirm_response')[0].session_id).toBe(
      original,
    );
  });

  it('keeps terminal payment outcomes and attempt metadata on the original session', () => {
    Funnel.init('private', '');
    const context = Funnel.beginConfirm('Card');
    Context.setSessionData('new-session', 'pk_test', 'new-payment');
    Funnel.beginConfirm('Card');
    API.logPaymentOutcome(
      {status: 'succeeded', payment_method: 'card'},
      'ConfirmCall',
      context,
    );
    const row = rows('lifecycle.payment_succeeded')[0];
    expect(row.session_id).toBe(context.sessionId);
    expect(details(row).attempt_id).toBe(context.attemptId);
  });

  it('records an actual HTTP response with unreadable JSON while preserving processCatch', async () => {
    jest.spyOn(global, 'fetch').mockResolvedValue({
      ok: true,
      status: 200,
      json: () => Promise.reject(new SyntaxError('invalid JSON')),
    } as any);
    const success = jest.fn();
    const failure = jest.fn();
    const caught = jest.fn();
    await API.handleApiCall(
      'https://api.example.test/confirm',
      undefined,
      {},
      'ConfirmCall',
      'POST',
      success,
      failure,
      caught,
    );
    expect(caught).toHaveBeenCalledTimes(1);
    expect(success).not.toHaveBeenCalled();
    expect(failure).not.toHaveBeenCalled();
    expect(
      details(rows('lifecycle.payment_confirm_response')[0]),
    ).toMatchObject({
      status_code: 200,
      outcome: 'unreadable',
      response_body_unreadable: true,
    });
  });

  it('emits authentication attempts and keeps DDC business events at INFO', async () => {
    await SDK.observeApi(
      'Authentication',
      'https://api.example.test/3ds',
      undefined,
      () => undefined,
      () => [],
      'Card',
      undefined,
      () => Promise.resolve({}),
    );
    expect(rows('lifecycle.authentication_started')).toHaveLength(1);
    SDK.logLifecycle('DdcStarted');
    expect(rows('lifecycle.ddc_started')[0].log_type).toBe('INFO');
  });
});

describe('startup API readiness', () => {
  it.each([
    ['Client', 'Config', 'Sessions'],
    ['Client', 'Sessions', 'Config'],
    ['Config', 'Client', 'Sessions'],
    ['Config', 'Sessions', 'Client'],
    ['Sessions', 'Client', 'Config'],
    ['Sessions', 'Config', 'Client'],
  ])('waits for all startup requests: %s, %s, %s', (first, second, third) => {
    const ready = jest.fn();
    const settle = Startup.make(ready);
    settle(first, true);
    settle(second, true);
    expect(ready).not.toHaveBeenCalled();
    settle(third, true);
    settle(third, true);
    expect(ready).toHaveBeenCalledTimes(1);
    expect(ready).toHaveBeenCalledWith(false);
  });

  it('blocks rendered on required API failure and reports optional failure as degraded', () => {
    const ready = jest.fn();
    const failed = Startup.make(ready);
    failed('Client', false);
    failed('Config', true);
    failed('Sessions', true);
    expect(ready).not.toHaveBeenCalled();
    const degraded = Startup.make(ready);
    degraded('Client', true);
    degraded('Config', true);
    degraded('Sessions', false);
    expect(ready).toHaveBeenCalledWith(true);
  });
});
