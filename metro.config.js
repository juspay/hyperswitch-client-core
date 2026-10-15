const {getDefaultConfig} = require('@react-native/metro-config');
// const exclusionList = require('metro-config/src/defaults/exclusionList');

/**
 * Metro configuration
 * https://facebook.github.io/metro/docs/configuration
 *
 * @type {import('@react-native/metro-config').MetroConfig}
 */

const path = require('path');

const defaultConfig = getDefaultConfig(__dirname);

const NOT_IN_HOSTED_PM_BUNDLE = ['@vgs/collect-react-native'];
const hostedPaymentMethodsBundle =
  process.env.HYPERSWITCH_BUNDLE === 'payment-methods';

module.exports = {
  ...defaultConfig,
  resolver: {
    ...defaultConfig.resolver,
    sourceExts: ['bs.js', ...defaultConfig.resolver.sourceExts],
    resolveRequest: (context, moduleName, platform) =>
      hostedPaymentMethodsBundle && NOT_IN_HOSTED_PM_BUNDLE.includes(moduleName)
        ? {
            type: 'sourceFile',
            filePath: path.join(
              __dirname,
              'src/payment-methods/hosted/notBundled.js',
            ),
          }
        : context.resolveRequest(context, moduleName, platform),
  },
};
