import type { StyleProp, TextStyle, ViewStyle } from 'react-native';

export type FormId = string;

export type VaultType =
  'hyperswitch' | 'vgs' | 'skyflow' | 'basis_theory' | 'evervault';

export type ElementType =
  'cardNumber' | 'cardExpiry' | 'cardCvc' | 'cardholderName';

export interface VaultDetails {
  vaultType: VaultType;

  vaultData: unknown;
}

export interface FieldStyles {
  container?: StyleProp<ViewStyle>;

  input?: StyleProp<TextStyle>;
}

/* The names @juspay-tech/react-native-hyperswitch uses. The vault draws fields only, so
   the sheet-wide members (loader, overlay, selected*) have no effect here. */
export interface AppearanceColors {
  primary?: string;
  background?: string;
  componentBackground?: string;
  componentBorder?: string;
  componentDivider?: string;
  componentText?: string;
  primaryText?: string;
  secondaryText?: string;
  placeholderText?: string;
  icon?: string;
  error?: string;
  loaderBackground?: string;
  loaderForeground?: string;
  overlay?: string;
  selectedComponentBackground?: string;
  selectedComponentBorder?: string;
  selectedComponentBorderWidth?: number;
  selectedComponentDivider?: string;
  selectedComponentText?: string;
}

export interface AppearanceColorScheme {
  light?: AppearanceColors;
  dark?: AppearanceColors;
}

export interface AppearanceShapes {
  borderRadius?: number;
  borderWidth?: number;
  inputHeight?: number;
  gap?: number;
}

export interface AppearanceFont {
  family?: string;
  scale?: number;
  placeholderTextSizeAdjust?: number;
  errorTextSizeAdjust?: number;
}

export type LabelBehavior = 'above' | 'floating' | 'never';

export type AppearanceLabels = LabelBehavior;

export interface Appearance extends FieldStyles {
  fields?: Partial<Record<ElementType, FieldStyles>>;

  colors?: AppearanceColorScheme;

  shapes?: AppearanceShapes;

  font?: AppearanceFont;

  labels?: AppearanceLabels;
}

export interface SavedCardData {
  cardNetwork?: string;
}

export interface SavedCardPaymentMethodData {
  card?: SavedCardData;
}

export interface SavedCard {
  paymentMethodToken?: string;

  paymentMethodData?: SavedCardPaymentMethodData;
}

export type CvcIconDisplay = 'hidden' | 'default';

export type CardBrandIconDisplay =
  'standard' | 'hidden' | 'animated' | 'hideGeneric';

export type ErrorDisplay = 'none' | 'colorOnly' | 'inline';

export interface FieldOptions {
  placeholder?: string;

  label?: string;

  labelBehavior?: LabelBehavior;

  errorDisplay?: ErrorDisplay;

  unstyled?: boolean;

  cvcIcon?: CvcIconDisplay;

  cardBrandIcon?: CardBrandIconDisplay;

  savedCard?: SavedCard;
}

export interface FieldEvent {
  elementType: ElementType;
}

export interface FieldChange {
  elementType: ElementType;
  empty: boolean;
  complete: boolean;
  valid: boolean;
  brand?: string;
  error?: string;
  touched: boolean;
}

export interface CardDetails {
  bin: string | null;
  extendedBin: string | null;
  last4: string | null;
  brand: string | null;
  expiryMonth: string | null;
  expiryYear: string | null;
  formattedExpiry: string | null;
  isCardNumberComplete: boolean;
  isCvcComplete: boolean;
  isExpiryComplete: boolean;
  isCardNumberValid: boolean;
  isExpiryValid: boolean;
}

export interface CardFormEvent {
  elementType: 'cardForm';
}

export interface CardFormChange {
  elementType: 'cardForm';
  eventName: 'cardDetailsChange';
  payload: CardDetails;

  complete: boolean;

  valid: boolean;

  fields: Partial<Record<ElementType, FieldChange>>;
}

export type TokenizeStatus = 'success' | 'validation_error' | 'error';

export type TokenizeErrorType = 'validation_error' | 'api_error' | 'card_error';

export type TokenizeErrorCode =
  | 'validation_error'
  | 'incomplete_field_set'
  | 'sdk_not_ready'
  | 'unsupported_configuration'
  | 'session_expired'
  | 'session_consumed'
  | 'invalid_session'
  | 'unknown_outcome'
  | 'tokenization_failed';

export interface TokenizeError {
  code: TokenizeErrorCode;
  message: string;
  type: TokenizeErrorType;
}

export interface TokenizedCard {
  bin?: string;
  last4?: string;
  brand?: string;
  expiryMonth?: string;
  expiryYear?: string;
}

export interface TokenizeData {
  tokens?: Record<string, unknown>;

  raw?: unknown;

  savedCard?: SavedCard;
}

export type TokenizeResult =
  | {
      status: 'success';
      vaultType?: VaultType;
      data?: TokenizeData;
      card?: TokenizedCard;
    }
  | {
      status: 'validation_error' | 'error';
      vaultType?: VaultType;
      error: TokenizeError;
    };

export type FormStatus = 'initializing' | 'ready' | 'tokenizing' | 'error';

export interface CardFormInstance {
  tokenize(providerData?: unknown): Promise<TokenizeResult>;
  readonly status: FormStatus;
}

export interface CardFormHandle {
  tokenize(providerData?: unknown): Promise<TokenizeResult>;
  readonly status: FormStatus;
}

export interface FieldHandle {
  focus(): void;
  blur(): void;
  clear(): void;
}
