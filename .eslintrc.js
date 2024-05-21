module.exports = {
  root: true,
  extends: [],
  rules: {
    'react-hooks/rules-of-hooks': 'error',
  },
  env: {
    browser: true,
    es2021: true,
  },
  parserOptions: {
    ecmaVersion: 'latest',
    sourceType: 'module',
  },
  parser: '@babel/eslint-parser',
  plugins: ['react-hooks'],
};
