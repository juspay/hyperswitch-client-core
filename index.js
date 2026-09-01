import { AppRegistry, Platform } from 'react-native';
import NewApp, { HeadlessApp } from './src/routes/Update';
import { app as VaultFieldApp } from './src/vault/HsVaultEntry.bs.js';
import { name as appName, headless } from './app.json';

AppRegistry.registerComponent(appName, () => NewApp);
import "./vault"
if (Platform.OS === 'android') {
    AppRegistry.registerHeadlessTask(headless, () => async taskData => {
        HeadlessApp(taskData)
    });
} else if (Platform.OS === 'ios') {
    AppRegistry.registerComponent(headless, () => HeadlessApp);
}