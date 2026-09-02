import { AppRegistry, Platform } from 'react-native';
import NewApp, { HeadlessApp } from './src/routes/Update';
import { name as appName, headless } from './app.json';

AppRegistry.registerComponent(appName, () => NewApp);

if (Platform.OS === 'android') {
    AppRegistry.registerHeadlessTask(headless, () => async taskData => {
        HeadlessApp(taskData)
    });
} else if (Platform.OS === 'ios') {
    AppRegistry.registerComponent(headless, () => HeadlessApp);
}