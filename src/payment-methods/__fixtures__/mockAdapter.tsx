import { Fragment, useEffect, useImperativeHandle } from 'react';
import { Text } from 'react-native';
import { fieldChange } from '../core/fieldChange';
import type { FieldChangeInput } from '../core/fieldChange';
import type {
  ProviderAdapter,
  ProviderFieldProps,
  ProviderHostProps,
} from '../core/ProviderAdapter';
import type {
  CardDetails,
  ElementType,
  TokenizeResult,
  VaultType,
} from '../core/types';

export interface MockAdapterOptions {
  vaultType?: VaultType;

  readyDelayMs?: number;

  neverReady?: boolean;

  failOnInit?: unknown;

  tokenizeResult?: TokenizeResult;

  fieldState?: FieldChangeInput;

  cardDetails?: Partial<CardDetails>;

  onTokenize?: () => void;

  onFieldCommand?: (
    elementType: ElementType,
    name: 'focus' | 'blur' | 'clear'
  ) => void;
}

export function createMockAdapter(
  options: MockAdapterOptions = {}
): ProviderAdapter {
  const vaultType: VaultType = options.vaultType ?? 'vgs';

  function Host({
    onReady,
    onError,
    onCardDetails,
    children,
  }: ProviderHostProps) {
    useEffect(() => {
      if (options.failOnInit !== undefined) {
        onError(options.failOnInit);
        return;
      }
      if (options.neverReady) return;

      const delay = options.readyDelayMs ?? 0;
      const timer = setTimeout(() => {
        onReady({ mock: true });
        if (options.cardDetails) onCardDetails?.(options.cardDetails);
      }, delay);
      return () => clearTimeout(timer);
    }, [onReady, onError, onCardDetails]);

    return <Fragment>{children}</Fragment>;
  }

  function Field({
    elementType,
    onChange,
    styles,
    savedCard,
    placeholder,
    cvcIcon,
    cardBrandIcon,
    label,
    labelBehavior,
    errorDisplay,
    unstyled,
    testID,
    fieldRef,
  }: ProviderFieldProps) {
    useImperativeHandle(
      fieldRef,
      () => ({
        focus: () => options.onFieldCommand?.(elementType, 'focus'),
        blur: () => options.onFieldCommand?.(elementType, 'blur'),
        clear: () => options.onFieldCommand?.(elementType, 'clear'),
      }),
      [elementType]
    );
    const state = options.fieldState;
    useEffect(() => {
      if (state) onChange?.(fieldChange(elementType, state));
    }, [elementType, onChange, state]);
    return (
      <Text
        testID={`mock-field-${elementType}`}
        style={styles?.container}
        accessibilityLabel={
          savedCard
            ? `saved:${savedCard.paymentMethodToken}:${savedCard.paymentMethodData?.card?.cardNetwork ?? ''}`
            : undefined
        }
        accessibilityHint={cvcIcon}
        accessibilityValue={{
          /* Every forwarded prop, for tests to read back; JSON drops the unset ones. */
          text: JSON.stringify({
            placeholder,
            cardBrandIcon,
            label,
            labelBehavior,
            errorDisplay,
            unstyled,
            testID,
          }),
        }}
      >{`mock:${elementType}`}</Text>
    );
  }

  return {
    vaultType,
    validateVaultData: (raw) => raw,
    createCollector: async () => {
      if (options.failOnInit !== undefined) throw options.failOnInit;
      if (options.readyDelayMs) {
        await new Promise((resolve) =>
          setTimeout(resolve, options.readyDelayMs)
        );
      }
      return { mock: true };
    },
    Host,
    Field,
    tokenize: async () => {
      options.onTokenize?.();
      return (
        options.tokenizeResult ?? {
          status: 'success',
          vaultType,
          data: { tokens: { card_number: 'tok_mock' } },
        }
      );
    },
  };
}
