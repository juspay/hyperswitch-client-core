import { Fragment, useEffect, useRef } from 'react';
import { StyleSheet } from 'react-native';

import { fieldChange } from '../../core/fieldChange';
import type { ProviderAdapter } from '../../core/ProviderAdapter';
import { errorResult, messageOf } from '../../core/results';
import type { ElementType, TokenizeResult } from '../../core/types';
import type { VgsTokenizeOptions, VgsVaultData } from './types';

declare const require: (moduleId: string) => unknown;

type VgsSdk = any;

let vgsSdk: VgsSdk | null = null;
try {
  vgsSdk = require('@vgs/collect-react-native') as VgsSdk;
} catch {
  vgsSdk = null;
}

export const vgsSdkAvailable = vgsSdk != null;

const { VGSCollect, VGSTextInput, VGSCardInput, VGSCVCInput } =
  vgsSdk ?? ({} as VgsSdk);

type VGSCollect = InstanceType<VgsSdk['VGSCollect']>;

const VAULT_TYPE = 'vgs' as const;

const FIELD_CONFIG: Record<
  ElementType,
  { fieldName: string; type: 'card' | 'expDate' | 'cvc' | 'cardHolderName' }
> = {
  cardNumber: { fieldName: 'card_number', type: 'card' },
  cardExpiry: { fieldName: 'expiration_date', type: 'expDate' },
  cardCvc: { fieldName: 'card_cvc', type: 'cvc' },
  cardholderName: { fieldName: 'card_holder', type: 'cardHolderName' },
};

const FIELD_COMPONENT: Partial<Record<ElementType, typeof VGSTextInput>> = {
  cardNumber: VGSCardInput,
  cardCvc: VGSCVCInput,
};

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

function validateVaultData(raw: unknown): VgsVaultData {
  if (!isRecord(raw) || typeof raw.vaultId !== 'string' || !raw.vaultId) {
    throw new Error(
      'VGS vaultData requires a non-empty string "vaultId". Received: ' +
        JSON.stringify(raw)
    );
  }
  return raw as unknown as VgsVaultData;
}

const Host: ProviderAdapter['Host'] = ({
  vaultData,
  onReady,
  onError,
  children,
}) => {
  const data = vaultData as VgsVaultData;
  const collectorRef = useRef<VGSCollect | null>(null);

  useEffect(() => {
    try {
      const collector = new VGSCollect(data.vaultId, data.environment);
      if (data.routeId) collector.setRouteId(data.routeId);
      collectorRef.current = collector;

      if (data.cname) {
        collector
          .setCname(data.cname)
          .then(() => onReady(collector))
          .catch(onError);
      } else {
        onReady(collector);
      }
    } catch (error) {
      onError(error);
    }
  }, [
    data.vaultId,
    data.environment,
    data.routeId,
    data.cname,
    onReady,
    onError,
  ]);

  return <Fragment>{children}</Fragment>;
};

interface VgsFieldState {
  isValid?: boolean;
  isEmpty?: boolean;
  isFocused?: boolean;
  isDirty?: boolean;
  validationErrors?: string[];
  cardBrand?: string;
}

const Field: ProviderAdapter['Field'] = ({
  elementType,
  collector,
  placeholder,
  styles,
  onChange,
  onFocus,
  onBlur,
}) => {
  const config = FIELD_CONFIG[elementType];
  const focusedRef = useRef(false);

  const flatStyle = StyleSheet.flatten(styles?.container) as
    { height?: number } | undefined;
  const containerHeight =
    typeof flatStyle?.height === 'number' ? flatStyle.height : undefined;

  const handleState = (state: unknown) => {
    const s = (state ?? {}) as VgsFieldState;
    onChange?.(
      fieldChange(elementType, {
        empty: Boolean(s.isEmpty),
        valid: Boolean(s.isValid),
        touched: Boolean(s.isDirty),
        brand: s.cardBrand,
        error: s.validationErrors?.[0],
      })
    );
    const focused = Boolean(s.isFocused);
    if (focused !== focusedRef.current) {
      focusedRef.current = focused;
      (focused ? onFocus : onBlur)?.({ elementType });
    }
  };

  const common = {
    collector: collector as VGSCollect,
    fieldName: config.fieldName,
    placeholder,
    containerStyle: styles?.container as object | undefined,
    textStyle: styles?.input as object | undefined,
    onStateChange: handleState,
  };
  const Specialized = FIELD_COMPONENT[elementType];
  return Specialized ? (
    <Specialized {...common} containerHeight={containerHeight} />
  ) : (
    <VGSTextInput {...common} type={config.type} />
  );
};

async function readResponseBody(response: any): Promise<unknown> {
  if (response && typeof response.json === 'function') {
    try {
      return await response.json();
    } catch {
      if (typeof response.text === 'function') {
        try {
          return await response.text();
        } catch {
          return undefined;
        }
      }
      return undefined;
    }
  }
  return response;
}

const tokenize: ProviderAdapter['tokenize'] = async (
  collector,
  providerData
): Promise<TokenizeResult> => {
  const options = (providerData ?? {}) as VgsTokenizeOptions;
  const vgs = collector as VGSCollect;
  try {
    const { status, response } = await vgs.submit(
      options.path ?? '/post',
      options.method ?? 'POST',
      options.extraData
    );
    const body = await readResponseBody(response);

    if (status >= 200 && status < 300) {
      return {
        status: 'success',
        vaultType: VAULT_TYPE,
        data: {
          raw: body,
          tokens: isRecord(body) ? body : undefined,
        },
      };
    }

    return errorResult(
      VAULT_TYPE,
      'tokenization_failed',
      `VGS returned status ${status}.`
    );
  } catch (error) {
    return errorResult(VAULT_TYPE, 'tokenization_failed', messageOf(error));
  }
};

const createCollector = async (vaultData: unknown): Promise<VGSCollect> => {
  const data = vaultData as VgsVaultData;
  const collector = new VGSCollect(data.vaultId, data.environment);
  if (data.routeId) collector.setRouteId(data.routeId);
  if (data.cname) await collector.setCname(data.cname);
  return collector;
};

export const vgsAdapter: ProviderAdapter = {
  vaultType: VAULT_TYPE,
  validateVaultData,
  createCollector,
  Host,
  Field,
  tokenize,
};
