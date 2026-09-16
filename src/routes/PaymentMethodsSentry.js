import React from 'react';
import { make as PaymentMethods } from './PaymentMethods.bs.js';
import {
  sentryReactNative,
  initiateSentry,
} from '../components/modules/Sentry.bs.js';

const SentryPaymentMethods = React.memo(props => {
  const dsn = process.env.SENTRY_DSN
  if (dsn) {
    initiateSentry(dsn, process.env.SENTRY_ENV);
    return typeof sentryReactNative.wrap === 'function'
      ? sentryReactNative.wrap(PaymentMethods)(props)
      : PaymentMethods(props);
  } else {
    return PaymentMethods(props);
  }
});

export default (
  SentryPaymentMethods
);
