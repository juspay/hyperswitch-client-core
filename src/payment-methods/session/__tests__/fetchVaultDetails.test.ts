import {
  describe,
  it,
  expect,
  jest,
  beforeEach,
  afterEach,
} from '@jest/globals';

import { fetchVaultDetails, readVaultDetails } from '../fetchVaultDetails';
import { decodeBase64, readAuthorizationClaims } from '../sdkAuthorization';

const authorization = (claims: string) =>
  Buffer.from(claims, 'utf8').toString('base64');

const VALID_AUTH = authorization(
  'payment_method_session_id=0a_pms_0192,profile_id=pro_456'
);

type FetchArgs = [string, { headers?: Record<string, string> }];

const okResponse = (body: unknown) => ({
  ok: true,
  status: 200,
  json: async () => body,
});

const sessionBody = (external: unknown) => ({
  id: '0a_pms_0192',
  client_secret: 'cs_9wcXDRVkfEtLEsSnYKgQ',
  external_vault_details: external,
});

const original = globalThis.fetch;
let fetchMock: jest.Mock<(...args: FetchArgs) => Promise<unknown>>;

beforeEach(() => {
  fetchMock = jest.fn<(...args: FetchArgs) => Promise<unknown>>();
  (globalThis as { fetch?: unknown }).fetch = fetchMock;
});

afterEach(() => {
  (globalThis as { fetch?: unknown }).fetch = original;
});

describe('sdkAuthorization', () => {
  it('decodes base64, including the URL-safe alphabet and missing padding', () => {
    expect(decodeBase64('cHJvZmlsZV9pZD0uLi4=')).toBe('profile_id=...');
    expect(decodeBase64('cHJvZmlsZV9pZD0uLi4')).toBe('profile_id=...');
    expect(decodeBase64('!!not base64!!')).toBeUndefined();
  });

  it('reads the session id out of the claims', () => {
    const result = readAuthorizationClaims(VALID_AUTH);
    expect(result.ok && result.claims).toEqual({
      paymentMethodSessionId: '0a_pms_0192',
    });
  });

  it('names what is missing', () => {
    expect(readAuthorizationClaims('   ')).toEqual({
      ok: false,
      message: 'sdkAuthorization is empty.',
    });
    expect(readAuthorizationClaims('!!!')).toEqual({
      ok: false,
      message: 'sdkAuthorization is not valid base64.',
    });

    const noSession = readAuthorizationClaims(
      authorization('profile_id=pro_1')
    );
    expect(noSession.ok).toBe(false);
    expect(!noSession.ok && noSession.message).toMatch(
      /payment_method_session_id/
    );
  });
});

describe('readVaultDetails', () => {
  it('maps the documented VGS shape onto VgsVaultData', () => {
    const result = readVaultDetails(
      sessionBody({ vgs: { external_vault_id: 'tnt_abc', sdk_env: 'sandbox' } }),
      VALID_AUTH
    );
    expect(result).toEqual({
      ok: true,
      vaultDetails: {
        vaultType: 'vgs',
        vaultData: { vaultId: 'tnt_abc', environment: 'sandbox' },
      },
    });
  });

  it('reads the Hyperswitch vault off vault_details, ahead of external', () => {
    const result = readVaultDetails({
      id: '0a_pms_0192',
      vault_details: {
        vault_type: 'hyperswitch',
        vault_data: { sdk_authorization: 'auth_123' },
      },
      external_vault_details: {
        vgs: { external_vault_id: 'tnt_abc', sdk_env: 'sandbox' },
      },
    }, VALID_AUTH);
    expect(result).toEqual({
      ok: true,
      vaultDetails: {
        vaultType: 'hyperswitch',
        vaultData: { sdkAuthorization: 'auth_123' },
      },
    });
  });

  it('falls through to external_vault_details when vault_details names another vault', () => {
    const result = readVaultDetails({
      vault_details: { vault_type: 'something_else', vault_data: {} },
      external_vault_details: {
        vgs: { external_vault_id: 'tnt_abc', sdk_env: 'sandbox' },
      },
    }, VALID_AUTH);
    expect(result.ok && result.vaultDetails.vaultType).toBe('vgs');
  });

  it('camelizes any other supported vault it is handed', () => {
    const result = readVaultDetails(
      sessionBody({
        skyflow: { vault_id: 'v1', vault_url: 'https://x', table: 't' },
      }),
      VALID_AUTH
    );
    expect(result).toEqual({
      ok: true,
      vaultDetails: {
        vaultType: 'skyflow',
        vaultData: { vaultId: 'v1', vaultUrl: 'https://x', table: 't' },
      },
    });
  });

  it('falls back to the Hyperswitch vault when the session names no external vault', () => {
    const result = readVaultDetails(sessionBody(undefined), VALID_AUTH);
    expect(result).toEqual({
      ok: true,
      vaultDetails: {
        vaultType: 'hyperswitch',
        vaultData: { sdkAuthorization: VALID_AUTH },
      },
    });
  });

  it('says so when the session names no supported vault', () => {
    const unknown = readVaultDetails(
      sessionBody({ some_other_vault: {} }),
      VALID_AUTH
    );
    expect(unknown.ok).toBe(false);
    expect(!unknown.ok && unknown.message).toMatch(/some_other_vault/);
  });
});

describe('fetchVaultDetails', () => {
  it('GETs the payment-method session with the authorization header', async () => {
    fetchMock.mockResolvedValue(
      okResponse(
        sessionBody({
          vgs: { external_vault_id: 'tnt_abc', sdk_env: 'sandbox' },
        })
      )
    );

    const result = await fetchVaultDetails({ sdkAuthorization: VALID_AUTH });

    expect(result.ok && result.vaultDetails.vaultType).toBe('vgs');
    const [url, init] = fetchMock.mock.calls[0]!;

    expect(url).toBe(
      'https://live.hyperswitch.io/api/v1/payment-method-sessions/0a_pms_0192'
    );
    expect(init.headers).toMatchObject({ Authorization: VALID_AUTH });
    expect('X-Profile-Id' in (init.headers ?? {})).toBe(false);
  });

  it('uses the SANDBOX host when asked for it', async () => {
    fetchMock.mockResolvedValue(
      okResponse(sessionBody({ vgs: { external_vault_id: 'x' } }))
    );
    await fetchVaultDetails({
      sdkAuthorization: VALID_AUTH,
      environment: 'SANDBOX',
    });
    expect(fetchMock.mock.calls[0]![0]).toBe(
      'https://app.hyperswitch.io/api/v1/payment-method-sessions/0a_pms_0192'
    );
  });

  it('refuses INTEG without customEndpoints, since it has no public host', async () => {
    const result = await fetchVaultDetails({
      sdkAuthorization: VALID_AUTH,
      environment: 'INTEG',
    });
    expect(result.ok).toBe(false);
    expect(!result.ok && result.message).toMatch(/no public host/);
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('reads an overrideEndpoints backend endpoint', async () => {
    fetchMock.mockResolvedValue(
      okResponse(sessionBody({ vgs: { external_vault_id: 'x' } }))
    );
    await fetchVaultDetails({
      sdkAuthorization: VALID_AUTH,
      environment: 'INTEG',
      customEndpoints: {
        overrideEndpoints: { customBackendEndpoint: 'https://integ.acme.test' },
      },
    });
    expect(fetchMock.mock.calls[0]![0]).toBe(
      'https://integ.acme.test/v1/payment-method-sessions/0a_pms_0192'
    );
  });

  it('uses the PROD host and explicit customEndpoints', async () => {
    fetchMock.mockResolvedValue(
      okResponse(sessionBody({ vgs: { external_vault_id: 'x' } }))
    );

    await fetchVaultDetails({
      sdkAuthorization: VALID_AUTH,
      environment: 'PROD',
    });
    expect(fetchMock.mock.calls[0]![0]).toBe(
      'https://live.hyperswitch.io/api/v1/payment-method-sessions/0a_pms_0192'
    );

    await fetchVaultDetails({
      sdkAuthorization: VALID_AUTH,
      environment: 'PROD',
      customEndpoints: { commonEndpoint: 'https://vault.acme.test/api/' },
    });
    expect(fetchMock.mock.calls[1]![0]).toBe(
      'https://vault.acme.test/api/v1/payment-method-sessions/0a_pms_0192'
    );
  });

  it('never throws: a non-2xx, unreadable body, or a thrown fetch all come back as a result', async () => {
    fetchMock.mockResolvedValue({
      ok: false,
      status: 401,
      json: async () => ({}),
    });
    const unauthorized = await fetchVaultDetails({
      sdkAuthorization: VALID_AUTH,
    });
    expect(unauthorized).toEqual({
      ok: false,
      message: 'The payment-method-session lookup returned status 401.',
    });

    fetchMock.mockResolvedValue({
      ok: true,
      status: 200,
      json: async () => {
        throw new Error('bad json');
      },
    });
    const unreadable = await fetchVaultDetails({
      sdkAuthorization: VALID_AUTH,
    });
    expect(unreadable.ok).toBe(false);
    expect(!unreadable.ok && unreadable.message).toMatch(/readable JSON/);

    fetchMock.mockRejectedValue(new Error('network down'));
    const offline = await fetchVaultDetails({ sdkAuthorization: VALID_AUTH });
    expect(offline).toEqual({ ok: false, message: 'network down' });
  });

  it('does not call the network when the authorization carries no session id', async () => {
    const result = await fetchVaultDetails({
      sdkAuthorization: authorization('profile_id=pro_1'),
    });
    expect(result.ok).toBe(false);
    expect(fetchMock).not.toHaveBeenCalled();
  });
});
