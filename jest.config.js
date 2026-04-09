/** @type {import('jest').Config} */
module.exports = {
  preset: 'react-native',
  testMatch: [
    '<rootDir>/__tests__/**/*.test.ts',
    '<rootDir>/__tests__/**/*.test.tsx',
    '<rootDir>/src/__tests__/**/*.test.ts',
    '<rootDir>/src/__tests__/**/*.test.tsx',
  ],
  testPathIgnorePatterns: [
    '/node_modules/',
    '/detox-tests/',
  ],
  setupFiles: ['<rootDir>/jest.setup.js'],
  transform: {
    '\\.bs\\.js$': 'babel-jest',
    '\\.tsx?$': ['babel-jest', { presets: ['module:@react-native/babel-preset'] }],
  },
  transformIgnorePatterns: [
    'node_modules/(?!(react-native|@react-native|@rescript|rescript|@glennsl|rescript-react-native)/)',
  ],
  moduleFileExtensions: ['ts', 'tsx', 'js', 'jsx', 'json', 'node', 'native.bs.js', 'web.bs.js', 'bs.js'],
  collectCoverage: true,
  coverageDirectory: '<rootDir>/coverage',
  coverageReporters: ['text', 'lcov', 'json-summary'],
  collectCoverageFrom: [
    // --- Shared-code (pure logic) ---
    'shared-code/sdk-utils/validation/**/*.bs.js',
    'shared-code/sdk-utils/utils/**/*.bs.js',
    'shared-code/sdk-utils/events/**/*.bs.js',
    'shared-code/sdk-utils/types/**/*.bs.js',

    // --- src/types (pure mappers & data transformers) ---
    'src/types/**/*.bs.js',

    // --- src/utility (logics, constants, config, reusableCodeFromWeb) ---
    'src/utility/logics/**/*.bs.js',
    'src/utility/constants/**/*.bs.js',
    'src/utility/config/**/*.bs.js',
    'src/utility/reusableCodeFromWeb/**/*.bs.js',

    // --- Pure functions inside hooks ---
    'src/hooks/**/*.bs.js',

    // --- Contexts (testable with renderHook + providers) ---
    'src/contexts/**/*.bs.js',

    // --- Headless (has some pure functions) ---
    'src/headless/**/*.bs.js',

    // --- Exclusions: impure / untestable ---
    '!**/node_modules/**',
    '!**/__tests__/**',
    '!**/detox-tests/**',
    // Components and pages are React components (test via renderHook where applicable)
    '!src/components/**',
    '!src/pages/**',
    '!src/routes/**',
    '!src/icons/**',
    // Portal library is React components
    '!src/utility/libraries/**',
    // Test utilities
    '!src/utility/test/**',
    // Shared-code hooks/components are React-dependent
    '!shared-code/sdk-utils/hooks/**',
    '!shared-code/sdk-utils/components/**',
  ],
  coveragePathIgnorePatterns: [
    '/node_modules/',
    '/detox-tests/',
    '/__tests__/',
  ],
  testResultsProcessor: 'jest-sonar-reporter',
};
