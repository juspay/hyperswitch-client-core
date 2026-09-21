import type {
  Appearance,
  AppearanceColors,
  AppearanceFont,
  AppearanceShapes,
} from '../../core/types';
import { APPEARANCE_LABELS, pickAllowed } from '../../core/validate';

/* The vault's own flat theme names. Internal: consumers give colors/shapes/font. */
interface VaultVariables {
  colorPrimary?: string;
  colorText?: string;
  colorDanger?: string;
  colorTextPlaceholder?: string;
  colorBackground?: string;
  borderColor?: string;
  borderRadius?: number;
  fontFamily?: string;
  inputFieldHeight?: number;
  borderWidth?: number;
  gap?: number;
  fontScale?: number;
  placeholderTextSizeAdjust?: number;
  errorTextSizeAdjust?: number;
}

export interface VaultAppearance {
  variables?: VaultVariables;
  labels?: 'above' | 'floating' | 'never';
}

export type ColorScheme = 'light' | 'dark';

const STRING_KEYS = [
  'colorPrimary',
  'colorText',
  'colorDanger',
  'colorTextPlaceholder',
  'colorBackground',
  'borderColor',
  'fontFamily',
] as const;
const NUMBER_KEYS = [
  'borderRadius',
  'inputFieldHeight',
  'borderWidth',
  'gap',
  'fontScale',
  'placeholderTextSizeAdjust',
  'errorTextSizeAdjust',
] as const;

function sanitizeVariables(variables: VaultVariables): VaultVariables {
  const out: VaultVariables = {};
  for (const key of STRING_KEYS) {
    const value = variables[key];
    if (typeof value === 'string' && value !== '') out[key] = value;
  }
  for (const key of NUMBER_KEYS) {
    const value = variables[key];
    if (typeof value === 'number' && Number.isFinite(value)) out[key] = value;
  }
  return out;
}

/* react-native-hyperswitch's colors, in the vault's names. Its sheet-wide members
   (loader, overlay, selected*, divider, icon) draw nothing in a field-only form. */
function variablesFromColors(colors: AppearanceColors): VaultVariables {
  return sanitizeVariables({
    colorPrimary: colors.primary,
    colorText: colors.componentText ?? colors.primaryText,
    colorTextPlaceholder: colors.placeholderText ?? colors.secondaryText,
    colorBackground: colors.componentBackground ?? colors.background,
    borderColor: colors.componentBorder,
    colorDanger: colors.error,
  });
}

function variablesFromShapes(shapes: AppearanceShapes): VaultVariables {
  return sanitizeVariables({
    borderRadius: shapes.borderRadius,
    borderWidth: shapes.borderWidth,
    inputFieldHeight: shapes.inputHeight,
    gap: shapes.gap,
  });
}

function variablesFromFont(font: AppearanceFont): VaultVariables {
  return sanitizeVariables({
    fontFamily: font.family,
    fontScale: font.scale,
    placeholderTextSizeAdjust: font.placeholderTextSizeAdjust,
    errorTextSizeAdjust: font.errorTextSizeAdjust,
  });
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null;
}

export function toVaultAppearance(
  layers: readonly Appearance[],
  scheme: ColorScheme = 'light'
): VaultAppearance | undefined {
  let variables: VaultVariables | undefined;
  let labels: VaultAppearance['labels'];

  const merge = (next: VaultVariables) => {
    if (Object.keys(next).length === 0) return;
    variables = { ...(variables ?? {}), ...next };
  };

  for (const layer of layers) {
    const colors = layer.colors?.[scheme] ?? layer.colors?.light;
    if (isRecord(colors)) merge(variablesFromColors(colors));
    if (isRecord(layer.shapes)) merge(variablesFromShapes(layer.shapes));
    if (isRecord(layer.font)) merge(variablesFromFont(layer.font));

    const layerLabels = pickAllowed(
      layer.labels,
      APPEARANCE_LABELS,
      'appearance.labels'
    );
    if (layerLabels) labels = layerLabels;
  }

  if (!variables && !labels) return undefined;
  const out: VaultAppearance = {};
  if (variables) out.variables = variables;
  if (labels) out.labels = labels;
  return out;
}
