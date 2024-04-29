let modulesToTranspile = [
    // Add every react-native package that needs compiling
    // 'react-native-linear-gradient',
    'react-native-klarna-inapp-sdk',
    'react-native-inappbrowser-reborn',
    'react-native-hyperswitch-paypal',
    'react-native-hyperswitch-kount',
    '@rescript/react',
    '@sentry/react-native',
    'react-native',
    'react-native-code-push',
    'react-native-svg',
    'rescript-react-native',
    'bs-fetch',
    'react-content-loader/native'
];

module.exports = {
    env: {
        environment: 'next',
    },
    output: 'export',
    typescript: {
        // !! WARN !!
        // Dangerously allow production builds to successfully complete even if
        // your project has type errors.
        // !! WARN !!
        ignoreBuildErrors: true,
    },
    transpilePackages: modulesToTranspile,
    experimental: {
        esmExternals: "loose",
        forceSwcTransforms: true,
    },
    webpack: (config) => {
        return {
            ...(config),
            resolve: {
                ...(config.resolve),
                alias: {
                    ...(config.resolve.alias),
                    // Transform all direct `react-native` imports to `react-native-web`
                    'react-native$': 'react-native-web',
                    // 'react-native-linear-gradient': 'react-native-web-linear-gradient',
                    'react-native-klarna-inapp-sdk/index': 'react-native-web',
                    '@sentry/react-native': '@sentry/nextjs',
                    'react-native-hyperswitch-paypal': 'react-native-web',
                    'react-native-hyperswitch-kount': 'react-native-web',
                    'react-native-inappbrowser-reborn': 'react-native-web',
                    'react-content-loader/native': 'react-content-loader',
                },
                extensions: [
                    '.web.tsx',
                    '.web.ts',
                    '.web.jsx',
                    '.web.js',
                    ...(config.resolve.extensions)
                ]
            }
        }
    },
}
