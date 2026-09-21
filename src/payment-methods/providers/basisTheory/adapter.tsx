import { createRef, useEffect, useRef } from 'react';
import type { RefObject } from 'react';
import { StyleSheet } from 'react-native';

import { fieldChange } from '../../core/fieldChange';
import type { ProviderAdapter } from '../../core/ProviderAdapter';
import { errorResult, messageOf } from '../../core/results';
import type { TokenizeResult } from '../../core/types';
import type { BasisTheoryVaultData } from './types';

declare const require: (moduleId: string) => unknown;

type BasisTheorySdk = any;

let basisTheorySdk: BasisTheorySdk | null = null;
try {
  basisTheorySdk =
    require('@basis-theory/react-native-elements') as BasisTheorySdk;
} catch {
  basisTheorySdk = null;
}

export const basisTheorySdkAvailable = basisTheorySdk != null;

const {
  BasisTheoryProvider,
  useBasisTheory,
  CardNumberElement,
  CardExpirationDateElement,
  CardVerificationCodeElement,
  TextElement,
} = basisTheorySdk ?? ({} as BasisTheorySdk);

const VAULT_TYPE = 'basis_theory' as const;

interface BtRefs {
  cardNumber: RefObject<any | null>;
  cardExpiry: RefObject<any | null>;
  cardCvc: RefObject<any | null>;
  cardholderName: RefObject<any | null>;
}

interface BtInstance {
  tokens: {
    create: (
      token: { type: string; data: Record<string, unknown> },
      options?: unknown
    ) => Promise<unknown>;
  };
}

interface BtCollector {
  bt: BtInstance;
  refs: BtRefs;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

function validateVaultData(raw: unknown): BasisTheoryVaultData {
  if (!isRecord(raw) || typeof raw.apiKey !== 'string' || !raw.apiKey) {
    throw new Error(
      'Basis Theory vaultData requires a non-empty string "apiKey". Received: ' +
        JSON.stringify(raw)
    );
  }
  return raw as unknown as BasisTheoryVaultData;
}

const Host: ProviderAdapter['Host'] = ({
  vaultData,
  onReady,
  onError,
  children,
}) => {
  const data = vaultData as BasisTheoryVaultData;
  const { bt, error } = useBasisTheory(
    data.apiKey,
    data.baseUrl ? { apiBaseUrl: data.baseUrl } : undefined
  );

  const refsRef = useRef<BtRefs | null>(null);
  if (refsRef.current === null) {
    refsRef.current = {
      cardNumber: createRef<any>(),
      cardExpiry: createRef<any>(),
      cardCvc: createRef<any>(),
      cardholderName: createRef<any>(),
    };
  }
  const refs = refsRef.current;

  useEffect(() => {
    if (error) {
      onError(error);
      return;
    }
    if (bt) {
      onReady({ bt: bt as unknown as BtInstance, refs });
    }
  }, [bt, error, refs, onReady, onError]);

  return <BasisTheoryProvider bt={bt}>{children}</BasisTheoryProvider>;
};

interface BtChangeEvent {
  empty?: boolean;
  valid?: boolean;
  errors?: Array<{ type: string }>;
  brand?: string;
}

const Field: ProviderAdapter['Field'] = ({
  elementType,
  collector,
  placeholder,
  styles,
  onChange,
}) => {
  const { refs } = collector as BtCollector;

  const mergedStyle = StyleSheet.flatten([styles?.container, styles?.input]);
  const handleChange = onChange
    ? (event: unknown) => {
        const e = (event ?? {}) as BtChangeEvent;
        onChange(
          fieldChange(elementType, {
            empty: e.empty ?? true,
            valid: Boolean(e.valid),
            brand: e.brand,
            error: e.errors?.[0]?.type,
          })
        );
      }
    : undefined;
  switch (elementType) {
    case 'cardNumber':
      return (
        <CardNumberElement
          btRef={refs.cardNumber}
          placeholder={placeholder}
          style={mergedStyle}
          onChange={handleChange}
        />
      );
    case 'cardExpiry':
      return (
        <CardExpirationDateElement
          btRef={refs.cardExpiry}
          placeholder={placeholder}
          style={mergedStyle}
          onChange={handleChange}
        />
      );
    case 'cardCvc':
      return (
        <CardVerificationCodeElement
          btRef={refs.cardCvc}
          placeholder={placeholder}
          style={mergedStyle}
          onChange={handleChange}
        />
      );
    case 'cardholderName':
      return (
        <TextElement
          btRef={refs.cardholderName}
          placeholder={placeholder}
          style={mergedStyle}
          onChange={handleChange}
        />
      );
  }
};

const tokenize: ProviderAdapter['tokenize'] = async (
  collector,
  providerData
): Promise<TokenizeResult> => {
  const { bt, refs } = collector as BtCollector;
  const expiry = refs.cardExpiry.current;
  const data: Record<string, unknown> = {
    number: refs.cardNumber.current,
    expiration_month: expiry ? expiry.month() : undefined,
    expiration_year: expiry ? expiry.year() : undefined,
    cvc: refs.cardCvc.current,
    cardholder_name: refs.cardholderName.current,
  };

  try {
    const token = await bt.tokens.create(
      { type: 'card', data, ...(isRecord(providerData) ? providerData : {}) },
      undefined
    );
    if (!token) {
      return errorResult(
        VAULT_TYPE,
        'tokenization_failed',
        'Basis Theory returned no token.'
      );
    }
    const id = isRecord(token) ? token.id : undefined;
    return {
      status: 'success',
      vaultType: VAULT_TYPE,
      data: { raw: token, tokens: id ? { id } : undefined },
    };
  } catch (error) {
    return errorResult(VAULT_TYPE, 'tokenization_failed', messageOf(error));
  }
};

export const basisTheoryAdapter: ProviderAdapter = {
  vaultType: VAULT_TYPE,
  validateVaultData,
  Host,
  Field,
  tokenize,
};
