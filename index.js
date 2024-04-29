import {AppRegistry} from 'react-native';
import NewApp from './src/routes/Update';
import {name as appName, headless} from './app.json';
import {registerHeadless} from './src/headless/Headless.bs';

AppRegistry.registerComponent(appName, () => NewApp);
registerHeadless(headless);
