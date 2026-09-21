const BASE64_ALPHABET =
  'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

export function decodeBase64(input: string): string | undefined {
  const normalized = input
    .replace(/\s/g, '')
    .replace(/-/g, '+')
    .replace(/_/g, '/')
    .replace(/[=]+$/, '');

  let out = '';
  let buffer = 0;
  let bits = 0;

  for (const symbol of normalized) {
    const position = BASE64_ALPHABET.indexOf(symbol);
    if (position < 0) return undefined;
    buffer = buffer * 64 + position;
    bits += 6;
    if (bits >= 8) {
      bits -= 8;
      out += String.fromCharCode((buffer >> bits) & 0xff);
      buffer &= (1 << bits) - 1;
    }
  }

  return out;
}

export function parseAuthorizationClaims(
  sdkAuthorization: string
): Record<string, string> | undefined {
  const decoded = decodeBase64(sdkAuthorization.trim());
  if (decoded === undefined) return undefined;

  const claims: Record<string, string> = {};
  for (const pair of decoded.split(',')) {
    const separator = pair.indexOf('=');
    if (separator <= 0) continue;
    const key = pair.slice(0, separator).trim();
    const value = pair.slice(separator + 1).trim();
    if (key && value && claims[key] === undefined) claims[key] = value;
  }
  return claims;
}

export interface AuthorizationClaims {
  paymentMethodSessionId: string;
}

export type ClaimsResult =
  { ok: true; claims: AuthorizationClaims } | { ok: false; message: string };

export function readAuthorizationClaims(
  sdkAuthorization: string
): ClaimsResult {
  if (sdkAuthorization.trim().length === 0) {
    return { ok: false, message: 'sdkAuthorization is empty.' };
  }

  const claims = parseAuthorizationClaims(sdkAuthorization);
  if (!claims) {
    return { ok: false, message: 'sdkAuthorization is not valid base64.' };
  }

  const paymentMethodSessionId = claims.payment_method_session_id;
  if (!paymentMethodSessionId) {
    return {
      ok: false,
      message:
        'sdkAuthorization does not contain payment_method_session_id. Pass vaultDetails instead.',
    };
  }

  return { ok: true, claims: { paymentMethodSessionId } };
}
