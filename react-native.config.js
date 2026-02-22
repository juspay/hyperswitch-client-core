const path = require('path');

module.exports = {
  commands: require('@callstack/repack/commands/webpack'),
  project: {
    ios: {
      automaticPodsInstallation: true,
    },
  },
  dependencies: {
      // '@juspay-tech/react-native-hyperswitch-click-to-pay': {
      //   root: path.join(__dirname, 'react-native-hyperswitch', 'packages', '@juspay-tech', 'react-native-hyperswitch-click-to-pay'),
      // },
      '@juspay-tech/react-native-hyperswitch-netcetera-3ds': {
        root: path.join(__dirname, 'react-native-hyperswitch', 'packages', '@juspay-tech', 'react-native-hyperswitch-netcetera-3ds'),
      },
      '@juspay-tech/react-native-hyperswitch-scancard': {
        root: path.join(__dirname, 'react-native-hyperswitch', 'packages', '@juspay-tech', 'react-native-hyperswitch-scancard'),
      },
    },
};
