module.exports = {
  presets: [
    [
      'module:@react-native/babel-preset',
      {useTransformReactJSXExperimental: true},
    ],
  ],
  plugins: [
    ['react-native-web'],
    ['@babel/plugin-transform-flow-strip-types'],
    ['module:react-native-dotenv'],
    ['@babel/plugin-transform-react-jsx', {runtime: 'automatic'}],
    ['@babel/plugin-proposal-decorators', {legacy: true}],
    ['@babel/plugin-proposal-class-properties', {loose: true}],
    ['@babel/plugin-proposal-private-methods', {loose: true}],
    ['@babel/plugin-proposal-private-property-in-object', {loose: true}],
    '@babel/plugin-transform-runtime',
    // 'react-native-reanimated/plugin', // <--- Only add this plugin if "react-native-reanimated" is installed in your project.
  ],
};
