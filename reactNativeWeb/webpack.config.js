const path = require('path');
const TerserPlugin = require('terser-webpack-plugin');

const webpack = require('webpack');
const HtmlWebpackPlugin = require('html-webpack-plugin');
const ReactRefreshWebpackPlugin = require('@pmmmwh/react-refresh-webpack-plugin');
const appDirectory = path.resolve(__dirname);
const {presets, plugins} = require(`${appDirectory}/babel.config.js`);
const isDevelopment = process.env.NODE_ENV !== 'production';
console.log("dev mode --- >", isDevelopment)
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
  'react-native-code-push',
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

module.exports = {
  entry: {
    app: path.join(__dirname, 'index.web.js'),
  },
  output: {
    path: path.resolve(appDirectory, 'dist'),
    publicPath: '/',
    filename: 'index.bundle.js',
  },
  devtool: 'source-map',
  devServer: {
    hot: true,
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
      template: path.join(__dirname, 'index.html'),
    }),
    new webpack.HotModuleReplacementPlugin(),
    isDevelopment && new ReactRefreshWebpackPlugin(),
    new webpack.DefinePlugin({
      // See: https://github.com/necolas/react-native-web/issues/349
      __DEV__: JSON.stringify(false),
    }),
  ].filter(Boolean),
};