import React from 'react';
import { initiateSentry } from '../components/modules/Sentry.bs.js';

// Sentry is per JS realm, not per surface: initialise it once, however many
// roots this realm renders. Each realm (payments, PMM) bundles its own copy of
// this module, so the flag is naturally per-realm.
//
// Sentry is a chunk of its own on iOS and Android, loaded by initiateSentry, so
// roots are not wrapped with Sentry.wrap: its module is not there when they
// first render. Until it loads, error boundaries render without reporting
// (see Sentry.res).
let sentryInitialised = false;

const withSentry = Root =>
  React.memo(props => {
    const dsn = process.env.SENTRY_DSN;
    if (dsn && !sentryInitialised) {
      sentryInitialised = true;
      initiateSentry(dsn, process.env.SENTRY_ENV);
    }
    return <Root {...props} />;
  });

export default withSentry;
