import type { ComponentType, ReactNode } from 'react';
import { Appearance as DeviceAppearance } from 'react-native';

import type {
  CollectorContext,
  ProviderAdapter,
} from '../core/ProviderAdapter';
import type { CardDetails } from '../core/types';
import {
  hyperswitchVaultAdapter,
  loadHyperswitchVaultSdk,
} from '../providers/hyperswitch/adapter';
import { toVaultAppearance } from '../providers/hyperswitch/appearance';
import type { HyperswitchVaultData } from '../providers/hyperswitch/types';
import { registerAdapter } from '../providers/registry';
import { requireExport } from '../providers/sdkChunks';

/* The vault package's `./detached` entry, in the vault chunk. Kept here, where
   only the hosted (payment methods) entry reaches it: releases of the vault
   without the entry fail to resolve it, which the web build treats as an error. */
const loadVaultDetached = (): Promise<unknown> =>
  // @ts-ignore: the subpath is missing from older vault releases.
  import('@juspay-tech/react-native-hyperswitch-vault/detached').then(
    requireExport('@juspay-tech/react-native-hyperswitch-vault/detached', 'createDetachedCardForm')
  );

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
let loading: Promise<DetachedVaultSdk | null> | undefined;

/* The vault chunk, with its ./detached entry. Resolves null when the vault is
   not part of this build or predates that entry; a later call tries again. */
function loadDetachedSdk(): Promise<DetachedVaultSdk | null> {
  if (detachedSdk) return Promise.resolve(detachedSdk);
  if (loading) return loading;
  loading = Promise.all([loadHyperswitchVaultSdk(), loadVaultDetached()]).then(
    ([, entry]) => {
      loading = undefined;
      const loaded = entry as Partial<DetachedVaultSdk> | null;
      detachedSdk =
        typeof loaded?.createDetachedCardForm === 'function'
          ? (loaded as DetachedVaultSdk)
          : null;
      return detachedSdk;
    },
    () => {
      loading = undefined;
      return null;
    }
  );
  return loading;
}

/* Known only once the vault chunk has been looked at: false with a vault
   release that predates its ./detached entry, or with no vault at all. */
export function hyperswitchDetachedAvailable(): Promise<boolean> {
  return loadDetachedSdk().then((sdk) => sdk != null);
}

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

let registration: Promise<unknown> | undefined;

/* Loads the vault chunk and registers the detached adapter once it is in.
   Resolves with how to unregister it (a no-op when there is nothing to register). */
export function registerHostedAdapters(): Promise<() => void> {
  const pending = loadDetachedSdk().then((sdk) =>
    sdk ? registerAdapter(hyperswitchDetachedAdapter) : () => {}
  );
  registration = pending;
  return pending;
}

/* Settles once a registration that was started has finished, at once when
   none was. A form opened in between waits for it, so it does not fall back
   to the in-tree Hyperswitch adapter that cannot host detached fields. */
export function hostedAdaptersReady(): Promise<void> {
  return registration ? registration.then(() => undefined) : Promise.resolve();
}
