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
 * The SDK has one React host per product, each with its own entry bundle:
 *
 *   hyperswitch.bundle                             index.js (payments)
 *   hyperswitch-payment-methods.bundle             index.payment-methods.js
 *   hyperswitch-payment-method-management.bundle   index.payment-method-management.js
 *
 * `yarn bundle:*` (scripts/bundle.mjs) builds them in one compilation, so the
 * code they have in common is one chunk file that all of them load, never a copy
 * per entry. Chunk files are `hyperswitch.<chunk>.chunk.bundle`:
 *
 *   react-native     React Native + React. Initial: the native host evaluates it
 *                    before the entry (HyperBundleLoader.kt, HyperReactNativeFactory.mm).
 *   vendors          every other package the entries use from the start. Initial.
 *   sentry           @sentry/react-native, loaded on demand.
 *   paypal           @juspay-tech/react-native-hyperswitch-paypal
 *   netcetera-3ds    @juspay-tech/react-native-hyperswitch-netcetera-3ds
 *   scancard         @juspay-tech/react-native-hyperswitch-scancard
 *   vault            @juspay-tech/react-native-hyperswitch-vault
 *   vgs              @vgs/collect-react-native
 *   optional-shared  code the on-demand chunks share
 *   location-data    country/state JSON
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

/**
 * Entry files, one per React host, by the name of the bundle the native side
 * loads (`<name>.bundle`) and the dev-server request (`<entry file>.bundle`).
 */
const ENTRIES = [
  { bundle: 'hyperswitch', file: 'index' },
  { bundle: 'hyperswitch-payment-methods', file: 'index.payment-methods' },
  { bundle: 'hyperswitch-payment-method-management', file: 'index.payment-method-management' },
];

/**
 * Chunks every entry needs before it can start. The native host evaluates them,
 * in this order, before the entry (HyperBundleLoader.kt, HyperReactNativeFactory.mm).
 */
const INITIAL_CHUNKS = ['react-native', 'vendors'];

/** Prefix of every chunk file: `hyperswitch.<chunk>.chunk.bundle`. */
const CHUNK_PREFIX = 'hyperswitch';

/**
 * RepackPlugin without its output step. That step copies one entry to
 * `--bundle-output` and refuses a compilation with several entries; the shared
 * build (scripts/bundle.mjs) installs the files itself.
 */
class SharedBuildRepackPlugin {
  constructor(config) {
    this.config = config;
  }

  apply(compiler) {
    const Output = Repack.plugins.OutputPlugin;
    const apply = Output.prototype.apply;
    Output.prototype.apply = () => {};
    try {
      new Repack.RepackPlugin(this.config).apply(compiler);
    } finally {
      Output.prototype.apply = apply;
    }
  }
}

export default Repack.defineRspackConfig((env) => {
  const { mode = 'production', platform = process.env.PLATFORM ?? 'android' } = env;
  const isProduction = mode === 'production';
  const isDevServer = Boolean(env.devServer);
  // `node scripts/bundle.mjs` (yarn bundle:*): every entry in one compilation, so
  // react-native, sentry, vault, ... are one file each that all entries share.
  const isSharedBuild = !isDevServer && process.env.HYPERSWITCH_SHARED_BUILD === '1';
  // A plain `react-native bundle --entry-file ...` (Gradle's and Xcode's release
  // steps): that one entry, its chunks prefixed with its bundle name.
  const isSingleEntry = !isDevServer && !isSharedBuild;

  const entry = isDevServer
    ? Object.fromEntries(ENTRIES.map((e) => [e.file, `./${e.file}.js`]))
    : isSharedBuild
      ? Object.fromEntries(ENTRIES.map((e) => [e.bundle, `./${e.file}.js`]))
      : env.entry ?? './index.js';

  const chunkPrefix = isSingleEntry
    ? env.bundleFilename
      ? path.basename(env.bundleFilename).replace(/\.(js)?bundle$/, '')
      : (ENTRIES.find((e) => entry === `./${e.file}.js`) ?? ENTRIES[0]).bundle
    : CHUNK_PREFIX;

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
      // Dev server: `<entry file>.bundle`, the name each host requests.
      // Entries: `<name>.bundle` (the single-entry build is renamed to
      // --bundle-output by Re.Pack). Initial chunks and every other chunk:
      // `<prefix>.<chunk>.chunk.bundle`.
      filename: (pathData) =>
        pathData.chunk && INITIAL_CHUNKS.includes(pathData.chunk.name)
          ? `${chunkPrefix}.[name].chunk.bundle`
          : isSingleEntry
            ? 'index.bundle'
            : '[name].bundle',
      chunkFilename: `${chunkPrefix}.[name].chunk.bundle`,
      // The hosts are separate JS realms, so one chunk-loading global is fine;
      // keep it stable across releases.
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
          // React Native + React: one chunk every entry shares, evaluated by the
          // native host before the entry. `@react-native/js-polyfills` and the
          // SWC helpers it uses stay in each entry: Re.Pack runs the polyfills
          // before the entry's startup, which is what waits for these chunks.
          reactNative: isProduction
            ? {
                name: 'react-native',
                test: /[\\/]node_modules[\\/](react-native|react|scheduler|@react-native[\\/](?!js-polyfills)[^\\/]+)[\\/]/,
                chunks: 'all',
                enforce: true,
                priority: 100,
              }
            : false,
          // Every other package any entry uses from the start: one shared chunk,
          // also evaluated by the native host before the entry. It takes such a
          // package from the on-demand chunks too (chunks: 'all'): they load
          // after it, so a second copy there would only be dead weight.
          // Packages used only through import() stay in their own chunks (below).
          vendors: isProduction
            ? {
                name: 'vendors',
                test: (module, { chunkGraph }) =>
                  /[\\/]node_modules[\\/](?!@react-native[\\/]js-polyfills[\\/]|@swc[\\/]helpers[\\/])/.test(
                    module.resource ?? ''
                  ) && chunkGraph.getModuleChunks(module).some((chunk) => chunk.canBeInitial()),
                chunks: 'all',
                enforce: true,
                priority: 90,
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
      new (isSharedBuild ? SharedBuildRepackPlugin : Repack.RepackPlugin)({
        platform,
        // Every chunk is packaged with the SDK (assets on Android, resources on
        // iOS). Nothing is fetched from a remote at runtime.
        extraChunks: [{ include: /.*/, type: 'local' }],
      }),
      // Chunk files are evaluated as plain scripts. The React Native bundle
      // defines `self` only after InitializeCore has run, but the initial chunks
      // are evaluated *before* the entry, so give every chunk the same
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
