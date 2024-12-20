module.exports = {
  presets: [
    '@babel/preset-env', // Handles modern JavaScript features like `export`
  ],
  plugins: [
    '@babel/plugin-transform-modules-commonjs', // Transforms ES modules to CommonJS for Jest compatibility
  ],
};
