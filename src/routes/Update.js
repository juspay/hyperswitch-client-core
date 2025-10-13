import React from 'react';
import App from './AppExports.js';
import {
  sentryReactNative,
  initiateSentry,
} from '../components/modules/Sentry.bs.js';
export { HeadlessApp } from './AppExports.js';

const NewApp = props => {
  return (
    <App
      props={props.props}
      rootTag={props.rootTag}
    />
  );
};

const SentryApp = React.memo(props => {
  initiateSentry(process.env.SENTRY_DSN, process.env.SENTRY_ENV);
  return sentryReactNative.wrap(NewApp)(props);
});

export default (
  SentryApp
);
