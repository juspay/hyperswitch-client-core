import {AppRegistry} from 'react-native';
import NewApp, {HeadlessApp} from './src/routes/Update';
import {name as appName, headless} from './app.json';

AppRegistry.registerComponent(appName, () => NewApp);

if (Platform.OS === 'android') {
    AppRegistry.registerHeadlessTask(headless, () => HeadlessApp);
} else if (Platform.OS === 'ios') {
    AppRegistry.registerComponent(headless, () => HeadlessApp);
}