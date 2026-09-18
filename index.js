import { AppRegistry } from 'react-native';
import NewApp, { HeadlessApp } from './src/Payments/routes/Update';
import { name as appName, headless } from './app.json';

AppRegistry.registerComponent(appName, () => NewApp);

// Viewless surface on both platforms: prerender() on Android, detached root view on iOS.
AppRegistry.registerComponent(headless, () => HeadlessApp);
