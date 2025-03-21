/** @type {import('next').NextConfig} */

const bsconfig = require('../rescript.json');

let transpileModules = [
    // Add every react-native package that needs compiling
    // 'react-native-linear-gradient',
    'react-native-klarna-inapp-sdk',
    'react-native-inappbrowser-reborn',
    // 'react-native-hyperswitch-paypal',
    // 'react-native-hyperswitch-kount',
    'react-native-plaid-link-sdk',
    '@sentry/react-native',
    'react-native',
    'react-native-web',
    'react-native-svg',
    'react-content-loader/native',
    'rescript'
].concat(bsconfig["bs-dependencies"]);

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
    transpilePackages: transpileModules,
    experimental: {
        esmExternals: "loose",
        forceSwcTransforms: true,
        turbo: {
            resolveAlias: {
                "react-native": "react-native-web",
                'react-native-klarna-inapp-sdk/index': 'react-native-web',
                '@sentry/react-native': '@sentry/nextjs',
                'react-native-hyperswitch-paypal': 'react-native-web',
                'react-native-hyperswitch-kount': 'react-native-web',
                'react-native-plaid-link-sdk': 'react-native-web',
                'react-native-inappbrowser-reborn': 'react-native-web',
                'react-content-loader/native': 'react-content-loader',
            },
            resolveExtensions: [
                ".web.bs.js",
                ".web.js",
                ".web.jsx",
                ".web.ts",
                ".web.tsx",
                ".mdx",
                ".tsx",
                ".ts",
                ".jsx",
                ".js",
                ".mjs",
                ".json",
            ],
        },
    },
    webpack: (config) => {
        config.resolve.alias = {
            ...(config.resolve.alias || {}),
            // Transform all direct `react-native` imports to `react-native-web`
            "react-native$": "react-native-web",
            'react-native-klarna-inapp-sdk/index': 'react-native-web',
            '@sentry/react-native': '@sentry/nextjs',
            'react-native-hyperswitch-paypal': 'react-native-web',
            'react-native-hyperswitch-kount': 'react-native-web',
            'react-native-plaid-link-sdk': 'react-native-web',
            'react-native-inappbrowser-reborn': 'react-native-web',
            'react-content-loader/native': 'react-content-loader',
        };
        config.resolve.extensions = [
            ".web.js",
            ".web.jsx",
            ".web.ts",
            ".web.tsx",
            ".web.bs.js",
            ...config.resolve.extensions,
        ];
        return config;
    },
};
