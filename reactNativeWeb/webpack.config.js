const path = require('path');
const TerserPlugin = require('terser-webpack-plugin');

require('dotenv').config({path: './.env'});

const webpack = require('webpack');
const HtmlWebpackPlugin = require('html-webpack-plugin');
const ReactRefreshWebpackPlugin = require('@pmmmwh/react-refresh-webpack-plugin');
const appDirectory = path.resolve(__dirname);
const {presets, plugins} = require(`${appDirectory}/babel.config.js`);
const isDevelopment = process.env.NODE_ENV == 'development';
const repoVersion = require('./version.json').version;
const majorVersion = 'v' + repoVersion.split('.')[0];
const repoPublicPath = isDevelopment
  ? ``
  : `/mobile/${repoVersion}/mobile/${majorVersion}`;

const compileNodeModules = [
  // Add every react-native package that needs compiling
  // 'react-native-gesture-handler',
  // 'react-native-linear-gradient',
  // 'react-native-klarna-inapp-sdk',
  'react-native-inappbrowser-reborn',
  '@react-native-picker/picker',
  '@react-navigation/material-top-tabs',
  '@react-navigation/stack',
  '@rescript/react',
  'react-native',
  'react-native-gesture-handler',
  'react-native-safe-area-context',
  'react-native-screens',
  'react-native-svg',
  'react-native-tab-view',
  'react-content-loader',
  'react-native-hyperswitch-netcetera-3ds',
  'react-native-scan-card',
].map(moduleName =>
  path.resolve(appDirectory, `../node_modules/${moduleName}`),
);

const babelLoaderConfiguration = {
  test: /\.js$|tsx?$/,
  // Add every directory that needs to be compiled by Babel during the build.
  include: [
    path.resolve(__dirname, 'index.web.js'), // Entry to your application
    path.resolve(__dirname, '../App.js'), // Change this to your main App file
    path.resolve(__dirname, '../src'),
    ...compileNodeModules,
  ],
  use: {
    loader: 'babel-loader',
    options: {
      cacheDirectory: true,
      presets,
      plugins: [
        ...plugins,
        isDevelopment && require.resolve('react-refresh/babel'),
      ].filter(Boolean),
    },
  },
};

const svgLoaderConfiguration = {
  test: /\.svg$/,
  use: [
    {
      loader: '@svgr/webpack',
    },
  ],
};

const imageLoaderConfiguration = {
  test: /\.(gif|jpe?g|png)$/,
  use: {
    loader: 'url-loader',
    options: {
      name: '[name].[ext]',
    },
  },
};

const authorizedScriptSources = [
  "'self'",
  'https://js.braintreegateway.com',
  'https://checkout.hyperswitch.io',
  'https://beta.hyperswitch.io',
  'https://dev.hyperswitch.io',
  'https://sandbox.hyperswitch.io',
  'https://fonts.googleapis.com',
  'https://pay.google.com',
  'https://tpgw.trustpay.eu/js/v1.js',
  'https://test-tpgw.trustpay.eu/js/v1.js',
  'https://applepay.cdn-apple.com/jsapi/v1/apple-pay-sdk.js',
  'https://img.mpay.samsung.com/gsmpi/sdk/samsungpay_web_sdk.js',
  'https://apple.com/apple-pay',
  'https://x.klarnacdn.net/kp/lib/v1/api.js',
  'https://www.paypal.com/sdk/js',
  'https://sandbox.digitalwallet.earlywarning.com/web/resources/js/digitalwallet-sdk.js',
  'https://checkout.paze.com/web/resources/js/digitalwallet-sdk.js',
  'https://cdn.plaid.com/link/v2/stable/link-initialize.js',
  'https://www.sandbox.paypal.com',
  'https://www.google.com/pay',
  'https://sandbox.secure.checkout.visa.com',
  'https://src.mastercard.com',
  'https://sandbox.src.mastercard.com',
  // Add other trusted sources here
];

// List of authorized external styles sources
const authorizedStyleSources = [
  "'self'",
  "'unsafe-inline'",
  'https://beta.hyperswitch.io',
  'https://dev.hyperswitch.io',
  'https://sandbox.hyperswitch.io',
  'https://fonts.googleapis.com',
  'http://fonts.googleapis.com',
  'https://src.mastercard.com',
  // Add other trusted sources here
];

const authorizedFontSources = [
  "'self'",
  'https://fonts.gstatic.com',
  'http://fonts.gstatic.com',
  // Add other trusted sources here
];

const authorizedImageSources = [
  "'self'",
  'https://www.gstatic.com',
  'https://static.scarf.sh/a.png',
  'https://www.paypalobjects.com',
  'https://googleads.g.doubleclick.net',
  'https://www.google.com',
  'data: *',
  // Add other trusted sources here
];

const authorizedFrameSources = [
  "'self'",
  'https://checkout.hyperswitch.io',
  'https://dev.hyperswitch.io',
  'https://beta.hyperswitch.io',
  'https://live.hyperswitch.io',
  'https://integ.hyperswitch.io',
  'https://app.hyperswitch.io',
  'https://sandbox.hyperswitch.io',
  'https://api.hyperswitch.io',
  'https://pay.google.com',
  'https://www.sandbox.paypal.com',
  'https://sandbox.src.mastercard.com/',
  'https://sandbox.secure.checkout.visa.com/',
  'https://checkout.wallet.cat.earlywarning.io/',
  'https://ndm-prev.3dss-non-prod.cloud.netcetera.com/',
  // Add other trusted sources here
];

const authorizedConnectSources = [
  "'self'",
  'https://checkout.hyperswitch.io',
  'https://dev.hyperswitch.io',
  'https://beta.hyperswitch.io',
  'https://live.hyperswitch.io',
  'https://integ.hyperswitch.io',
  'https://app.hyperswitch.io',
  'https://sandbox.hyperswitch.io',
  'https://api.hyperswitch.io',
  'https://www.google.com/pay',
  'https://pay.google.com',
  'https://google.com/pay',
  'https://www.sandbox.paypal.com',
  // Add other trusted sources here
];
module.exports = {
  entry: {
    app: path.join(__dirname, 'index.web.js'),
  },
  output: {
    path: path.resolve(appDirectory, 'dist'),
    filename: 'index.bundle.js',
    publicPath: `${repoPublicPath}/`,
  },
  devtool: 'source-map',
  devServer: {
    hot: true,
    port: 8081,
  },
  resolve: {
    extensions: [
      '.web.tsx',
      '.web.ts',
      '.tsx',
      '.ts',
      '.web.bs.js',
      '.bs.js',
      '.web.js',
      '.js',
    ],
    alias: {
      'react-native$': 'react-native-web',
      'react-native-linear-gradient': 'react-native-web-linear-gradient',
      'react-native-klarna-inapp-sdk/index': 'react-native-web',
      '@sentry/react-native': '@sentry/react',
      'react-native-hyperswitch-paypal': 'react-native-web',
      'react-native-hyperswitch-kount': 'react-native-web',
      'react-native-hyperswitch-netcetera-3ds': 'react-native-web',
      'react-native-plaid-link-sdk': 'react-native-web',
    },
  },
  optimization: {
    minimize: !isDevelopment,
    minimizer: [!isDevelopment && new TerserPlugin()].filter(Boolean),
  },
  module: {
    rules: [
      babelLoaderConfiguration,
      imageLoaderConfiguration,
      svgLoaderConfiguration,
    ],
  },
  plugins: [
    new HtmlWebpackPlugin({
      inject: true,
      template: path.join(__dirname, 'index.html'),
      chunks: ['app'],
      scriptLoading: 'blocking',
      // Add CSP meta tag
      meta: {
        'Content-Security-Policy': {
          'http-equiv': 'Content-Security-Policy',
          content: `default-src 'self'; script-src ${authorizedScriptSources.join(
            ' ',
          )}; style-src ${authorizedStyleSources.join(' ')};
          font-src ${authorizedFontSources.join(' ')}; 
          img-src ${authorizedImageSources.join(' ')}; 
          frame-src ${authorizedFrameSources.join(' ')}; 
          connect-src ${authorizedConnectSources.join(' ')};`,
        },
      },
    }),
    new webpack.HotModuleReplacementPlugin(),
    isDevelopment && new ReactRefreshWebpackPlugin(),
    new webpack.DefinePlugin({
      // See: https://github.com/necolas/react-native-web/issues/349
      __DEV__: JSON.stringify(false),
    }),
  ].filter(Boolean),
};
