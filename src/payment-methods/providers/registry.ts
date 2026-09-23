import type { ProviderAdapter } from '../core/ProviderAdapter';
import type { VaultType } from '../core/types';

type AdapterLoader = () => ProviderAdapter;
type ChunkAdapterLoader = () => Promise<ProviderAdapter>;

declare const require: (moduleId: string) => unknown;

const registered = new Map<VaultType, ProviderAdapter>();
const loaderCache = new Map<VaultType, ProviderAdapter>();
const inflight = new Map<VaultType, Promise<ProviderAdapter>>();

function missingSdk(pkg: string, cause?: unknown): Error {
  const error = new Error(
    `This vault_type needs the "${pkg}" package, which is not installed. ` +
      `Install it in your app (e.g. \`npm install ${pkg}\`) and rebuild.`
  );
  if (cause !== undefined) (error as { cause?: unknown }).cause = cause;
  return error;
}

/* resolveAdapter() was asked for an adapter whose SDK sits in a chunk of its
   own that nobody has loaded yet. */
export class AdapterNotLoadedError extends Error {
  readonly vaultType: VaultType;

  constructor(vaultType: VaultType) {
    super(
      `The "${vaultType}" provider SDK is loaded on demand and is not loaded yet. ` +
        `Await loadAdapter("${vaultType}") before resolving it.`
    );
    this.name = 'AdapterNotLoadedError';
    this.vaultType = vaultType;
  }
}

export function isAdapterNotLoadedError(
  error: unknown
): error is AdapterNotLoadedError {
  return (
    error instanceof AdapterNotLoadedError ||
    (error instanceof Error && error.name === 'AdapterNotLoadedError')
  );
}

/* Providers whose SDK is a chunk of its own (providers/sdkChunks.ts):
   the adapter module is small and bundled; its SDK arrives with the chunk. */
const chunkLoaders: Partial<Record<VaultType, ChunkAdapterLoader>> = {
  hyperswitch: () => {
    const m = require('./hyperswitch/adapter') as typeof import('./hyperswitch/adapter');
    return m.loadHyperswitchVaultSdk().then(
      () => m.hyperswitchVaultAdapter,
      (error: unknown) => {
        throw missingSdk('@juspay-tech/react-native-hyperswitch-vault', error);
      }
    );
  },
  vgs: () => {
    const m = require('./vgs/adapter') as typeof import('./vgs/adapter');
    return m.loadVgsSdk().then(
      () => m.vgsAdapter,
      (error: unknown) => {
        throw missingSdk('@vgs/collect-react-native', error);
      }
    );
  },
};

/* Providers whose SDK is part of the main bundle when installed. */
const loaders: Partial<Record<VaultType, AdapterLoader>> = {
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

function unknownVaultType(vaultType: VaultType): Error {
  return new Error(
    `No provider adapter registered for vault_type "${vaultType}". ` +
      'Install the matching provider SDK (and make sure this version supports it), ' +
      'or register a custom adapter with registerAdapter().'
  );
}

export function registerAdapter(adapter: ProviderAdapter): () => void {
  registered.set(adapter.vaultType, adapter);
  return () => {
    if (registered.get(adapter.vaultType) === adapter) {
      registered.delete(adapter.vaultType);
    }
  };
}

/* Synchronous: an injected adapter, one already loaded, or one whose SDK is in
   the main bundle. Throws AdapterNotLoadedError for a chunked provider that
   loadAdapter() has not brought in yet. */
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

  if (chunkLoaders[vaultType]) throw new AdapterNotLoadedError(vaultType);

  throw unknownVaultType(vaultType);
}

/* Loads the adapter and, for a chunked provider, its SDK chunk; the result is
   cached so resolveAdapter() answers synchronously from then on. An injected
   adapter wins, as it does for resolveAdapter(). Rejects with the same errors
   resolveAdapter() throws (a missing SDK, an unknown vault type). */
export function loadAdapter(vaultType: VaultType): Promise<ProviderAdapter> {
  const injected = registered.get(vaultType);
  if (injected) return Promise.resolve(injected);

  const cached = loaderCache.get(vaultType);
  if (cached) return Promise.resolve(cached);

  const pending = inflight.get(vaultType);
  if (pending) return pending;

  const chunkLoader = chunkLoaders[vaultType];
  if (!chunkLoader) {
    try {
      return Promise.resolve(resolveAdapter(vaultType));
    } catch (error) {
      return Promise.reject(error);
    }
  }

  const loading = chunkLoader().then(
    (adapter) => {
      inflight.delete(vaultType);
      loaderCache.set(vaultType, adapter);
      return registered.get(vaultType) ?? adapter;
    },
    (error: unknown) => {
      // Let a later call try again (e.g. once the chunk is reachable).
      inflight.delete(vaultType);
      throw error;
    }
  );
  inflight.set(vaultType, loading);
  return loading;
}
