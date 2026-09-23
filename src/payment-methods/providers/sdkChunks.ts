/* Provider SDKs that the bundler emits as chunks of their own (vault and vgs;
   see rspack.config.mjs). The bundler loads each chunk once and caches it.
   The specifiers must stay literal so the bundler can resolve and split them.

   A package that is not part of the build is replaced by a module that exports
   nothing, so each loader checks for an export it needs and rejects without it. */

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
  import('@juspay-tech/react-native-hyperswitch-vault').then(
    requireExport(PKG_VAULT, 'CardForm')
  );

export const loadVgs = (): Promise<unknown> =>
  import('@vgs/collect-react-native').then(requireExport(PKG_VGS, 'VGSCollect'));
