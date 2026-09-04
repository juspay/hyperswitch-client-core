import { AppRegistry, Platform } from 'react-native';
import NewApp, { HeadlessApp, runHeadlessTask } from './src/routes/Update';
import { name as appName, headless } from './app.json';

AppRegistry.registerComponent(appName, () => NewApp);

if (Platform.OS === 'android') {
    AppRegistry.registerHeadlessTask(headless, () => taskData => runHeadlessTask(taskData.props));
} else if (Platform.OS === 'ios') {
    AppRegistry.registerComponent(headless, () => HeadlessApp);
}
