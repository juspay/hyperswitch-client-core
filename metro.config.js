// const {getDefaultConfig} = require('@react-native/metro-config');
// // const exclusionList = require('metro-config/src/defaults/exclusionList');

// /**
//  * Metro configuration
//  * https://facebook.github.io/metro/docs/configuration
//  *
//  * @type {import('@react-native/metro-config').MetroConfig}
//  */

// const defaultConfig = getDefaultConfig(__dirname);

// module.exports = {
//   ...defaultConfig,
//   resolver: {
//     ...defaultConfig.resolver,
//     sourceExts: ['bs.js', ...defaultConfig.resolver.sourceExts],
//   },
// };

const { getDefaultConfig, mergeConfig } = require('@react-native/metro-config');

/**
 * Metro configuration
 * https://reactnative.dev/docs/metro
 *
 * @type {import('@react-native/metro-config').MetroConfig}
 */
const config = {};
const defaultConfig = getDefaultConfig(__dirname);

module.exports = {
    ...defaultConfig,
    resolver: {
        ...defaultConfig.resolver,
        sourceExts: [...defaultConfig.resolver.sourceExts, 'cjs'],
    },
}
