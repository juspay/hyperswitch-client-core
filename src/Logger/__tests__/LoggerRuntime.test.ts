import * as Runtime from '../core/LoggerRuntime.bs.js';
import * as Context from '../core/LoggerContext.bs.js';
import * as Config from '../core/LoggerConfig.bs.js';
import * as Queue from '../core/LoggerQueue.bs.js';
import * as Types from '../core/LoggerTypes.bs.js';

jest.mock('../../hooks/WebKit.bs.js', () => ({
  platform: 'android',
  platformString: 'android',
}));
jest.mock('../../types/SdkTypes.bs.js', () => ({
  sdkStateToStrMapper: () => 'PAYMENT_SHEET',
}));
jest.mock('../core/LoggerQueue.bs.js', () => ({
  push: jest.fn(),
  backfillContext: jest.fn(),
  droppedRows: {contents: 0},
  sendFailures: {contents: 0},
}));

const rows = () => (Queue.push as jest.Mock).mock.calls.map(([row]) => row);
const names = () => rows().map(row => row.event_name);
const observe = (
  call: () => any,
  failureOf?: (result: any) => any,
  detailsOf?: (result: any) => any,
) =>
  Runtime.observe(
    'FUNCTION',
    {action: 'call', subject: 'launch_google_pay'},
    Types.quietSuccess,
    undefined,
    undefined,
    30000,
    failureOf,
    detailsOf,
    undefined,
    undefined,
    undefined,
    undefined,
    undefined,
    call,
  );

describe('shared function observation semantics', () => {
  beforeEach(() => {
    jest.useFakeTimers();
    (Queue.push as jest.Mock).mockClear();
    Config.endpoint.contents = 'https://logs.example.test';
    Context.setSessionData(
      `session-${Math.random()}`,
      'pk_test',
      'pay_test',
      undefined,
      undefined,
    );
  });
  afterEach(() => jest.useRealTimers());

  it('returns synchronous results and emits the shared value envelope', () => {
    const result = {ok: true};
    expect(observe(() => result)).toBe(result);
    expect(names()).toEqual(['function.call_returned.launch_google_pay']);
    const row = rows()[0];
    expect(row.component).toBe('MOBILE');
    expect(row.first_event).toBe('true');
    expect(JSON.parse(row.value)).toMatchObject({
      schema_version: 8,
      href: '',
      occurrence: 1,
      details: {duration_ms: expect.any(Number)},
    });
  });

  it('preserves the original promise and records init then done', async () => {
    const promise = Promise.resolve('token');
    expect(observe(() => promise)).toBe(promise);
    expect(names()).toEqual(['function.call_init.launch_google_pay']);
    await promise;
    expect(names()).toEqual([
      'function.call_init.launch_google_pay',
      'function.call_done.launch_google_pay',
    ]);
  });

  it('records timeout and late settlement without cancelling the operation', async () => {
    let resolve: (value: string) => void;
    const promise = new Promise<string>(done => {
      resolve = done;
    });
    observe(() => promise);
    jest.advanceTimersByTime(30000);
    expect(names()[1]).toBe('function.call_timed_out.launch_google_pay');
    resolve('token');
    await promise;
    expect(names()[2]).toBe('function.call_done.launch_google_pay');
    expect(JSON.parse(rows()[2].value).details.settled_after_timeout).toBe(
      true,
    );
  });

  it('records returned failures and keeps cancellation distinct from payment success', () => {
    observe(
      () => ({error: 'failed'}),
      () => ({name: 'GOOGLE_PAY_FAILED', message: undefined, details: []}),
    );
    expect(names()).toEqual(['function.call_failed.launch_google_pay']);
    expect(JSON.parse(rows()[0].value).details.failure_class).toBe(
      'RETURNED_FAILURE',
    );
    observe(
      () => ({cancelled: true}),
      () => undefined,
      () => [['status', 'cancelled']],
    );
    expect(names()[1]).toBe('function.call_returned.launch_google_pay');
    expect(JSON.parse(rows()[1].value).details.status).toBe('cancelled');
    expect(names()).not.toContain('lifecycle.payment_succeeded');
  });

  it('rethrows synchronous errors after logging them', () => {
    const error = new Error('wallet unavailable');
    expect(() =>
      observe(() => {
        throw error;
      }),
    ).toThrow(error);
    expect(names()).toEqual(['function.call_failed.launch_google_pay']);
    expect(JSON.parse(rows()[0].value).details.failure_class).toBe('THREW');
  });

  it('records rejected promises without swallowing the original rejection', async () => {
    const error = new Error('wallet rejected');
    const promise = Promise.reject(error);
    expect(observe(() => promise)).toBe(promise);
    await expect(promise).rejects.toBe(error);
    expect(names()).toEqual([
      'function.call_init.launch_google_pay',
      'function.call_failed.launch_google_pay',
    ]);
    expect(JSON.parse(rows()[1].value).details.failure_class).toBe('REJECTED');
  });

  it('preserves callback arguments, this, arity, and synchronous triggered outcome', () => {
    const handler = function (value: number) {
      return this.offset + value;
    };
    const wrapped = Runtime.observeCallback(
      'FUNCTION',
      {action: 'callback', subject: 'on_approve'},
      Types.quietSuccess,
      undefined,
      undefined,
      undefined,
      undefined,
      undefined,
      undefined,
      undefined,
      handler,
    );
    expect(wrapped.length).toBe(handler.length);
    expect(wrapped.call({offset: 2}, 3)).toBe(5);
    expect(names()).toEqual(['function.callback_triggered.on_approve']);
  });
});
