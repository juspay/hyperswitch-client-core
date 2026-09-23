module.exports = {
  presets: ['module:@react-native/babel-preset'],
  plugins: ['module:react-native-dotenv'],
  env: {
    // The bundler splits `import()` into chunks. Jest runs without
    // --experimental-vm-modules, so there it becomes a promised require.
    test: {
      plugins: ['@babel/plugin-transform-dynamic-import'],
    },
  },
};
