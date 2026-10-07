/* Provider SDKs that the bundler emits as chunks of their own (vault and vgs;
   see rspack.config.mjs). The bundler loads each chunk once and caches it.

   Each is reached through a wrapper in ./optionalSdk that loads the package
   inside try/catch, so a package that is missing, or throws while loading,
   rejects here with "not part of this build" and the provider is unavailable. */

const PKG_VAULT = '@juspay-tech/react-native-hyperswitch-vault';
const PKG_VGS = '@vgs/collect-react-native';

export function requireExport(pkg: string, name: string) {
  return (ns: unknown): unknown => {
    const value = (ns as Record<string, unknown> | null | undefined)?.[name];
    if (value === undefined) {
      throw new Error(`"${pkg}" is not part of this build.`);
    }
    return ns;
  };
}

export const loadVault = (): Promise<unknown> =>
  import('./optionalSdk/vault').then(({ loaded }) => requireExport(PKG_VAULT, 'CardForm')(loaded));

export const loadVgs = (): Promise<unknown> =>
  import('./optionalSdk/vgs').then(({ loaded }) => requireExport(PKG_VGS, 'VGSCollect')(loaded));
