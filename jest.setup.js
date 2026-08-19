// UMD bundles under shared-code (e.g. superposition.js) probe `self`, which
// the react-native jest environment does not define.
if (typeof global.self === 'undefined') {
  global.self = global;
}
