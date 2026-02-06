import path from 'node:path';
import { fileURLToPath } from 'node:url';
import * as Repack from '@callstack/repack';
import { MoveAssetsPlugin } from './plugins/MoveAssetsPlugin.mjs';
import { IgnorePlugin } from '@rspack/core';


const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const optionalDependencies = [/react-native-lib-demo/];

export default Repack.defineRspackConfig(env => {
  const { platform, mode } = env;

  const appAssets =
    platform === 'android'
      ? path.resolve(__dirname, 'android/app/src/main/assets')
      : path.resolve(__dirname, 'ios/hyperswitch/resources');

  const appAssetsGenerated =
    platform === 'android'
      ? path.resolve(__dirname, 'build/hyperswitch/android')
      : path.resolve(__dirname, 'build/hyperswitch/ios');

  const libAssets =
    platform === 'android'
      ? path.resolve(__dirname, 'react-native-lib-demo/android/src/main/assets')
      : path.resolve(__dirname, 'react-native-lib-demo/ios/resources');

  return {
    entry: './index.js',
    resolve: {
      ...Repack.getResolveOptions(platform),
      extensions: [
        ...(platform === 'android' ? ['.android.bs.js', '.android.js', '.android.jsx', '.android.ts', '.android.tsx'] : []),
        ...(platform === 'ios' ? ['.ios.bs.js', '.ios.js', '.ios.jsx', '.ios.ts', '.ios.tsx'] : []),
        '.native.bs.js',
        '.native.js',
        '.native.jsx',
        '.native.ts',
        '.native.tsx',
        '.bs.js',
        '.js',
        '.jsx',
        '.ts',
        '.tsx',
        '.json',
      ],
      alias: {
        'shared-code/assets': false,
        'shared-code/.github': false,
        'shared-code/.git': false,
      },
    },
    module: {
      rules: [
        {
          test: /\.[jt]sx?$/,
          include: [
            path.resolve(__dirname, 'shared-code/sdk-utils'),
            path.resolve(__dirname, 'src'),
          ],
          exclude: /node_modules/,
          use: {
            loader: '@callstack/repack/babel-swc-loader',
            parallel: true,
            options: {}
          },
        },
        {
          test: /\.json$/,
          type: 'json',
        },
        {
          test: /\.svg$/,
          loader: 'ignore-loader',
        },
        {
          test: /\.jpeg|.png|.jpg|.gif|.webp|.md|$/,
          loader: 'ignore-loader',
        },
        {
          test: /shared-code\/assets\/.*\/jsons\/.*$/,
          loader: 'ignore-loader',
        },
        {
          test: /shared-code\/assets\/.*\/jsons-gzips\/.*$/,
          loader: 'ignore-loader',

        },
        {
          test: /\.(res|resi|ml|mli)$/,
          loader: 'ignore-loader',
        },
        ...Repack.getAssetTransformRules(),
      ],
    },
    ...(mode === 'production' && {
      output: {
        filename: 'hyperswitch.bundle',
        path: appAssetsGenerated,
        chunkFilename: '[name].chunk.bundle',
        clean: true,
      },
    }),
    plugins: [
      new Repack.RepackPlugin(
        mode === 'production'
          ? {
            extraChunks: [
              {
                test: optionalDependencies,
                type: 'remote',
                outputPath: libAssets,
              },
              {
                exclude: optionalDependencies,
                type: 'remote',
                outputPath: appAssets,
              },
            ],
          }
          : {},
      ),
      new IgnorePlugin({
        resourceRegExp: /shared-code\/(?!sdk-utils|assets)/,
      }),
      ...(mode === 'production'
        ? [
          new MoveAssetsPlugin({
            appAssetsPath: appAssets,
            patterns: optionalDependencies,
          }),
        ]
        : []),
    ],
  };
});