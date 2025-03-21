import React from 'react';
import App from './AppExports.js';
import {
  sentryReactNative,
  initiateSentry,
} from '../components/modules/Sentry.bs.js';

const NewApp = props => {
  return (
    <App
      props={props.props}
      rootTag={props.rootTag}
    />
  );
};

const SentryApp = React.memo(props => {
    initiateSentry(
      process.env.HYPERSWITCH_SENTRY_DSN ||
        'https://c9e476046dd766abc5ed73583e8f6b69@sentry.hyperswitch.io/3',
    );
    return sentryReactNative.wrap(NewApp)(props);
});

export default (
  SentryApp
);
