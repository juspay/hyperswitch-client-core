const path = require('path');

module.exports = {
  commands: require('@callstack/repack/commands/webpack'),
  project: {
    ios: {
      automaticPodsInstallation: true,
    },
  },
};
