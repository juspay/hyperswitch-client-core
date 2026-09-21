import { Fragment, useEffect, useMemo } from 'react';
import type { ComponentProps, ReactNode } from 'react';

import { fieldChange } from '../../core/fieldChange';
import type { ProviderAdapter } from '../../core/ProviderAdapter';
import { errorResult, messageOf } from '../../core/results';
import type { ElementType, TokenizeResult } from '../../core/types';
import type { SkyflowVaultData } from './types';

declare const require: (moduleId: string) => unknown;

type SkyflowSdk = any;

let skyflowSdk: SkyflowSdk | null = null;
try {
  skyflowSdk = require('skyflow-react-native') as SkyflowSdk;
} catch {
  skyflowSdk = null;
}

export const skyflowSdkAvailable = skyflowSdk != null;

const {
  SkyflowProvider,
  useCollectContainer,
  CardNumberElement,
  ExpirationDateElement,
  CvvElement,
  CardHolderNameElement,
} = skyflowSdk ?? ({} as SkyflowSdk);

const VAULT_TYPE = 'skyflow' as const;

type SkyflowContainer = ComponentProps<typeof CardNumberElement>['container'];
type CollectOptions = Parameters<SkyflowContainer['collect']>[0];

interface SkyflowCollector {
  container: SkyflowContainer;
  table: string;
  columns: Record<ElementType, string>;
}

const ELEMENTS: Record<ElementType, typeof CardNumberElement> = {
  cardNumber: CardNumberElement,
  cardExpiry: ExpirationDateElement,
  cardCvc: CvvElement,
  cardholderName: CardHolderNameElement,
};

const DEFAULT_COLUMNS: Record<ElementType, string> = {
  cardNumber: 'card_number',
  cardExpiry: 'card_expiration',
  cardCvc: 'cvv',
  cardholderName: 'cardholder_name',
};

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

function validateVaultData(raw: unknown): SkyflowVaultData {
  if (
    !isRecord(raw) ||
    typeof raw.vaultId !== 'string' ||
    !raw.vaultId ||
    typeof raw.vaultUrl !== 'string' ||
    !raw.vaultUrl ||
    typeof raw.table !== 'string' ||
    !raw.table
  ) {
    throw new Error(
      'Skyflow vaultData requires non-empty string "vaultId", "vaultUrl" and "table". ' +
        'Received: ' +
        JSON.stringify(raw)
    );
  }
  return raw as unknown as SkyflowVaultData;
}

function resolveColumns(data: SkyflowVaultData): Record<ElementType, string> {
  return { ...DEFAULT_COLUMNS, ...data.columns };
}

function extractTokens(response: unknown): Record<string, unknown> | undefined {
  if (!isRecord(response) || !Array.isArray(response.records)) return undefined;
  const tokens: Record<string, unknown> = {};
  for (const record of response.records) {
    if (isRecord(record) && isRecord(record.fields)) {
      Object.assign(tokens, record.fields);
    }
  }
  return Object.keys(tokens).length > 0 ? tokens : undefined;
}

function SkyflowBridge({
  table,
  columns,
  onReady,
  onError,
  children,
}: {
  table: string;
  columns: Record<ElementType, string>;
  onReady: (collector: SkyflowCollector) => void;
  onError: (error: unknown) => void;
  children: ReactNode;
}) {
  const container = useCollectContainer();
  useEffect(() => {
    try {
      onReady({ container, table, columns });
    } catch (error) {
      onError(error);
    }
  }, [container, table, columns, onReady, onError]);
  return <Fragment>{children}</Fragment>;
}

const Host: ProviderAdapter['Host'] = ({
  vaultData,
  onReady,
  onError,
  children,
}) => {
  const data = vaultData as SkyflowVaultData;
  const config = useMemo<any>(
    () => ({
      vaultID: data.vaultId,
      vaultURL: data.vaultUrl,
      getBearerToken: () => Promise.resolve(data.bearerToken ?? ''),
      options: data.options,
    }),
    [data.vaultId, data.vaultUrl, data.bearerToken, data.options]
  );
  const columns = useMemo(() => resolveColumns(data), [data]);

  return (
    <SkyflowProvider config={config}>
      <SkyflowBridge
        table={data.table}
        columns={columns}
        onReady={onReady}
        onError={onError}
      >
        {children}
      </SkyflowBridge>
    </SkyflowProvider>
  );
};

interface SkyflowElementState {
  isValid?: boolean;
  isEmpty?: boolean;
  isFocused?: boolean;
  selectedCardScheme?: string;
}

const Field: ProviderAdapter['Field'] = ({
  elementType,
  collector,
  placeholder,
  onChange,
  onFocus,
  onBlur,
}) => {
  const { container, table, columns } = collector as SkyflowCollector;
  const Element = ELEMENTS[elementType];
  const report = (state: unknown, touched?: boolean) => {
    const s = (state ?? {}) as SkyflowElementState;
    const empty = s.isEmpty ?? true;
    const valid = Boolean(s.isValid);
    onChange?.(
      fieldChange(elementType, {
        empty,
        valid,
        touched: touched ?? !empty,
        brand: s.selectedCardScheme,
        error: !empty && !valid ? 'invalid' : undefined,
      })
    );
  };
  return (
    <Element
      container={container}
      table={table}
      column={columns[elementType]}
      placeholder={placeholder}
      onChange={(state: unknown) => report(state)}
      onFocus={(state: unknown) => {
        onFocus?.({ elementType });
        report(state);
      }}
      onBlur={(state: unknown) => {
        report(state, true);
        onBlur?.({ elementType });
      }}
    />
  );
};

const tokenize: ProviderAdapter['tokenize'] = async (
  collector,
  providerData
): Promise<TokenizeResult> => {
  const { container } = collector as SkyflowCollector;
  const overrides = isRecord(providerData) ? providerData : {};
  const options = { tokens: true, ...overrides } as CollectOptions;
  try {
    const response = await container.collect(options);
    return {
      status: 'success',
      vaultType: VAULT_TYPE,
      data: { raw: response, tokens: extractTokens(response) },
    };
  } catch (error) {
    return errorResult(VAULT_TYPE, 'tokenization_failed', messageOf(error));
  }
};

export const skyflowAdapter: ProviderAdapter = {
  vaultType: VAULT_TYPE,
  validateVaultData,
  Host,
  Field,
  tokenize,
};
