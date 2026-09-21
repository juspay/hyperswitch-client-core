import type { ComponentType, ReactNode } from 'react';
import { Appearance as DeviceAppearance } from 'react-native';

import type {
  CollectorContext,
  ProviderAdapter,
} from '../core/ProviderAdapter';
import type { CardDetails } from '../core/types';
import { hyperswitchVaultAdapter } from '../providers/hyperswitch/adapter';
import { toVaultAppearance } from '../providers/hyperswitch/appearance';
import type { HyperswitchVaultData } from '../providers/hyperswitch/types';
import { registerAdapter } from '../providers/registry';

declare const require: (moduleId: string) => unknown;

/* The vault's handle for a form whose fields are not its children. It carries
   no card data and no store; see createDetachedCardForm in the vault package. */
interface DetachedVaultForm {
  Host: ComponentType;
  Field: ComponentType<{ children: ReactNode }>;
  tokenize(): Promise<unknown>;
}

interface DetachedVaultSdk {
  createDetachedCardForm(config: Record<string, unknown>): DetachedVaultForm;
}

let detachedSdk: DetachedVaultSdk | null = null;
try {
  const loaded = require(
    '@juspay-tech/react-native-hyperswitch-vault/detached'
  ) as Partial<DetachedVaultSdk> | null;
  detachedSdk =
    typeof loaded?.createDetachedCardForm === 'function'
      ? (loaded as DetachedVaultSdk)
      : null;
} catch {
  detachedSdk = null;
}

/* False with a vault release that predates its ./detached entry. */
export const hyperswitchDetachedAvailable = detachedSdk != null;

const BaseField = hyperswitchVaultAdapter.Field;

/* The library's own Hyperswitch adapter, for fields that each sit in a root of
   their own. It is registered only by the hosted entry, so <CardForm> users
   keep the adapter they have always had. */
export const hyperswitchDetachedAdapter: ProviderAdapter = {
  ...hyperswitchVaultAdapter,

  createCollector: async (vaultData, context?: CollectorContext) => {
    if (!detachedSdk) {
      throw new Error(
        'This @juspay-tech/react-native-hyperswitch-vault has no "./detached" entry. Update it.'
      );
    }
    const data = vaultData as HyperswitchVaultData;
    const layers = context?.appearances ?? [];
    const scheme = DeviceAppearance.getColorScheme() === 'dark' ? 'dark' : 'light';

    return detachedSdk.createDetachedCardForm({
      vaultDetails: {
        vaultType: 'hyperswitch',
        vaultData: { sdkAuthorization: data.sdkAuthorization },
      },
      environment: data.environment ?? context?.environment ?? 'PROD',
      customEndpoints: context?.customEndpoints,
      locale: context?.locale,
      appearance:
        layers.length > 0 ? toVaultAppearance(layers, scheme) : undefined,
      onChange: (event: { payload?: Partial<CardDetails> }) => {
        const payload = event?.payload ?? {};
        context?.onCardDetails({
          bin: payload.bin ?? null,
          extendedBin: payload.extendedBin ?? null,
          last4: payload.last4 ?? null,
          brand: payload.brand ?? null,
          expiryMonth: payload.expiryMonth ?? null,
          expiryYear: payload.expiryYear ?? null,
        });
      },
    });
  },

  DetachedHost: ({ collector }) => {
    const { Host } = collector as DetachedVaultForm;
    return <Host />;
  },

  Field: (props) => {
    const { Field } = props.collector as DetachedVaultForm;
    return (
      <Field>
        <BaseField {...props} />
      </Field>
    );
  },
};

export function registerHostedAdapters(): () => void {
  return hyperswitchDetachedAvailable
    ? registerAdapter(hyperswitchDetachedAdapter)
    : () => {};
}
