import type {
  CardDetails,
  TokenizeErrorCode,
  TokenizeErrorType,
  TokenizedCard,
  TokenizeResult,
  VaultType,
} from './types';

export function errorTypeFor(code: TokenizeErrorCode): TokenizeErrorType {
  return code === 'validation_error' || code === 'incomplete_field_set'
    ? 'validation_error'
    : 'api_error';
}

export function errorResult(
  vaultType: VaultType | undefined,
  code: TokenizeErrorCode,
  message: string
): TokenizeResult {
  const type = errorTypeFor(code);
  return {
    status: type === 'validation_error' ? 'validation_error' : 'error',
    vaultType,
    error: { code, message, type },
  };
}

export function tokenizedCardOf(
  details: Partial<CardDetails>
): TokenizedCard | undefined {
  const card: TokenizedCard = {};
  if (details.bin) card.bin = details.bin;
  if (details.last4) card.last4 = details.last4;
  if (details.brand) card.brand = details.brand;
  if (details.expiryMonth) card.expiryMonth = details.expiryMonth;
  if (details.expiryYear) card.expiryYear = details.expiryYear;
  return Object.keys(card).length > 0 ? card : undefined;
}

export function messageOf(error: unknown): string {
  return error instanceof Error ? error.message : String(error);
}
