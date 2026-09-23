// Must come first: tells the bundler's ScriptManager where chunk files live.
import './src/chunks/ScriptResolver.bs.js';
import { AppRegistry } from 'react-native';
import { pmm as pmmAppName } from './app.json';

// Separate moduleName, separate root component: runApplication("hyperPMM", ...)
// mounts the PMM navigator directly, no sdkState routing in the way.
import PMMRoot from './src/payment-method-management/PMMEntry';

AppRegistry.registerComponent(pmmAppName, () => PMMRoot);
