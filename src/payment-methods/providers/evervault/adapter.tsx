import { useCallback, useEffect, useRef } from 'react';
import type { ComponentProps } from 'react';
import { StyleSheet } from 'react-native';

import { canonicalBrand } from '../../core/fieldChange';
import type { ProviderAdapter } from '../../core/ProviderAdapter';
import { errorResult } from '../../core/results';
import type {
  CardDetails,
  ElementType,
  TokenizeResult,
} from '../../core/types';
import type { EvervaultVaultData } from './types';

declare const require: (moduleId: string) => unknown;

type EvervaultSdk = any;

let evervaultSdk: EvervaultSdk | null = null;
try {
  evervaultSdk = require('@evervault/react-native') as EvervaultSdk;
} catch {
  evervaultSdk = null;
}

export const evervaultSdkAvailable = evervaultSdk != null;

const { EvervaultProvider, Card, CardNumber, CardExpiry, CardCvc, CardHolder } =
  evervaultSdk ?? ({} as EvervaultSdk);

const VAULT_TYPE = 'evervault' as const;

type InputStyle = ComponentProps<typeof CardNumber>['style'];

interface EvervaultCollector {
  getPayload: () => any | null;
}

const ERROR_FIELD: Record<string, ElementType> = {
  name: 'cardholderName',
  number: 'cardNumber',
  expiry: 'cardExpiry',
  cvc: 'cardCvc',
};

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

function validateVaultData(raw: unknown): EvervaultVaultData {
  if (
    !isRecord(raw) ||
    typeof raw.teamId !== 'string' ||
    !raw.teamId ||
    typeof raw.appId !== 'string' ||
    !raw.appId
  ) {
    throw new Error(
      'Evervault vaultData requires non-empty string "teamId" and "appId". Received: ' +
        JSON.stringify(raw)
    );
  }
  return raw as unknown as EvervaultVaultData;
}

const fourDigitYear = (year: unknown): string | null => {
  if (typeof year !== 'string' || !year) return null;
  return year.length === 2 ? `20${year}` : year;
};

function cardDetailsOf(payload: any): Partial<CardDetails> {
  const card = payload?.card ?? {};
  const expiryMonth =
    typeof card.expiry?.month === 'string' && card.expiry.month
      ? card.expiry.month
      : null;
  return {
    bin: typeof card.bin === 'string' && card.bin ? card.bin : null,
    last4:
      typeof card.lastFour === 'string' && card.lastFour ? card.lastFour : null,
    brand: canonicalBrand(card.brand) ?? null,
    expiryMonth,
    expiryYear: fourDigitYear(card.expiry?.year),
  };
}

const Host: ProviderAdapter['Host'] = ({
  vaultData,
  onReady,
  onError,
  onCardDetails,
  children,
}) => {
  const data = vaultData as EvervaultVaultData;
  const payloadRef = useRef<any | null>(null);

  const handleChange = useCallback(
    (payload: any) => {
      payloadRef.current = payload;
      onCardDetails?.(cardDetailsOf(payload));
    },
    [onCardDetails]
  );

  const collectorRef = useRef<EvervaultCollector | null>(null);
  if (collectorRef.current === null) {
    collectorRef.current = { getPayload: () => payloadRef.current };
  }
  const collector = collectorRef.current;

  useEffect(() => {
    onReady(collector);
  }, [collector, onReady]);

  return (
    <EvervaultProvider teamId={data.teamId} appId={data.appId}>
      <Card onChange={handleChange} onError={onError}>
        {children}
      </Card>
    </EvervaultProvider>
  );
};

const Field: ProviderAdapter['Field'] = ({
  elementType,
  placeholder,
  styles,
}) => {
  const inputStyle = StyleSheet.flatten([
    styles?.container,
    styles?.input,
  ]) as InputStyle;
  switch (elementType) {
    case 'cardNumber':
      return <CardNumber placeholder={placeholder} style={inputStyle} />;
    case 'cardExpiry':
      return <CardExpiry placeholder={placeholder} style={inputStyle} />;
    case 'cardCvc':
      return <CardCvc placeholder={placeholder} style={inputStyle} />;
    case 'cardholderName':
      return <CardHolder placeholder={placeholder} style={inputStyle} />;
  }
};

const tokenize: ProviderAdapter['tokenize'] = async (
  collector
): Promise<TokenizeResult> => {
  const payload = (collector as EvervaultCollector).getPayload();

  if (!payload) {
    return errorResult(
      VAULT_TYPE,
      'validation_error',
      'No card details have been entered yet.'
    );
  }

  if (!payload.isComplete) {
    const problems = Object.entries(payload.errors ?? {}).map(
      ([field, message]) => `${ERROR_FIELD[field] ?? field}: ${String(message)}`
    );
    return errorResult(
      VAULT_TYPE,
      'validation_error',
      problems.length > 0 ? problems.join(', ') : 'Card details are incomplete.'
    );
  }

  const card = payload.card;
  return {
    status: 'success',
    vaultType: VAULT_TYPE,
    data: {
      raw: card,
      tokens: {
        name: card.name,
        number: card.number,
        expiry: card.expiry,
        cvc: card.cvc,
      },
    },
  };
};

export const evervaultAdapter: ProviderAdapter = {
  vaultType: VAULT_TYPE,
  validateVaultData,
  Host,
  Field,
  tokenize,
};
