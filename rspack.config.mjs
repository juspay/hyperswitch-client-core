import path from 'node:path';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';
import * as Repack from '@callstack/repack';
import rspack from '@rspack/core';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const require = createRequire(import.meta.url);

/**
 * Re.Pack (Rspack) configuration for the Hyperswitch SDK bundles.
 *
 * The SDK ships one entry bundle per React host (`index.js` for payments,
 * `index.payment-methods.js` for the Payment Methods SDK,
 * `index.payment-method-management.js` for payment method management) plus a set of
 * separately loaded chunk files that sit next to it in the native package,
 * each named `<bundle name>.<chunk>.chunk.bundle` (e.g. `hyperswitch.sentry.chunk.bundle`):
 *
 *   react-native.chunk.bundle   React Native + React runtime. An *initial* chunk:
 *                               the native host evaluates it before the entry
 *                               bundle (see HyperBundleLoader.kt / HyperReactNativeFactory.mm).
 *   sentry.chunk.bundle         @sentry/react-native, loaded on demand.
 *   paypal.chunk.bundle         @juspay-tech/react-native-hyperswitch-paypal
 *   netcetera-3ds.chunk.bundle  @juspay-tech/react-native-hyperswitch-netcetera-3ds
 *   scancard.chunk.bundle       @juspay-tech/react-native-hyperswitch-scancard
 *   vault.chunk.bundle          @juspay-tech/react-native-hyperswitch-vault
 *   vgs.chunk.bundle            @vgs/collect-react-native
 *
 *   optional-shared.chunk.bundle  code shared by the optional chunks
 *   location-data.chunk.bundle    country/state JSON
 *
 * Chunk names come from the cache groups below (ReScript cannot emit
 * `webpackChunkName` comments). On-demand chunks are loaded through Re.Pack's
 * ScriptManager; `src/chunks/ScriptResolver.res` decides where a chunk is read
 * from (dev server, the directory the entry bundle came from, or the SDK's own
 * assets/resources).
 */

/** Chunk name -> package path matcher. Every module of the package lands in that chunk. */
const OPTIONAL_CHUNKS = {
  sentry: /[\\/]node_modules[\\/]@sentry[\\/]/,
  paypal: /[\\/]node_modules[\\/]@juspay-tech[\\/]react-native-hyperswitch-paypal[\\/]/,
  'netcetera-3ds':
    /[\\/]node_modules[\\/]@juspay-tech[\\/]react-native-hyperswitch-netcetera-3ds[\\/]/,
  scancard: /[\\/]node_modules[\\/]@juspay-tech[\\/]react-native-hyperswitch-scancard[\\/]/,
  vault: /[\\/]node_modules[\\/]@juspay-tech[\\/]react-native-hyperswitch-vault[\\/]/,
  vgs: /[\\/]node_modules[\\/]@vgs[\\/]collect-react-native[\\/]/,
};

/**
 * Optional packages. Metro tolerates a missing optional dependency; Rspack does
 * not, so each one that is not installed is replaced by a stub:
 *
 *  - loaded with `import()` (the chunks above): a stub that exports nothing. A
 *    module that throws while a dynamic import evaluates it is reported as a
 *    fatal error, so the loaders check for the export they need instead.
 *  - loaded with `require()` inside try/catch: a stub that throws, which is how
 *    a missing package behaved under Metro.
 */
const OPTIONAL_IMPORTED_PACKAGES = [
  '@sentry/react-native',
  '@juspay-tech/react-native-hyperswitch-paypal',
  '@juspay-tech/react-native-hyperswitch-netcetera-3ds',
  '@juspay-tech/react-native-hyperswitch-scancard',
  '@juspay-tech/react-native-hyperswitch-vault',
  // Subpath entry that older vault releases do not have.
  '@juspay-tech/react-native-hyperswitch-vault/detached',
  '@vgs/collect-react-native',
];

const OPTIONAL_REQUIRED_PACKAGES = [
  '@juspay-tech/react-native-hyperswitch-samsung-pay',
  '@evervault/react-native',
  '@basis-theory/react-native-elements',
  '@react-native-clipboard/clipboard',
  'skyflow-react-native',
  'react-native-plaid-link-sdk',
  'react-native-hyperswitch-kount',
  'react-native-klarna-inapp-sdk',
];

function isResolvable(request) {
  try {
    require.resolve(request, { paths: [__dirname] });
    return true;
  } catch {
    // Packages whose `exports` map hides package.json still resolve their main
    // entry above; a bare directory without a resolvable entry counts as missing.
    return false;
  }
}

function escapeRegExp(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

export default Repack.defineRspackConfig((env) => {
  const { mode = 'production', platform = process.env.PLATFORM ?? 'android' } = env;
  const isProduction = mode === 'production';
  const entry = env.entry ?? './index.js';
  // Chunk files are prefixed with the entry bundle's name, so the payments and
  // the payment methods bundles can share one assets/resources directory:
  // `hyperswitch.bundle` + `hyperswitch.<chunk>.chunk.bundle`.
  const bundleName = env.bundleFilename
    ? path.basename(env.bundleFilename).replace(/\.(js)?bundle$/, '')
    : /payment-method-management/.test(entry)
      ? 'hyperswitch-payment-method-management'
      : /payment-methods/.test(entry)
        ? 'hyperswitch-payment-methods'
        : 'hyperswitch';

  const stubs = [
    [OPTIONAL_IMPORTED_PACKAGES, path.join(__dirname, 'src/chunks/missingOptionalModule.async.js')],
    [OPTIONAL_REQUIRED_PACKAGES, path.join(__dirname, 'src/chunks/missingOptionalModule.js')],
  ].flatMap(([packages, stub]) =>
    packages.filter((pkg) => !isResolvable(pkg)).map((pkg) => [pkg, stub])
  );

  return {
    mode,
    context: __dirname,
    entry,
    output: {
      // The entry chunk is the bundle the native host names (`--bundle-output`);
      // every other chunk, including the initial react-native chunk, is a
      // `<name>.chunk.bundle` file next to it.
      filename: (pathData) =>
        pathData.chunk && pathData.chunk.name === 'react-native'
          ? `${bundleName}.[name].chunk.bundle`
          : 'index.bundle',
      chunkFilename: `${bundleName}.[name].chunk.bundle`,
      // Both hosts (payments, payment methods) are separate JS realms, so one
      // chunk-loading global is fine; keep it stable across releases.
      chunkLoadingGlobal: 'hyperswitchChunks',
      uniqueName: 'hyperswitch',
    },
    resolve: {
      ...Repack.getResolveOptions(platform),
      extensions: [
        `.${platform}.bs.js`,
        '.native.bs.js',
        '.bs.js',
        ...Repack.getResolveOptions(platform).extensions,
      ],
    },
    module: {
      rules: [
        {
          test: /\.[cm]?[jt]sx?$/,
          type: 'javascript/auto',
          use: {
            // Runs the project's babel config (react-native-dotenv etc.) and
            // SWC for everything Babel is not needed for.
            loader: '@callstack/repack/babel-swc-loader',
            parallel: true,
            options: {},
          },
        },
        ...Repack.getAssetTransformRules(),
      ],
    },
    // @sentry/react-native require()s packages this SDK does not use (Expo,
    // React Navigation) inside try/catch. Unresolved, the bundler throws at the
    // require site and Sentry catches it; Metro stayed silent about them.
    // Do not stub them instead: a stub module goes through Re.Pack's guarded
    // require, which reports a throw from a lazy require() as fatal.
    ignoreWarnings: [
      {
        module: /[\\/]node_modules[\\/]@sentry[\\/]react-native[\\/]/,
        message: /Can't resolve '(expo-updates|expo-router[^']*|@react-navigation\/native)'/,
      },
    ],
    optimization: {
      // Stable, human readable chunk ids: the native side and the OTA config refer
      // to chunk files by name.
      chunkIds: 'named',
      moduleIds: 'deterministic',
      minimize: isProduction,
      splitChunks: {
        // Only the cache groups below may create chunks; no incidental splitting.
        cacheGroups: {
          default: false,
          defaultVendors: false,
          // React Native + React. Extracted from every chunk so the runtime is
          // shared and can be loaded as its own bundle before the entry.
          // `@react-native/js-polyfills` stays in the entry: Re.Pack runs the
          // polyfills before the startup that would load this chunk.
          reactNative: isProduction
            ? {
                name: 'react-native',
                test: /[\\/]node_modules[\\/](react-native|react|scheduler|@react-native[\\/](?!js-polyfills)[^\\/]+)[\\/]/,
                chunks: 'all',
                enforce: true,
                priority: 100,
              }
            : false,
          ...Object.fromEntries(
            Object.entries(OPTIONAL_CHUNKS).map(([name, test]) => [
              name,
              { name, test, chunks: 'async', enforce: true, priority: 50 },
            ])
          ),
          // Whatever the optional packages share that is not already in the
          // entry (Babel/SWC helpers, the stub for a missing package). Named, so
          // no chunk file gets a generated name.
          optionalShared: {
            name: 'optional-shared',
            test: /[\\/](node_modules|src[\\/]chunks)[\\/]/,
            chunks: 'async',
            enforce: true,
            priority: 10,
          },
          // Country/state data: a lazily imported JSON (CountryStateDataContext.res).
          locationData: {
            name: 'location-data',
            test: /[\\/]shared-code[\\/]assets[\\/]v2[\\/]jsons[\\/]location[\\/]/,
            chunks: 'async',
            enforce: true,
            priority: 40,
          },
        },
      },
    },
    plugins: [
      new Repack.RepackPlugin({
        platform,
        // Every chunk is packaged with the SDK (assets on Android, resources on
        // iOS). Nothing is fetched from a remote at runtime.
        extraChunks: [{ include: /.*/, type: 'local' }],
      }),
      // Chunk files are evaluated as plain scripts. The React Native bundle
      // defines `self` only after InitializeCore has run, but the react-native
      // chunk is evaluated *before* the entry, so give every chunk the same
      // global-object prelude Re.Pack gives the entry.
      new rspack.BannerPlugin({
        raw: true,
        entryOnly: false,
        test: /\.chunk\.bundle$/,
        banner:
          'var self = typeof self !== "undefined" ? self : (typeof globalThis !== "undefined" ? globalThis : this);',
      }),
      // Missing optional packages (see OPTIONAL_*_PACKAGES).
      ...stubs.map(
        ([pkg, stub]) =>
          new rspack.NormalModuleReplacementPlugin(
            // Exact request only: `pkg` must not also catch `pkg/subpath`.
            new RegExp(`^${escapeRegExp(pkg)}$`),
            stub
          )
      ),
    ],
  };
});
