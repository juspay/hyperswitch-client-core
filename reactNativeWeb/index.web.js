import {AppRegistry} from 'react-native';
import {name as appName} from '../app.json';
import {app} from './WebApp.bs.js';

AppRegistry.registerComponent(appName, () => app);

const initReactNativeWeb = async () => {
  AppRegistry.runApplication(appName, {
    initialProps: {},
    rootTag: document.getElementById('app-root'),
  });
};

initReactNativeWeb();
