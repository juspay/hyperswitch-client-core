#!/usr/bin/env node
import { readFileSync, readdirSync, statSync, existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const srcDir = path.join(root, 'src');

const failures = [];
const check = (ok, what) => {
  console.log(`  ${ok ? 'ok  ' : 'FAIL'}  ${what}`);
  if (!ok) failures.push(what);
};

const walk = (dir) =>
  readdirSync(dir, { withFileTypes: true }).flatMap((e) => {
    const full = path.join(dir, e.name);
    return e.isDirectory() ? walk(full) : [full];
  });

const sources = walk(srcDir)
  .filter((f) => f.endsWith('.res'))
  .map((f) => ({ file: path.relative(root, f), text: readFileSync(f, 'utf8') }));

check(sources.length > 20, `the scan found source files to scan (${sources.length})`);

const SAVED_CARD_ONLY = {
  'src/pages/payment/SavedPaymentSheet.res': 'CVC for an already-saved card; collects no new card',
  'src/utility/PaymentEvents.res': 'the emitter itself; its new-card caller is gone',
  'src/components/elements/SavedCardCvvComponent.res': 'CVC entry for a saved card',
  'src/headless/HeadlessCommon.res': 'confirms a saved card by token + re-entered CVC',
  'src/pages/widgets/CvcWidget.res': 'the CVC widget for a saved card',
};
const isExempt = (file) => Object.prototype.hasOwnProperty.call(SAVED_CARD_ONLY, file);

const scan = (label, pattern, { allowExempt = true } = {}) => {
  const hits = [];
  for (const { file, text } of sources) {
    if (allowExempt && isExempt(file)) continue;
    text.split('\n').forEach((line, i) => {
      const code = line
        .replace(/\/\*[\s\S]*?\*\//g, '')
        .replace(/^\s*\*.*$/, '')
        .replace(/\/\/.*$/, '');
      if (pattern.test(code)) hits.push(`${file}:${i + 1} ${line.trim().slice(0, 78)}`);
    });
  }
  check(
    hits.length === 0,
    `${label}${hits.length ? `\n        ${hits.slice(0, 4).join('\n        ')}` : ''}`
  );
  return hits;
};

console.log('Client-core owns no new-card data');

scan(
  'no React Final Form field is bound to a card write path',
  /useField\s*\(\s*["'`]?[^)]*payment_method_data\.card\./
);

const CARD_WIRE_KEYS = 'card_number|card_cvc|card_exp_month|card_exp_year|card_holder_name|card_network';

const CONSTRUCTION = new RegExp(
  `(?<![A-Za-z0-9_.])\\(\\s*["'\`](${CARD_WIRE_KEYS})["'\`]\\s*,` +
    `|(?<![A-Za-z0-9_.])\\(\\s*["'\`]card["'\`]\\s*,\\s*\\[`
);
scan('no card payment_method_data is constructed', CONSTRUCTION);

scan('no new-card emitCardInfo call', /emitter\.emitCardInfo|emitCardInfo\s*\(\s*~info/);

scan(
  'no client-core eligibility request',
  /useEligibilityCheckHook|\/eligibility["'`]|callEligibilityCheck\s*\(/
);

for (const name of ['CardElement', 'CardSchemeComponent', 'ScanCardButton', 'ScanCardModule']) {
  scan(`no reference to the deleted ${name}`, new RegExp(`\\b${name}\\b`), { allowExempt: false });
  check(
    !existsSync(path.join(srcDir, 'components/dynamic', `${name}.res`)) &&
      !existsSync(path.join(srcDir, 'components/elements', `${name}.res`)) &&
      !existsSync(path.join(srcDir, 'components/modules', `${name}.res`)),
    `${name}.res is deleted from disk`
  );
}

const grouper = sources.find((s) => s.file.endsWith('FieldGrouper.res'))?.text ?? '';
check(grouper.length > 0, 'FieldGrouper.res was found');
check(
  /CardNumber \| Cvc \| CardExpiryMonth \| CardExpiryYear \| CardNetwork \| CardHolderName => Card/.test(
    grouper
  ),
  'CardHolderName is classified as Card, so it reaches the library and not FullNameElement'
);
check(
  /\| FirstName \| LastName => Name/.test(grouper),
  'FirstName and LastName remain billing data in the Name group'
);

console.log('\nThe saved-card exemptions are genuinely saved-card only');

const NEW_CARD_TREE = [
  'src/components/dynamic/ParentElement.res',
  'src/components/dynamic/RequiredFields.res',
  'src/components/dynamic/DynamicFields.res',
  'src/components/vault/VaultCardElement.res',
  'src/components/vault/VaultCardForm.res',
];
for (const file of NEW_CARD_TREE) {
  const entry = sources.find((s) => s.file === file);
  check(entry !== undefined, `${file} exists`);
  if (!entry) continue;
  const referenced = Object.keys(SAVED_CARD_ONLY).filter((exempt) => {
    const moduleName = path.basename(exempt, '.res');
    return new RegExp(`\\b${moduleName}\\b`).test(entry.text);
  });
  check(
    referenced.length === 0,
    `${path.basename(file)} references no saved-card-only module (${referenced.join(', ') || 'none'})`
  );
}

console.log('\nThe scanner is not vacuous');

const SYNTHETIC = [
  ['a card field registration', `let x = ReactFinalForm.useField("payment_method_data.card.card_number")`, /useField\s*\(\s*["'`]?[^)]*payment_method_data\.card\./],
  [
    'a card body construction',
    'let d = [("card", [("card_number", pan)])]',
    CONSTRUCTION,
  ],
  ['a cardholder-name construction specifically', 'let d = [("card_holder_name", name)]', CONSTRUCTION],
  ['a new-card emitCardInfo', `emitter.emitCardInfo(~info)`, /emitter\.emitCardInfo|emitCardInfo\s*\(\s*~info/],
  ['an eligibility request', `let u = baseUrl ++ "/eligibility"`, /useEligibilityCheckHook|\/eligibility["'`]|callEligibilityCheck\s*\(/],
  ['a CardElement reference', `<CardElement fields />`, /\bCardElement\b/],
];
for (const [label, synthetic, pattern] of SYNTHETIC) {
  check(pattern.test(synthetic), `the scanner catches ${label}`);
}

const PERMITTED = [
  ['a required-field path declaration', '"required_field": "payment_method_data.card.card_number",'],
  ['a display name', '"display_name": "card_holder_name",'],
  ['a commented-out construction', '//           ("card_number", pan)'],
  ['a response accessor', 'card_holder_name: cardDict->getString("card_holder_name", ""),'],
  ['a reader for the card network', 'card_network: cardDict->getString("card_network", ""),'],
];
const constructionPattern = CONSTRUCTION;
for (const [label, permitted] of PERMITTED) {
  const code = permitted.replace(/\/\/.*$/, '');
  check(!constructionPattern.test(code), `the scanner does not flag ${label}`);
}

if (failures.length) {
  console.error('\n[verify-no-card-ownership] FAIL');
  for (const f of failures) console.error(`  - ${f}`);
  process.exit(1);
}
console.log('\n[verify-no-card-ownership] OK - client-core owns no new-card data');
