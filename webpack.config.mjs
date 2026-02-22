import path from 'node:path';
import { fileURLToPath } from 'node:url';
import * as Repack from '@callstack/repack';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

/**
 * Webpack configuration enhanced with Re.Pack defaults for React Native.
 *
 * Learn about webpack configuration: https://webpack.js.org/configuration/
 * Learn about Re.Pack configuration: https://re-pack.dev/docs/guides/configuration
 */

export default Repack.defineWebpackConfig(env => {
    const { platform, mode } = env;
    return {
        context: __dirname,
        entry: './index.js',
        ...(mode === "production"
            ? {
                output: {
                    filename: 'hyperswitch.bundle',
                    chunkFilename: "[name].bundle",
                },
                optimization: {
                    splitChunks: {
                        cacheGroups: {
                            scancard: {
                                test: /@juspay-tech\/react-native-hyperswitch-scancard/,
                                name: 'react-native-hyperswitch-scancard',
                                chunks: 'async',
                                enforce: true,
                            },
                            netcetera3ds: {
                                test: /@juspay-tech\/react-native-hyperswitch-netcetera-3ds/,
                                name: 'react-native-hyperswitch-netcetera-3ds',
                                chunks: 'async',
                                enforce: true,
                            },
                        },
                    },
                }
            }
            : {
            }
        ),
        resolve: {
            alias: {
                react: path.resolve(__dirname, 'node_modules/react'),
                'react-native': path.resolve(__dirname, 'node_modules/react-native'),
            },
            ...Repack.getResolveOptions(),
            extensions: [
                ...(platform === 'android'
                    ? [
                        '.android.bs.js',
                        '.native.bs.js',
                    ]
                    : []),
                ...(platform === 'ios'
                    ? [
                        '.ios.bs.js',
                        '.native.bs.js',
                    ]
                    : []),
                '.web.bs.js',

                ...(platform === 'android'
                    ? ['.android.js', '.android.ts', '.android.tsx']
                    : []),
                ...(platform === 'ios'
                    ? ['.ios.js', '.ios.ts', '.ios.tsx']
                    : []),
                '.native.js',
                // base
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
                ...Repack.getAssetTransformRules(),
                {
                    test: /\.json$/,
                    type: 'json',
                },
                {
                    test: /\.(res|resi|ml|mli)$/,
                    loader: 'ignore-loader',
                },
                {
                    test: /\.svg$/,
                    loader: 'ignore-loader',
                },
                {
                    test: /shared-code\/.*$/,
                    exclude: /\.(bs\.js|js|json)$/,
                    loader: 'ignore-loader',
                },
                {
                    test: /\.[cm]?[jt]sx?$/,
                    type: 'javascript/auto',
                    use: {
                        loader: '@callstack/repack/babel-swc-loader',
                    },
                    parser: {
                        javascript: {
                            importMeta: true,
                            dynamicImport: true,
                        }
                    }
                }
            ],
        },
        plugins: [new Repack.RepackPlugin()],
    }
});