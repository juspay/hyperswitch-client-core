module.exports = {
  // Re.Pack (Rspack) replaces Metro for `start` and `bundle`; see rspack.config.mjs.
  commands: require('@callstack/repack/commands/rspack'),
  assets: ['./assets/fonts/'],
  project: {
    android: {
      appName: 'demo-app',
    },
  },
};
