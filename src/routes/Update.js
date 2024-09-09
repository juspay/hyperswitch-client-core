import React, {useEffect} from 'react';
import CodePush from 'react-native-code-push';
import App from './AppExports.js';
import {Platform} from 'react-native';
import {
  sentryReactNative,
  initiateSentry,
} from '../components/modules/Sentry.bs.js';

const NewApp = props => {
  useEffect(() => {
    checkForUpdate();
  }, []);

  const checkForUpdate = () => {
    // setShow(true);
    CodePush.checkForUpdate(
      Platform.OS == 'android'
        ? process.env.HYPERSWITCH_CODEPUSH_ANDROID_KEY
        : process.env.HYPERSWITCH_CODEPUSH_IOS_KEY,
    )
      .then(update => {
        if (update) syncImmediate();
      })
      .catch(err => {});
  };

  const syncImmediate = async () => {
    await CodePush.sync(
      {
        checkFrequency: CodePush.CheckFrequency.ON_APP_START,
        installMode: CodePush.InstallMode.IMMEDIATE,
        updateDialog: false,
      },
      //   codePushStatusDidChange,
      //   codePushDownloadDidProgress,
    );
  };

  return (
    <App
      props={props.props}
      rootTag={props.rootTag}
      checkForUpdate={checkForUpdate}
    />
  );
};

const SentryApp = props => {
  return React.useMemo(() => {
    initiateSentry(
      process.env.HYPERSWITCH_SENTRY_DSN ||
        'https://c9e476046dd766abc5ed73583e8f6b69@sentry.hyperswitch.io/3',
    );
    return sentryReactNative.wrap(NewApp)(props);
  }, []);
};

export default CodePush({checkFrequency: CodePush.CheckFrequency.MANUAL})(
  SentryApp,
);
