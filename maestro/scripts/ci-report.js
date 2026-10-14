#!/usr/bin/env node
// Turns a Maestro run into a readable CI result:
//   - a results table (status, flow, file, duration, failing step, reason) written to the GitHub job
//     summary ($GITHUB_STEP_SUMMARY) and printed to the job log
//   - one folder per failed flow, ready to upload:
//       FAILED - screen at failure.png  the screen when it failed, with a red banner naming the step and reason
//                                       (needs ImageMagick; without it the plain screenshot is copied)
//       README.txt                      flow, file, failing step, reason and the steps it ran
//       all-screenshots/                every screenshot Maestro took for the flow
// Only screenshots and step names are collected. Device logs and Maestro logs stay on the runner: they
// can carry the sandbox publishable key and payment session tokens.
//
// usage: node maestro/scripts/ci-report.js <junit-report.xml> <test-output-dir> <screenshots-out-dir>
const fs = require('fs');
const path = require('path');
const {execFileSync} = require('child_process');

const [reportPath, outputDir, screenshotsDir] = process.argv.slice(2);
if (!reportPath || !outputDir || !screenshotsDir) {
  console.error('usage: ci-report.js <junit-report.xml> <test-output-dir> <screenshots-out-dir>');
  process.exit(2);
}

const decode = text =>
  text
    .replace(/&quot;/g, '"')
    .replace(/&apos;/g, "'")
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&amp;/g, '&');
const attr = (tag, name) => {
  const match = tag.match(new RegExp(`\\s${name}="([^"]*)"`));
  return match ? decode(match[1]) : '';
};
const duration = seconds => {
  const total = Math.round(Number(seconds) || 0);
  return total >= 60 ? `${Math.floor(total / 60)}m ${total % 60}s` : `${total}s`;
};
const cell = text => text.replace(/\r?\n/g, ' ').replace(/\|/g, '\\|').trim();

// ---- Maestro commands.json: readable step names (types and targets only, never script bodies or env)

const selector = s => {
  if (!s) return '';
  const parts = [];
  if (s.idRegex) parts.push(`id=${s.idRegex}`);
  if (s.textRegex) parts.push(`text="${s.textRegex}"`);
  if (s.index !== undefined && s.index !== null) parts.push(`index=${s.index}`);
  return parts.join(' ');
};
const describe = command => {
  const [type, body = {}] = Object.entries(command || {})[0] || [];
  switch (type) {
    case 'launchAppCommand':
      return `launch app${body.stopApp ? ' (restart)' : ''}`;
    case 'stopAppCommand':
      return `stop ${body.appId || 'app'}`;
    case 'runFlowCommand':
      return body.sourceDescription ? `run ${body.sourceDescription}` : 'run inline steps';
    case 'runScriptCommand':
      return `run script ${body.sourceDescription || ''}`.trim();
    case 'evalScriptCommand':
      return 'evaluate script';
    case 'tapOnElement':
      return `tap ${selector(body.selector)}`;
    case 'inputTextCommand':
      return `type "${body.text}"`;
    case 'eraseTextCommand':
      return 'erase text';
    case 'pressKeyCommand':
      return `press ${body.code || 'key'}`;
    case 'hideKeyboardCommand':
      return 'hide keyboard';
    case 'swipeCommand':
      return 'swipe';
    case 'scrollUntilVisible':
      return `scroll until visible ${selector(body.selector)}`;
    case 'assertConditionCommand': {
      const condition = body.condition || {};
      const verb = body.timeout ? 'wait until' : 'assert';
      if (condition.visible) return `${verb} visible ${selector(condition.visible)}`;
      if (condition.notVisible) return `${verb} not visible ${selector(condition.notVisible)}`;
      if (condition.scriptCondition !== undefined) return `assert ${condition.scriptCondition}`;
      if (condition.platform) return `on ${condition.platform} only`;
      return 'assert';
    }
    case 'retryCommand':
      return 'retry';
    case 'repeatCommand':
      return 'repeat';
    case 'waitForAnimationToEndCommand':
      return 'wait for animation to end';
    default:
      return type ? type.replace(/Command$/, '') : 'step';
  }
};
const ICON = {COMPLETED: '✅', FAILED: '❌', SKIPPED: '⏭'};

const readCommands = dir => {
  try {
    return JSON.parse(fs.readFileSync(path.join(dir, 'commands.json'), 'utf8'))
      .filter(e => e && e.command && e.metadata)
      .sort((a, b) => (a.metadata.sequenceNumber || 0) - (b.metadata.sequenceNumber || 0));
  } catch {
    return [];
  }
};

// ---- Optional red banner on the failure screenshot (ImageMagick)

const imageTool = ['magick', 'convert'].find(tool => {
  try {
    execFileSync(tool, ['-version'], {stdio: 'ignore'});
    return true;
  } catch {
    return false;
  }
});
const annotate = (src, dst, text) => {
  if (!imageTool) return false;
  try {
    const identify = imageTool === 'magick' ? ['magick', ['identify']] : ['identify', []];
    const width = Number(
      execFileSync(identify[0], [...identify[1], '-format', '%w', src]).toString().trim(),
    );
    if (!width) return false;
    // caption: reads "@file" and expands "%" escapes, so neutralise both.
    const caption = text.replace(/%/g, '%%').replace(/^@/, ' @');
    const banner = ['(', '-size', `${width - 48}x`, '-background', '#B00020', '-fill', 'white'];
    const pointsize = ['-pointsize', String(Math.max(24, Math.round(width / 30)))];
    for (const font of [['-font', 'DejaVu-Sans'], []]) {
      try {
        execFileSync(
          imageTool,
          [...banner, ...font, ...pointsize, `caption:${caption}`, '-bordercolor', '#B00020', '-border', '24', ')', src, '-append', dst],
          {stdio: 'ignore'},
        );
        return true;
      } catch {
        // try without the font
      }
    }
  } catch {
    // fall through to the plain copy
  }
  return false;
};

// ---- Collect the run

const cases = new Map();
let suite = '';
if (fs.existsSync(reportPath)) {
  const xml = fs.readFileSync(reportPath, 'utf8');
  suite = (xml.match(/<testsuite\b[^>]*>/) || [''])[0];
  for (const [, attrs, body = ''] of xml.matchAll(/<testcase\b([^>]*?)(?:\/>|>([\s\S]*?)<\/testcase>)/g)) {
    const failure = body.match(/<failure\b[^>]*>([\s\S]*?)<\/failure>/);
    const name = attr(` ${attrs}`, 'name');
    cases.set(name, {
      name,
      file: attr(` ${attrs}`, 'file'),
      time: attr(` ${attrs}`, 'time'),
      passed: attr(` ${attrs}`, 'status') === 'SUCCESS' && !failure,
      reason: failure ? decode(failure[1]) : '',
    });
  }
}

// Flow folders Maestro wrote so far. Only flows that failed have a screenshots/ folder.
const flowDirs = fs.existsSync(outputDir)
  ? fs
      .readdirSync(outputDir)
      .map(run => path.join(outputDir, run))
      .filter(runDir => fs.statSync(runDir).isDirectory())
      .flatMap(runDir => fs.readdirSync(runDir).map(flow => ({flow, dir: path.join(runDir, flow)})))
      .filter(({dir}) => fs.statSync(dir).isDirectory())
  : [];

const failedAt = new Map(); // flow name -> failing step
let collected = 0;
let annotated = 0;
for (const {flow, dir} of flowDirs) {
  const shots = path.join(dir, 'screenshots');
  if (!fs.existsSync(shots)) continue;
  // A flow that passed after a retried or optional step also has screenshots; skip it.
  const testCase = cases.get(flow);
  if (testCase && testCase.passed) continue;

  const commands = readCommands(dir);
  // The failure is the last failed top-level step and the failed steps nested in it (they come after it).
  // Earlier failed steps that were retried or optional are not part of it.
  const failed = commands.filter(e => e.metadata.status === 'FAILED');
  const top = failed.filter(e => (e.metadata.depth || 0) === 0).pop();
  const chain = top ? failed.filter(e => (e.metadata.sequenceNumber || 0) >= (top.metadata.sequenceNumber || 0)) : failed;
  const deepest = chain.reduce((a, b) => ((b.metadata.depth || 0) >= (a ? a.metadata.depth || 0 : -1) ? b : a), null);
  const step = deepest ? describe(deepest.metadata.evaluatedCommand || deepest.command) : '';
  const reason =
    (testCase && testCase.reason) ||
    (deepest && deepest.metadata.error && deepest.metadata.error.message) ||
    'the run stopped before this flow finished';
  failedAt.set(flow, step);

  const pngs = fs.readdirSync(shots).filter(f => f.endsWith('.png')).sort();
  const shotArtifact = deepest && (deepest.metadata.artifacts || []).find(a => a.type === 'SCREENSHOT');
  const failShot = shotArtifact ? path.join(dir, shotArtifact.path) : path.join(shots, pngs[pngs.length - 1] || '');

  const target = path.join(screenshotsDir, flow.replace(/[^\w .()-]/g, '_'));
  fs.mkdirSync(path.join(target, 'all-screenshots'), {recursive: true});
  for (const file of pngs) {
    fs.copyFileSync(path.join(shots, file), path.join(target, 'all-screenshots', file));
    collected += 1;
  }
  const failurePng = path.join(target, 'FAILED - screen at failure.png');
  let banner = false;
  if (fs.existsSync(failShot)) {
    banner = annotate(failShot, failurePng, `FAILED: ${flow}\nat: ${step || 'unknown step'}\n${reason}`);
    if (banner) annotated += 1;
    else fs.copyFileSync(failShot, failurePng);
  }

  const steps = commands
    .filter(e => !['defineVariablesCommand', 'applyConfigurationCommand'].includes(Object.keys(e.command)[0]))
    .filter(e => (e.metadata.depth || 0) === 0 || e.metadata.status === 'FAILED')
    .map(e => `  ${'  '.repeat(e.metadata.depth || 0)}${ICON[e.metadata.status] || '…'} ${describe(e.metadata.evaluatedCommand || e.command)}`);
  const readme = [
    `Flow:      ${flow}`,
    `File:      ${testCase && testCase.file ? testCase.file : 'see the Maestro test step log'}`,
    `Failed at: ${step || 'unknown step'}`,
    `Reason:    ${reason}`,
    '',
    `"FAILED - screen at failure.png" is the screen at that moment${banner ? ' (the red banner repeats the step and reason)' : ''}.`,
    'all-screenshots/ has every screenshot Maestro took for this flow.',
    '',
    'Steps (✅ done, ❌ failed, ⏭ skipped; nested lines are inside the step above):',
    ...(steps.length ? steps : ['  (no step list: Maestro did not record its commands)']),
    '',
    'Logs are not included: they can contain the sandbox publishable key and payment session tokens.',
    'Run the flow locally for logs: see maestro/README.md, "Running".',
    '',
  ].join('\n');
  fs.writeFileSync(path.join(target, 'README.txt'), readme);
}

// ---- Summary

const lines = ['## Maestro end-to-end results', ''];
if (!fs.existsSync(reportPath)) {
  lines.push(
    '**⚠️ The run stopped before Maestro wrote its report** (cancelled or timed out), so this list is partial. ' +
      'See the "Maestro test" step log for every flow.',
    '',
  );
  if (failedAt.size > 0) {
    lines.push('| | Flow | Failed at |', '| --- | --- | --- |');
    for (const [flow, step] of failedAt) lines.push(`| ❌ | ${cell(flow)} | ${cell(step)} |`);
  }
} else {
  const all = [...cases.values()];
  const failed = all.filter(c => !c.passed);
  lines.push(
    `**${failed.length === 0 ? '✅ All passed' : `❌ ${failed.length} failed`}** · ${all.length - failed.length}/${all.length} passed · ` +
      `${duration(attr(suite, 'time'))} on ${attr(suite, 'device') || 'emulator'}`,
    '',
    '| | Flow | File | Duration | Failed at | Reason |',
    '| --- | --- | --- | --- | --- | --- |',
  );
  for (const c of [...failed, ...all.filter(x => x.passed)]) {
    lines.push(
      `| ${c.passed ? '✅' : '❌'} | ${cell(c.name)} | \`${cell(c.file)}\` | ${duration(c.time)} | ` +
        `${cell(failedAt.get(c.name) || '')} | ${cell(c.reason).slice(0, 300)} |`,
    );
  }
}
if (failedAt.size > 0) {
  lines.push(
    '',
    'Screenshots: **Artifacts → `maestro-failure-screenshots`** at the bottom of this page. Each failed flow has ' +
      '`FAILED - screen at failure.png` (the screen when it failed, with the step and reason on a red banner), ' +
      '`README.txt` (the steps it ran) and `all-screenshots/`.',
  );
}

const markdown = `${lines.join('\n')}\n`;
if (process.env.GITHUB_STEP_SUMMARY) {
  fs.appendFileSync(process.env.GITHUB_STEP_SUMMARY, markdown);
}
console.log(markdown);
console.log(
  `${failedAt.size} failed flow(s): ${collected} screenshot(s) collected, ${annotated} labelled ` +
    `(${imageTool ? `ImageMagick: ${imageTool}` : 'ImageMagick not found: plain screenshots'}) in ${screenshotsDir}`,
);
