#!/usr/bin/env node

/**
 * Environment Variable Validation Script
 * Validates that all required environment variables are present before building or starting the app
 */

require('dotenv').config({path: './.env'});

// Define required environment variables
const REQUIRED_ENV_VARS = {
  // Core Hyperswitch URLs
  HYPERSWITCH_PRODUCTION_URL: {
    required: true,
    description: 'Hyperswitch Production API URL',
  },
  HYPERSWITCH_SANDBOX_URL: {
    required: true,
    description: 'Hyperswitch Sandbox API URL',
  },
  HYPERSWITCH_INTEG_URL: {
    required: true,
    description: 'Hyperswitch Integration API URL',
  },

  // Assets endpoints
  PROD_ASSETS_END_POINT: {
    required: true,
    description: 'Production assets endpoint URL',
  },
  SANDBOX_ASSETS_END_POINT: {
    required: true,
    description: 'Sandbox assets endpoint URL',
  },
  INTEG_ASSETS_END_POINT: {
    required: true,
    description: 'Integration assets endpoint URL',
  },

  // Logs path
  HYPERSWITCH_LOGS_PATH: {
    required: true,
    description: 'Path for Hyperswitch logs',
  },
};

// Optional environment variables (will warn)
const OPTIONAL_ENV_VARS = {
  // Sentry keys are intentionally not validated as per requirements
  // SENTRY_DSN: {
  //   description: 'Sentry DSN (optional)',
  // },
  // SENTRY_ENV: {
  //   description: 'Sentry Environment (optional)',
  // },
};

function validateEnvironmentVariables() {
  console.log(`Validating environment variables...\n`);

  const missingVars = [];
  const emptyVars = [];
  const presentVars = [];
  const warnings = [];

  // Check required variables
  Object.entries(REQUIRED_ENV_VARS).forEach(([key, config]) => {
    const value = process.env[key];

    if (value === undefined) {
      missingVars.push({key, ...config});
    } else if (value.trim() === '') {
      emptyVars.push({key, ...config});
    } else {
      presentVars.push({key, ...config});
    }
  });

  // Check optional variables
  Object.entries(OPTIONAL_ENV_VARS).forEach(([key, config]) => {
    const value = process.env[key];

    if (value === undefined || value.trim() === '') {
      warnings.push({key, ...config});
    }
  });

  // Print results
  if (presentVars.length > 0) {
    console.log(
      `Found ${presentVars.length} required environment variable(s):`,
    );
    presentVars.forEach(({key}) => {
      console.log(`  ✓ ${key}`);
    });
    console.log();
  }

  if (warnings.length > 0) {
    console.log(`Optional environment variable(s) not set:`);
    warnings.forEach(({key, description}) => {
      console.log(` ${key} - ${description}`);
    });
    console.log();
  }

  if (missingVars.length > 0 || emptyVars.length > 0) {
    console.error(`Environment Variable Validation Failed!\n`);

    if (missingVars.length > 0) {
      console.error(`Missing required environment variable(s):`);
      missingVars.forEach(({key, description}) => {
        console.error(`  ${key} - ${description}`);
      });
      console.log();
    }

    if (emptyVars.length > 0) {
      console.error(`Empty required environment variable(s):`);
      emptyVars.forEach(({key, description}) => {
        console.error(`  ${key} - ${description}`);
      });
      console.log();
    }

    console.error(`Action Required:`);
    console.error(
      `1. Create a .env file in the project root if it doesn't exist`,
    );
    console.error(`2. Copy the contents from .en file as a template`);
    console.error(
      `3. Fill in all required environment variables with appropriate values`,
    );
    console.error(`4. Ensure no values are left empty\n`);

    process.exit(1);
  }

  console.log(`All required environment variables are present!\n`);
}

// Run validation
try {
  validateEnvironmentVariables();
} catch (error) {
  console.error(`Error during validation:`, error.message);
  process.exit(1);
}
