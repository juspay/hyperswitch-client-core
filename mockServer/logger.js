const colors = {
  reset: '\x1b[0m',
  bold: '\x1b[1m',
  dim: '\x1b[2m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  cyan: '\x1b[36m',
};

const logger = {
  info: message => {
    console.info(`${colors.bold}${colors.cyan}info${colors.reset} ${message}`);
  },
  error: (message, error = null) => {
    console.error(
      `${colors.bold}${colors.red}error${colors.reset} ${colors.red}${message}${colors.reset}`,
      error ? `\n${colors.reset}${JSON.stringify(error, null, 2)}` : '',
    );
  },
  warn: message => {
    console.warn(
      `${colors.bold}${colors.yellow}warn${colors.reset} ${message}`,
    );
  },
  debug: (message, data = null) => {
    if (process.env.NODE_ENV === 'development') {
      console.debug(
        `${colors.bold}${colors.green}debug ${colors.reset}${message}`,
        data
          ? `\n${colors.dim}${JSON.stringify(data, null, 2)}${colors.reset}`
          : '',
      );
    }
  },
};

module.exports = logger;
