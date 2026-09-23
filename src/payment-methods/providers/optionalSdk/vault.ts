/* @juspay-tech/react-native-hyperswitch-vault, loaded with import() (see ../sdkChunks.ts). The package is
   require()d inside try/catch while this module is evaluated, so one that is
   missing from the build, or throws while loading, leaves `loaded` null: the
   provider is then unavailable. Importing the package itself would not do:
   Re.Pack reports an exception thrown while an import()ed module is
   evaluated as a fatal error, which ends the app. */

declare const require: (moduleId: string) => unknown;

let sdk: unknown = null;
try {
  sdk = require('@juspay-tech/react-native-hyperswitch-vault');
} catch {
  sdk = null;
}

export const loaded = sdk;
