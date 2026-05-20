const path = require('path');

module.exports = {
  assets: ['./assets/fonts/'],
  project: {
    android: {
      appName: 'demo-app',
    },
  },
  dependencies: {
    'react-native-nfc-emv': {
      root: path.join(__dirname, '..', '..', '..', 'library', 'react-native-nfc-emv'),
    },
  },
};
