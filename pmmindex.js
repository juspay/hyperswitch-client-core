import { AppRegistry } from 'react-native';
import PMMApp from './src/PaymentMethodManagement/routes/PMMUpdate';
import { pmm as pmmAppName } from './app.json';

// Payment Methods Management flow — registered as a separate component so
// native hosts can mount it from its own (smaller, payments-free) bundle.
AppRegistry.registerComponent(pmmAppName, () => PMMApp);
