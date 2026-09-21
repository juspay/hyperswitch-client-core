import { readAuthorizationClaims } from './sdkAuthorization';
import type { VaultDetails, VaultType } from '../core/types';

export type HyperswitchEnvironment = 'PROD' | 'SANDBOX' | 'INTEG';

export interface OverrideEndpointConfiguration {
  customBackendEndpoint?: string;
  customLoggingEndpoint?: string;
  customAssetEndpoint?: string;
  customSDKConfigEndpoint?: string;
  customAirborneEndpoint?: string;
}

export interface CommonEndpoint {
  commonEndpoint: string;
}

export interface OverrideEndpoints {
  overrideEndpoints: OverrideEndpointConfiguration;
}

const DEFAULT_BASE_URL: Partial<Record<HyperswitchEnvironment, string>> = {
  SANDBOX: 'https://app.hyperswitch.io/api',
  PROD: 'https://live.hyperswitch.io/api',
};

const DEFAULT_TIMEOUT_MS = 10_000;

export interface FetchVaultDetailsOptions {
  sdkAuthorization: string;

  environment?: HyperswitchEnvironment;

  customEndpoints?: CommonEndpoint | OverrideEndpoints;
  timeoutMs?: number;
  signal?: AbortSignal;
}

export type FetchVaultDetailsResult =
  | {
      ok: true;
      vaultDetails: VaultDetails;
      // expiresAt?: string;
    }
  | { ok: false; message: string };

function camelize(key: string): string {
  return key.replace(/_([a-z0-9])/g, (_, character: string) =>
    character.toUpperCase()
  );
}

function camelizeRecord(raw: Record<string, unknown>): Record<string, unknown> {
  const out: Record<string, unknown> = {};
  for (const [key, value] of Object.entries(raw)) out[camelize(key)] = value;
  return out;
}

const VAULT_TYPES: Record<string, VaultType> = {
  hyperswitch: 'hyperswitch',
  vgs: 'vgs',
  skyflow: 'skyflow',
  basis_theory: 'basis_theory',
  basistheory: 'basis_theory',
  evervault: 'evervault',
};

const ALIASES: Partial<Record<VaultType, Record<string, string>>> = {
  vgs: { externalVaultId: 'vaultId', sdkEnv: 'environment' },
};

function toVaultData(
  vaultType: VaultType,
  raw: Record<string, unknown>
): Record<string, unknown> {
  const camelized = camelizeRecord(raw);
  const aliases = ALIASES[vaultType];
  if (!aliases) return camelized;

  const out: Record<string, unknown> = {};
  for (const [key, value] of Object.entries(camelized)) {
    out[aliases[key] ?? key] = value;
  }
  return out;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

// const expiryOf = (body: Record<string, unknown>) =>
//   typeof body.expires_at === 'string' && body.expires_at
//     ? { expiresAt: body.expires_at }
//     : {};

export function readVaultDetails(
  body: unknown,
  sdkAuthorization: string
): FetchVaultDetailsResult {
  if (!isRecord(body)) {
    return {
      ok: false,
      message: 'The payment-method-session response was not an object.',
    };
  }

  const own = body.vault_details;
  if (isRecord(own)) {
    const ownType =
      typeof own.vault_type === 'string'
        ? VAULT_TYPES[own.vault_type.toLowerCase()]
        : undefined;
    const ownData = isRecord(own.vault_data) ? own.vault_data : undefined;
    if (ownType && ownData) {
      return {
        ok: true,
        vaultDetails: {
          vaultType: ownType,
          vaultData: toVaultData(ownType, ownData),
        },
        // ...(ownType === 'hyperswitch' ? expiryOf(body) : {}),
      };
    }
  }

  const external = body.external_vault_details;
  if (!isRecord(external)) {
    return {
      ok: true,
      vaultDetails: {
        vaultType: 'hyperswitch',
        vaultData: { sdkAuthorization: sdkAuthorization },
      },
      // ...expiryOf(body),
    };
  }

  for (const [key, value] of Object.entries(external)) {
    const vaultType = VAULT_TYPES[key.toLowerCase()];
    if (!vaultType || !isRecord(value)) continue;
    return {
      ok: true,
      vaultDetails: { vaultType, vaultData: toVaultData(vaultType, value) },
    };
  }

  const named = Object.keys(external).join(', ') || 'none';
  return {
    ok: false,
    message: `external_vault_details names no supported vault (got: ${named}). Pass vaultDetails explicitly.`,
  };
}

function resolveBaseUrl(options: FetchVaultDetailsOptions): string | undefined {
  const custom = options.customEndpoints;
  const explicit =
    custom && 'commonEndpoint' in custom
      ? custom.commonEndpoint
      : custom?.overrideEndpoints?.customBackendEndpoint;

  const trimmed = explicit?.trim();
  if (trimmed) return trimmed.replace(/\/+$/, '');
  return DEFAULT_BASE_URL[options.environment ?? 'PROD'];
}

export async function fetchVaultDetails(
  options: FetchVaultDetailsOptions
): Promise<FetchVaultDetailsResult> {
  const claims = readAuthorizationClaims(options.sdkAuthorization);
  if (!claims.ok) return claims;

  const baseUrl = resolveBaseUrl(options);
  if (!baseUrl) {
    return {
      ok: false,
      message: `The ${options.environment} environment has no public host. Pass customEndpoints.`,
    };
  }

  const url = `${baseUrl}/v1/payment-method-sessions/${encodeURIComponent(
    claims.claims.paymentMethodSessionId
  )}`;

  const controller = new AbortController();
  const caller = options.signal;
  if (caller) {
    if (caller.aborted) controller.abort();
    else caller.addEventListener('abort', () => controller.abort());
  }

  let timedOut = false;
  const timer = setTimeout(() => {
    timedOut = true;
    controller.abort();
  }, options.timeoutMs ?? DEFAULT_TIMEOUT_MS);

  try {
    const response = await fetch(url, {
      method: 'GET',
      headers: {
        Accept: 'application/json',
        Authorization: options.sdkAuthorization,
      },
      signal: controller.signal,
    });

    if (!response.ok) {
      return {
        ok: false,
        message: `The payment-method-session lookup returned status ${response.status}.`,
      };
    }

    let body: unknown;
    try {
      body = await response.json();
    } catch {
      return {
        ok: false,
        message: 'The payment-method-session response was not readable JSON.',
      };
    }

    return readVaultDetails(body, options.sdkAuthorization);
  } catch (error) {
    if (timedOut) {
      return {
        ok: false,
        message: 'The payment-method-session lookup timed out.',
      };
    }
    if (controller.signal.aborted) {
      return {
        ok: false,
        message: 'The payment-method-session lookup was aborted.',
      };
    }
    return {
      ok: false,
      message: error instanceof Error ? error.message : String(error),
    };
  } finally {
    clearTimeout(timer);
  }
}
