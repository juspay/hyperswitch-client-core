import { AppRegistry, Platform } from 'react-native';
import NewApp, { HeadlessApp } from './src/routes/Update';
import {ScriptManager, Script} from '@callstack/repack/client';
import { name as appName, headless } from './app.json';

ScriptManager.shared.addResolver(async (scriptId, caller) => {
  if (__DEV__) {
    return {
      url: Script.getDevServerURL(scriptId),
      cache: false,
    };
  }
  if (Platform.OS === 'android') {
    console.log('Resolving script for Android:', scriptId);
    return {
      url: Script.getFileSystemURL(`assets://${scriptId}`),
    };
  } else if (Platform.OS === 'ios') {
    console.log('Resolving script for iOS:', scriptId);
    return {
      url: Script.getFileSystemURL(`${scriptId}`),
    };
  }
  return {
    url: Script.getRemoteURL(`https://URL.com/assets/v1/chunks/${scriptId}`),
  };
});

AppRegistry.registerComponent(appName, () => NewApp);

if (Platform.OS === 'android') {
    AppRegistry.registerHeadlessTask(headless, () => async taskData => {
        HeadlessApp(taskData)
    });
} else if (Platform.OS === 'ios') {
    AppRegistry.registerComponent(headless, () => HeadlessApp);
}