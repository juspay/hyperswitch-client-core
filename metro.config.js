const {getDefaultConfig} = require('@react-native/metro-config');
// const exclusionList = require('metro-config/src/defaults/exclusionList');

/**
 * Metro configuration
 * https://facebook.github.io/metro/docs/configuration
 *
 * @type {import('@react-native/metro-config').MetroConfig}
 */

const defaultConfig = getDefaultConfig(__dirname);

const siblingVault = require('node:path').resolve(__dirname, '../react-native-hyperswitch-vault');

module.exports = {
  ...defaultConfig,
  watchFolders: [...(defaultConfig.watchFolders ?? []), siblingVault],
  resolver: {
    ...defaultConfig.resolver,
    sourceExts: ['bs.js', ...defaultConfig.resolver.sourceExts],
    // Cross-package ReScript bs-dependencies reach into the sibling vault
    // package's `src/*.bs.js` directly. Metro's `exports` resolution blocks
    // those subpaths ("not listed in the exports of … Falling back to
    // file-based resolution") and the fallback silently produces broken
    // bundles (HsVaultEntry renders nothing). Disable the package-exports
    // gate so plain main/module/file resolution is used.
    unstable_enablePackageExports: false,
    // Let Metro resolve `react-native-hyperswitch-vault/...` (the rescript.json
    // name) as the sibling vault package.
    extraNodeModules: {
      'react-native-hyperswitch-vault': siblingVault,
      '@juspay-tech/react-native-hyperswitch-vault': siblingVault,
    },
  },
};
