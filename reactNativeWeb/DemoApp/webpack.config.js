const path = require('path');
const webpack = require('webpack');
const HtmlWebpackPlugin = require('html-webpack-plugin');
const appDirectory = path.resolve(__dirname);

module.exports = {
  entry: {
    app: path.join(__dirname, 'DemoAppIndex.js'),
  },
  output: {
    path: path.resolve(appDirectory, 'dist'),
    publicPath: '/',
    filename: 'index.bundle.js',
  },
  devtool: 'source-map',
  devServer: {
    open: true,
    port: 8083,
    watchFiles: [
      path.join(__dirname, '..', 'hyperswitch-lite-sdk.js'),
    ],
    static: [
      {
        directory: path.join(__dirname, '..'),
        publicPath: '/',
        watch: true,
      },
    ],
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
  },
  plugins: [
    new HtmlWebpackPlugin({
      template: path.join(__dirname, 'DemoAppIndex.html'),
    }),
  ],
};
