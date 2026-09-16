import { AppRegistry } from 'react-native';
import PaymentMethods from './src/routes/PaymentMethodsSentry.js';
import { hyperswitchPaymentMethods } from './app.json';

AppRegistry.registerComponent(hyperswitchPaymentMethods, () => PaymentMethods);
