import { canonicalBrand } from './fieldChange';
import { errorResult } from './results';
import type {
  ElementType,
  FieldOptions,
  SavedCard,
  TokenizeResult,
  VaultType,
} from './types';

export interface MountedField {
  elementType: ElementType;
  savedCard?: SavedCard;
}

export type MountedFields = Partial<Record<ElementType, MountedField>>;

export function mountedField(
  elementType: ElementType,
  options: FieldOptions | undefined
): MountedField {
  return options?.savedCard
    ? { elementType, savedCard: options.savedCard }
    : { elementType };
}

export function savedCardOf(mounted: MountedFields): SavedCard | undefined {
  return mounted.cardCvc?.savedCard;
}

export const savedCardToken = (savedCard: SavedCard): string =>
  typeof savedCard.paymentMethodToken === 'string'
    ? savedCard.paymentMethodToken.trim()
    : '';

export const savedCardNetwork = (savedCard: SavedCard): string =>
  savedCard.paymentMethodData?.card?.cardNetwork ?? '';

const hasToken = (savedCard: SavedCard) => savedCardToken(savedCard) !== '';

export interface UnresolvedVault {
  pending: boolean;

  reason?: string;
}

export function checkConfiguration(
  vaultType: VaultType | undefined,
  mounted: MountedFields,
  unresolved?: UnresolvedVault
): TokenizeResult | undefined {
  if (!vaultType) {
    if (unresolved?.pending) {
      return errorResult(
        undefined,
        'sdk_not_ready',
        'The vault configuration is still being looked up. Try again once the session has loaded.'
      );
    }
    return errorResult(
      undefined,
      'unsupported_configuration',
      unresolved?.reason ??
        'No vault configuration. Pass options.vaultDetails or options.sdkAuthorization on ' +
          '<HyperPaymentMethodSession>, or vaultDetails directly on <CardForm>.'
    );
  }

  const fields = Object.values(mounted).filter(
    (field): field is MountedField => field !== undefined
  );

  const misplaced = fields.find(
    (field) => field.savedCard && field.elementType !== 'cardCvc'
  );
  if (misplaced) {
    return errorResult(
      vaultType,
      'unsupported_configuration',
      `savedCard belongs on a CVC field; it was passed to ${misplaced.elementType}.`
    );
  }

  const savedCard = savedCardOf(mounted);
  if (!savedCard) return undefined;

  if (!hasToken(savedCard)) {
    return errorResult(
      vaultType,
      'validation_error',
      "savedCard needs the stored card's paymentMethodToken. Pass the listing entry your backend returned."
    );
  }

  const others = fields.filter((field) => field.elementType !== 'cardCvc');
  if (others.length > 0) {
    return errorResult(
      vaultType,
      'unsupported_configuration',
      'A CVC field with savedCard must be the only field in the form. Remove ' +
        others.map((field) => `<${field.elementType}>`).join(', ') +
        ', or drop savedCard to collect a whole card.'
    );
  }

  return undefined;
}

export function withSavedCard(
  result: TokenizeResult,
  savedCard: SavedCard | undefined
): TokenizeResult {
  if (!savedCard || result.status !== 'success') return result;

  const network = savedCardNetwork(savedCard);
  const cardNetwork = network
    ? (canonicalBrand(network) ?? network)
    : undefined;

  return {
    ...result,
    data: {
      ...result.data,
      savedCard: {
        paymentMethodToken: savedCardToken(savedCard),
        ...(cardNetwork
          ? { paymentMethodData: { card: { cardNetwork } } }
          : {}),
      },
    },
  };
}
