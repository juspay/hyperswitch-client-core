import {AppRegistry} from 'react-native';
import {name as appName} from '../app.json';
import {app} from './WebApp.bs.js';
import * as WebKit from '../src/hooks/WebKit.bs.js';

AppRegistry.registerComponent(appName, () => app);

const initReactNativeWeb = async () => {
  const searchParams = new URLSearchParams(
    new URL(window.location.href).search,
  );
  if (searchParams.size > 0 && searchParams.get('status') != undefined) {
    const apiResStatus = {};
    searchParams.forEach((value, key) => {
      apiResStatus[key] = value;
    });
    var match$1 = WebKit.useWebKit();
    var exitPaymentSheet = match$1.exitPaymentSheet;
    exitPaymentSheet(JSON.stringify(apiResStatus));
  } else {
    AppRegistry.runApplication(appName, {
      initialProps: {},
      rootTag: document.getElementById('app-root'),
    });
  }
};

initReactNativeWeb();
