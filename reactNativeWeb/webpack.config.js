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
const repoPublicPath = isDevelopment ? `` : `/mobile/${repoVersion}`;

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
  '@juspay-tech/react-native-hyperswitch-netcetera-3ds',
  '@juspay-tech/react-native-scan-card',
  '@react-native-clipboard/clipboard',
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

const replaceConfiguration = {
  test: /Custom.*\.bs\.js$/,
  use: [
    {
      loader: 'string-replace-loader',
      options: {
        multiple: [
          {
            search: /accessible: false/g,
            replace: 'tabIndex: -1',
          },
          {
            search: /accessible: props.accessible/g,
            replace: 'tabIndex: (props.accessible === false ? -1 : 0)',
          },
        ],
      },
    },
  ],
};

const excludeConfiguration = {
  test: /^(?!.*\.(jsx?|tsx?|json|s?css|html|svg|png|jpe?g|gif|woff2?|ttf|eot)$).*/i,
  type: 'asset/resource',
  generator: {
    filename: '[name][ext]',
    emit: false,
  },
};

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
    port: 8082,
    historyApiFallback: {
      rewrites: [
        {from: /^\/redirect/, to: '/redirect.html'},
        {from: /./, to: '/index.html'},
      ],
    },
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
      '@juspay-tech/react-native-hyperswitch-netcetera-3ds': 'react-native-web',
      '@juspay-tech/react-native-hyperswitch-samsung-pay': 'react-native-web',
      'react-native-plaid-link-sdk': 'react-native-web',
      '@react-native-clipboard/clipboard':
        'react-native-web/dist/exports/Clipboard',
    },
  },
  optimization: {
    minimize: !isDevelopment,
    minimizer: [!isDevelopment && new TerserPlugin()].filter(Boolean),
  },
  module: {
    rules: [
      excludeConfiguration,
      babelLoaderConfiguration,
      imageLoaderConfiguration,
      svgLoaderConfiguration,
      replaceConfiguration,
    ],
  },
  plugins: [
    new HtmlWebpackPlugin({
      template: path.join(__dirname, 'index.html'),
      filename: 'index.html',
      chunks: ['app'],
    }),
    new HtmlWebpackPlugin({
      template: path.join(__dirname, 'redirect.html'),
      filename: 'redirect.html',
      chunks: [],
    }),
    new webpack.HotModuleReplacementPlugin(),
    isDevelopment && new ReactRefreshWebpackPlugin(),
    new webpack.DefinePlugin({
      // See: https://github.com/necolas/react-native-web/issues/349
      __DEV__: JSON.stringify(false),
    }),
  ].filter(Boolean),
};
