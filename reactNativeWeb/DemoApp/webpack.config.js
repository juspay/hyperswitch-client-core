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
    port: 8082, // Specify the port here
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
      template : path.join(__dirname, "DemoAppIndex.html")
    }),
  ]
};
