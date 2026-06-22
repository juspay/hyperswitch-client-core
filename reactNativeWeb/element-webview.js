import { AppRegistry, DeviceEventEmitter } from 'react-native';
import { name as appName } from '../app.json';
import { app } from './WebApp.bs.js';

AppRegistry.registerComponent(appName, () => app);

const initReactNativeWeb = async () => {
  AppRegistry.runApplication(appName, {
    initialProps: {},
    rootTag: document.getElementById('app-root'),
  });
};

// ── triggerWidgetAction bridge ─────────────────────────────────────────────
//
// The parent SDK sends postMessage: { triggerWidgetAction: { actionType, rootTag } }
// We re-emit it via DeviceEventEmitter so that useWidgetActions (NativeEventListener)
// picks it up and calls confirmButtonData.handlePress().

window.addEventListener('message', (event) => {
  if (
    event.data?.type === 'webpackOk' ||
    event.data?.source === 'react-devtools-content-script'
  ) {
    return;
  }

  let data;
  if (typeof event.data === 'string') {
    try { data = JSON.parse(event.data); } catch { return; }
  } else {
    data = event.data;
  }

  if (!data || typeof data !== 'object') return;

  if (data.triggerWidgetAction) {
    DeviceEventEmitter.emit('triggerWidgetAction', data.triggerWidgetAction);
    return;
  }

  if (data.type === 'triggerWidgetAction') {
    DeviceEventEmitter.emit('triggerWidgetAction', {
      actionType: data.actionType,
      rootTag: data.rootTag,
    });
    return;
  }
});

initReactNativeWeb();