import type { ProviderAdapter } from '../core/ProviderAdapter';
import type { VaultType } from '../core/types';

type AdapterLoader = () => ProviderAdapter;

declare const require: (moduleId: string) => unknown;

const registered = new Map<VaultType, ProviderAdapter>();
const loaderCache = new Map<VaultType, ProviderAdapter>();

function missingSdk(pkg: string): Error {
  return new Error(
    `This vault_type needs the "${pkg}" package, which is not installed. ` +
      `Install it in your app (e.g. \`npm install ${pkg}\`) and rebuild.`
  );
}

const loaders: Partial<Record<VaultType, AdapterLoader>> = {
  hyperswitch: () => {
    const m = require('./hyperswitch/adapter') as {
      hyperswitchVaultAdapter: ProviderAdapter;
      hyperswitchVaultSdkAvailable: boolean;
    };
    if (!m.hyperswitchVaultSdkAvailable) {
      throw missingSdk('@juspay-tech/react-native-hyperswitch-vault');
    }
    return m.hyperswitchVaultAdapter;
  },
  vgs: () => {
    const m = require('./vgs/adapter') as {
      vgsAdapter: ProviderAdapter;
      vgsSdkAvailable: boolean;
    };
    if (!m.vgsSdkAvailable) throw missingSdk('@vgs/collect-react-native');
    return m.vgsAdapter;
  },
  skyflow: () => {
    const m = require('./skyflow/adapter') as {
      skyflowAdapter: ProviderAdapter;
      skyflowSdkAvailable: boolean;
    };
    if (!m.skyflowSdkAvailable) throw missingSdk('skyflow-react-native');
    return m.skyflowAdapter;
  },
  basis_theory: () => {
    const m = require('./basisTheory/adapter') as {
      basisTheoryAdapter: ProviderAdapter;
      basisTheorySdkAvailable: boolean;
    };
    if (!m.basisTheorySdkAvailable) {
      throw missingSdk('@basis-theory/react-native-elements');
    }
    return m.basisTheoryAdapter;
  },
  evervault: () => {
    const m = require('./evervault/adapter') as {
      evervaultAdapter: ProviderAdapter;
      evervaultSdkAvailable: boolean;
    };
    if (!m.evervaultSdkAvailable) throw missingSdk('@evervault/react-native');
    return m.evervaultAdapter;
  },
};

export function registerAdapter(adapter: ProviderAdapter): () => void {
  registered.set(adapter.vaultType, adapter);
  return () => {
    if (registered.get(adapter.vaultType) === adapter) {
      registered.delete(adapter.vaultType);
    }
  };
}

export function resolveAdapter(vaultType: VaultType): ProviderAdapter {
  const injected = registered.get(vaultType);
  if (injected) return injected;

  const cached = loaderCache.get(vaultType);
  if (cached) return cached;

  const loader = loaders[vaultType];
  if (loader) {
    const adapter = loader();
    loaderCache.set(vaultType, adapter);
    return adapter;
  }

  throw new Error(
    `No provider adapter registered for vault_type "${vaultType}". ` +
      'Install the matching provider SDK (and make sure this version supports it), ' +
      'or register a custom adapter with registerAdapter().'
  );
}
