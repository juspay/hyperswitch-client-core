const path = require('path');

module.exports = {
  commands: require('@callstack/repack/commands/rspack'),
  project: {
    ios: {
      automaticPodsInstallation: true,
    },
  },
};
