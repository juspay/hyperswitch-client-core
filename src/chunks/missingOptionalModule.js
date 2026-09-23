/**
 * Stand-in for an optional package that is not installed at bundle time (see
 * rspack.config.mjs). Evaluating it throws, as a missing package did under
 * Metro; the SDK require()s every optional package inside try/catch and carries
 * on without it (src/chunks/OptionalPackage.res).
 */
throw new Error('Optional Hyperswitch module is not installed in this build');
