/**
 * Stand-in for an optional package that is loaded with `import()` and is not
 * installed at bundle time (see rspack.config.mjs).
 *
 * It must not throw: an exception while a dynamically imported module is
 * evaluated is reported by the bundler runtime as a fatal error. It exports
 * nothing instead, and every loader treats a missing export as "not in this
 * build" (Sentry.res, PaypalModule.res, ScanCardModule.res,
 * Netcetera3dsModule.res, payment-methods/providers/sdkChunks.ts).
 */
module.exports = {};
