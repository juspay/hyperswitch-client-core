module.exports = {
  assets: ['./assets/fonts/'],
  dependencies: {
    '@juspay-tech/react-native-hyperswitch-netcetera-3ds': { platforms: { android: null, ios: null } },
    '@juspay-tech/react-native-hyperswitch-paypal': { platforms: { android: null, ios: null } },
    '@juspay-tech/react-native-hyperswitch-scancard': { platforms: { android: null, ios: null } },
  },
  project: {
    android: {
      appName: 'demo-app',
    },
  },
};
