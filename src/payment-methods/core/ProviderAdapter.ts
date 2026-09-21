import type { ComponentType, ReactNode, Ref } from 'react';
import type {
  CommonEndpoint,
  HyperswitchEnvironment,
  OverrideEndpoints,
} from '../session/fetchVaultDetails';
import type {
  Appearance,
  CardBrandIconDisplay,
  CardDetails,
  CvcIconDisplay,
  ElementType,
  ErrorDisplay,
  FieldChange,
  FieldEvent,
  LabelBehavior,
  FieldHandle,
  FieldStyles,
  SavedCard,
  TokenizeResult,
  VaultType,
} from './types';

export interface ProviderHostProps<Collector = unknown, Data = unknown> {
  vaultData: Data;
  onReady: (collector: Collector) => void;
  onError: (error: unknown) => void;

  onCardDetails?: (details: Partial<CardDetails>) => void;
  children: ReactNode;
}

export interface ProviderFieldProps<Collector = unknown> {
  elementType: ElementType;
  collector: Collector;
  styles?: FieldStyles;
  placeholder?: string;
  label?: string;
  labelBehavior?: LabelBehavior;
  errorDisplay?: ErrorDisplay;
  unstyled?: boolean;

  savedCard?: SavedCard;

  cvcIcon?: CvcIconDisplay;

  cardBrandIcon?: CardBrandIconDisplay;
  onChange?: (change: FieldChange) => void;
  onFocus?: (event: FieldEvent) => void;
  onBlur?: (event: FieldEvent) => void;

  fieldRef?: Ref<FieldHandle>;

  /* Not on the public FieldProps: the payments SDK passes it through its
     bindings so its e2e selectors reach the input. */
  testID?: string;
}

/* What <CardForm> would have given the adapter's Host, for a form that has none. */
export interface CollectorContext {
  appearances: readonly Appearance[];
  locale?: string;
  environment?: HyperswitchEnvironment;
  customEndpoints?: CommonEndpoint | OverrideEndpoints;
  onCardDetails: (details: Partial<CardDetails>) => void;
}

export interface ProviderAdapter<Collector = unknown, Data = unknown> {
  readonly vaultType: VaultType;

  validateVaultData(raw: unknown): Data;

  createCollector?(
    vaultData: Data,
    context?: CollectorContext
  ): Promise<Collector>;

  /* For a collector that only works while something of its own is mounted.
     Whoever owns a detached form mounts this once, for as long as it lives. */
  DetachedHost?: ComponentType<{ collector: Collector }>;

  Host: ComponentType<ProviderHostProps<Collector, Data>>;

  Field: ComponentType<ProviderFieldProps<Collector>>;

  tokenize(
    collector: Collector,
    providerData?: unknown
  ): Promise<TokenizeResult>;
}
