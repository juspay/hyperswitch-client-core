import React from 'react';
import {
  sentryReactNative,
  initiateSentry,
} from '../components/modules/Sentry.bs.js';

// Sentry is per JS realm, not per surface: initialise it once, however many
// roots this realm renders. Each realm (payments, PMM) bundles its own copy of
// this module, so the flag is naturally per-realm.
let sentryInitialised = false;

const withSentry = Root =>
  React.memo(props => {
    const dsn = process.env.SENTRY_DSN
    if (dsn) {
      if (!sentryInitialised) {
        sentryInitialised = true
        initiateSentry(dsn, process.env.SENTRY_ENV);
      }
      return typeof sentryReactNative.wrap === 'function'
        ? sentryReactNative.wrap(Root)(props)
        : Root(props);
    } else {
      return Root(props);
    }
  });

export default withSentry;
