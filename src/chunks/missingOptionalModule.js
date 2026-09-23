/**
 * Stand-in for an optional package that is loaded with `require()` inside a
 * try/catch and is not installed at bundle time (see rspack.config.mjs).
 * Evaluating it throws, so the `require()` fails the way it did under Metro.
 * Packages loaded with `import()` use missingOptionalModule.async.js instead.
 */
throw new Error('Optional Hyperswitch module is not installed in this build');
