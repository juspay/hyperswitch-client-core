import path from 'node:path';
import { fileURLToPath } from 'node:url';
import * as Repack from '@callstack/repack';
import { MoveAssetsPlugin } from './plugins/MoveAssetsPlugin.mjs';
import { IgnorePlugin } from '@rspack/core';


const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const optionalDependencies = [/react-native-lib-demo/];

// Patterns to exclude from being generated in appAssets folder
const excludeFromAppAssets = [
  /react-native-lib-demo/,
  /shared-code_assets_v1_icons_mobile_/,  // Exclude mobile icons (v1)
  /shared-code_assets_v2_icons_/,  // Exclude v2 icons
  /shared-code_assets_v1_jsons_locales_/,  // Exclude locale jsons (v1)
  /shared-code_assets_/,
  /shared-code_github_/,
  /shared-code_assets_v1_jsons_location_/,
  /shared-code_assets_v1_configs_/,
  /shared-code_assets_v2_jsons_location_/,  // Exclude locale jsons (v2)
  /shared-code_assets_v1_jsons-gzips_locales_/,  // Exclude locale gzips (v1)
  /_svg\.chunk\.bundle$/,  // Exclude SVG chunk bundles
  /_gif\.chunk\.bundle$/,  // Exclude GIF chunk bundles
  /_jpeg\.chunk\.bundle$/,  // Exclude JPEG chunk bundles
  /shared-code_assets_README/,  // Exclude README files
  /shared-code_LICENCE/,  // Exclude LICENCE files
  /shared-code_README/,  // Exclude README files
  /\.map$/,  // Exclude sourcemap files
  /^[0-9a-f]{16}$/,  // Exclude hash-named files (sourcemap references)
];

// Patterns to clean up from raw/ and drawable-mdpi/ directories
const cleanupRawPatterns = [
  /sharedcode_assets_v1_icons_mobile_/,  // Remove mobile icons (v1)
  /sharedcode_assets_v2_icons_/,  // Remove v2 icons
  /\.svg$/,  // Remove all SVG files
  /\.yml$/,  // Remove YML files
  /sharedcode_github_/,  // Remove github workflow files
];

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
            options: {
              cacheDirectory: true,
            }
          },
        },
        {
          test: /\.json$/,
          type: 'json',
          include: [
            path.resolve(__dirname, 'shared-code/sdk-utils'),
            path.resolve(__dirname, 'shared-code/assets'),
          ],
        },

        {
          test: /\.[cm]?[jt]sx?$/,
          type: 'javascript/auto',
          use: {
            loader: '@callstack/repack/babel-swc-loader',
            parallel: true,
            options: {},
          },
        },
        {
          test: /\.(res|resi|ml|mli)$/,
          loader: 'ignore-loader'
        },
        {
          test: /\.svg$/,
          loader: 'ignore-loader',
        },
        {
          test: /\.json$/,
          type: 'json'
        },
        {
          test: /shared-code\/assets\/v1\/icons\/mobile\/.*$/,
          loader: 'ignore-loader'
        },
        {
          test: /shared-code\/assets\/v2\/icons\/.*$/,
          loader: 'ignore-loader'
        }, {
          test: /shared-code\/assets\/v2\/jsons\/.*$/,
          type: 'json'
        },
        {
          test: /shared-code\/assets\/v1\/jsons\/.*$/,
          type: 'json'
        },
        {
          test: /shared-code\/assets\/v1\/jsons-gzips\/.*$/,
          type: 'asset/resource'
        },
        {
          test: [/shared-code\/assets\/README.md/, /shared-code\/README.md/, /shared-code\/LICENCE/, /shared-code\/.github\/.*$/],
          loader: 'ignore-loader'
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
      devtool: false,  // Disable sourcemaps in production
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
                outputPath: appAssetsGenerated,  // Output to build folder first, MoveAssetsPlugin will copy wanted files
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
            patterns: excludeFromAppAssets,
            cleanupRawPatterns: cleanupRawPatterns,
          }),
        ]
        : []),
    ],
  };
});
