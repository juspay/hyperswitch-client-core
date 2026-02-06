const path = require('path');

module.exports = {
  commands: require('@callstack/repack/commands/rspack'),
  project: {
    ios: {
      automaticPodsInstallation: true,
    },
  },
  dependencies: {
    'react-native-lib-demo': {
      root: path.join(__dirname, '.', 'react-native-lib-demo'),
    },
  },
};
