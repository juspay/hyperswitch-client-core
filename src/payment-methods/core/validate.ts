import type {
  AppearanceLabels,
  CardBrandIconDisplay,
  CvcIconDisplay,
  ErrorDisplay,
  LabelBehavior,
} from './types';

export const CVC_ICONS: readonly CvcIconDisplay[] = ['hidden', 'default'];
export const CARD_BRAND_ICONS: readonly CardBrandIconDisplay[] = [
  'standard',
  'hidden',
  'animated',
  'hideGeneric',
];
export const APPEARANCE_LABELS: readonly AppearanceLabels[] = [
  'above',
  'floating',
  'never',
];

export const LABEL_BEHAVIORS: readonly LabelBehavior[] = APPEARANCE_LABELS;

export const ERROR_DISPLAYS: readonly ErrorDisplay[] = [
  'none',
  'colorOnly',
  'inline',
];

function warnUnknownValue(
  value: unknown,
  allowed: readonly string[],
  path: string
): void {
  if (!__DEV__) return;
  console.warn(
    `[payment-methods] Unknown value ${JSON.stringify(value)} for ${path}; expected one of ${allowed.join(', ')}. Using the default.`
  );
}

export function pickAllowed<T extends string>(
  value: unknown,
  allowed: readonly T[],
  path: string
): T | undefined {
  if (value === undefined || value === null || value === '') return undefined;
  if (
    typeof value === 'string' &&
    (allowed as readonly string[]).includes(value)
  ) {
    return value as T;
  }
  warnUnknownValue(value, allowed, path);
  return undefined;
}

export function pickString(value: unknown): string | undefined {
  return typeof value === 'string' ? value : undefined;
}
