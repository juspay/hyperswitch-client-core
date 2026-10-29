// Pinned web contracts keep CI deterministic and require no cross-repository credentials.
// To check a newer web checkout: node scripts/check-logger-parity.cjs --web-root ../hyperswitch-web
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');

const root = path.resolve(__dirname, '..');
const baseline = require('../src/Logger/__tests__/fixtures/web-contracts.json');
const extensions = {
  core: {},
  sdk: {
    walletStage: ['SheetStarted'],
    lifecycleEvent: [
      'ThreeDsSdkUnavailable',
      'SdkClosed(sdkClosedData)',
      'CustomerWentIdle(idleData)',
      'SdkInit(sdkInitData)',
      'SdkMounted',
      'SdkShimmerShown',
      'SdkRendered(sdkRenderData)',
      'FirstUserInteraction(firstInteractionData)',
      'PaymentConfirmAttempted(confirmAttemptData)',
      'PaymentConfirmResponse(confirmResponseData)',
      'PaymentConfirmFailed(confirmAttemptData)',
      'PaymentConfirmTimedOut(confirmAttemptData)',
      'ThreeDsStarted',
      'AuthenticationStarted(authenticationStartedData)',
      'PaymentDetailsFilled(paymentDetailsData)',
    ],
    userEvent: ['CardScanRequested'],
    apiEvent: ['ThreeDsAuthorize'],
    functionEvent: [
      'LaunchApplePay',
      'LaunchGooglePay',
      'LaunchPaypal',
      'LaunchSamsungPay',
      'LaunchScanCard',
      'InitialiseNetcetera',
      'GenerateAreqParams',
      'ReceiveChallengeParams',
      'GenerateChallenge',
    ],
    staticAssetEvent: ['LocaleStrings'],
  },
  merchant: {surface: ['PaymentSheet', 'Widget']},
};

// Expand the static shared catalog profiles used by the thin facades.
function moduleBody(source, name) {
  const match = new RegExp(`module ${name}\\s*=\\s*\\{`).exec(source);
  assert.ok(match, `missing shared catalog module ${name}`);
  const start = match.index + match[0].length;
  let depth = 1, quote = null, lineComment = false, blockComment = false;
  for (let i = start; i < source.length; i++) {
    const c = source[i], next = source[i + 1];
    if (lineComment) { if (c === '\n') lineComment = false; continue; }
    if (blockComment) { if (c === '*' && next === '/') { blockComment = false; i++; } continue; }
    if (quote) { if (c === '\\') i++; else if (c === quote) quote = null; continue; }
    if (c === '/' && next === '/') { lineComment = true; i++; continue; }
    if (c === '/' && next === '*') { blockComment = true; i++; continue; }
    if (c === '"' || c === '`') { quote = c; continue; }
    if (c === '{') depth++;
    if (c === '}' && --depth === 0) return source.slice(start, i);
  }
  throw new Error(`unterminated shared catalog module ${name}`);
}
function declarations(file) {
  const checkout = path.resolve(path.dirname(file), '../../..');
  const logging = path.join(checkout, 'shared-code/sdk-utils/logging');
  const catalogs = () => fs.readFileSync(path.join(logging, 'SharedLoggerEvents.res'), 'utf8');
  function expand(source) {
    return source.replace(/\binclude\s+(SharedLogger\.Types|SharedLoggerTypes|SharedLogger\.Events\.\w+|SharedLoggerEvents\.\w+|CommonSdk|Provider)\b/g, (_, include) => {
      if (include === 'SharedLogger.Types' || include === 'SharedLoggerTypes') {
        return fs.readFileSync(path.join(logging, 'SharedLoggerTypes.res'), 'utf8');
      }
      return expand(moduleBody(catalogs(), include.split('.').pop()));
    });
  }
  const source = expand(fs.readFileSync(file, 'utf8'))
    .replace(/\/\/[^\n]*|\/\*[\s\S]*?\*\//g, '');
  const types = {};
  for (const match of source.matchAll(/^\s*type (\w+)\s*=\s*/gm)) {
    const tail = source.slice(match.index + match[0].length);
    const end = tail.search(/^\s*(?:type|let|external)\b/m);
    types[match[1]] = (end < 0 ? tail : tail.slice(0, end))
      .replace(/(?:ClickToPayLoggerEvents|Provider)\.provider/g, 'provider')
      .replace(/\s+/g, '');
  }
  return types;
}

function variants(body) {
  return body.replace(/^\|/, '').split('|').sort();
}

function checkParity(mobileRoot = root, reference = baseline) {
  for (const [domain, relative] of Object.entries({
    core: 'core/LoggerTypes.res',
    sdk: 'sdk/SdkLoggerEvents.res',
    merchant: 'merchant/MerchantLoggerEvents.res',
  })) {
    const mobile = declarations(path.join(mobileRoot, 'src/Logger', relative));
    for (const [name, expected] of Object.entries(reference[domain])) {
      assert.ok(mobile[name], `${domain}.${name}: missing shared type`);
      if (expected.includes('|') || extensions[domain][name]) {
        assert.deepEqual(
          variants(mobile[name]),
          [...variants(expected), ...(extensions[domain][name] || [])].sort(),
          `${domain}.${name}: shared event/enum values drifted`,
        );
      } else {
        assert.equal(
          mobile[name],
          expected,
          `${domain}.${name}: payload fields drifted`,
        );
      }
    }
  }
  const config = fs.readFileSync(
    path.join(mobileRoot, 'src/Logger/core/LoggerConfig.res'),
    'utf8',
  );
  if (/include (?:SharedLoggerConfig|SharedLogger\.Config)\.Native\b/.test(config)) {
    const defaults = JSON.parse(fs.readFileSync(
      path.join(mobileRoot, 'shared-code/sdk-utils/logging/LoggerDefaults.json'), 'utf8'));
    assert.equal(defaults.schemaVersion, reference.schemaVersion, 'shared schema version drifted');
  } else {
    assert.match(config, new RegExp(`let schemaVersion = ${reference.schemaVersion}\\b`));
  }
}

if (require.main === module) {
  const index = process.argv.indexOf('--web-root');
  let reference = baseline;
  if (index >= 0) {
    assert.ok(process.argv[index + 1], '--web-root requires a checkout path');
    const web = path.resolve(process.argv[index + 1]);
    // Check the implementation as well as public contracts across the two checkouts.
    const relativeDir = 'shared-code/sdk-utils/logging';
    const files = checkout => fs.readdirSync(path.join(checkout, relativeDir))
      .filter(file => /\.(res|json)$/.test(file)).sort();
    assert.deepEqual(files(root), files(web), 'shared logging file inventory drifted');
    for (const file of files(root)) {
      const relative = path.join(relativeDir, file);
      assert.equal(fs.readFileSync(path.join(root, relative), 'utf8'),
        fs.readFileSync(path.join(web, relative), 'utf8'), `${file}: shared implementation drifted`);
    }
    reference = {
      ...baseline,
      core: declarations(path.join(web, 'src/Logger/core/LoggerTypes.res')),
      sdk: declarations(path.join(web, 'src/Logger/sdk/SdkLoggerEvents.res')),
      merchant: declarations(
        path.join(web, 'src/Logger/hyper-loader/HyperLoaderLoggerEvents.res'),
      ),
    };
    delete reference.core.context; // Internal context isolation is platform-specific.
    reference.sdk.provider = declarations(
      path.join(web, 'src/Logger/click-to-pay/ClickToPayLoggerEvents.res'),
    ).provider;
  }
  checkParity(root, reference);
  console.log(
    'Shared logger contracts match web; native extensions preserved.',
  );
}

module.exports = {checkParity};
