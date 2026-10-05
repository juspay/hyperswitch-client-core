#!/usr/bin/env node
// Turns a Maestro run into a readable CI result:
//   - a results table (status, flow, file, duration, failure reason) written to the GitHub job summary
//     ($GITHUB_STEP_SUMMARY) and printed to the job log
//   - the screenshots of the failed flows copied into one folder, ready to upload
// Only screenshots are collected. Device logs and Maestro logs stay on the runner: they can carry the
// sandbox publishable key and payment session tokens.
//
// usage: node maestro/scripts/ci-report.js <junit-report.xml> <test-output-dir> <screenshots-out-dir>
const fs = require('fs');
const path = require('path');

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

const lines = [];
let failed = [];

// Flow folders Maestro wrote so far. Only flows that failed have a screenshots/ folder.
const flowDirs = fs.existsSync(outputDir)
  ? fs
      .readdirSync(outputDir)
      .map(run => path.join(outputDir, run))
      .filter(runDir => fs.statSync(runDir).isDirectory())
      .flatMap(runDir => fs.readdirSync(runDir).map(flow => ({flow, dir: path.join(runDir, flow)})))
      .filter(({dir}) => fs.statSync(dir).isDirectory())
  : [];

if (!fs.existsSync(reportPath)) {
  // The run stopped (cancelled or timed out) before Maestro wrote its report: list what is known.
  const stopped = flowDirs.filter(({dir}) => fs.existsSync(path.join(dir, 'screenshots')));
  lines.push('## Maestro end-to-end results', '');
  lines.push(
    '**⚠️ The run stopped before Maestro wrote its report** (cancelled or timed out), so this list is partial. ' +
      'See the "Maestro test" step log for every flow.',
    '',
  );
  if (stopped.length > 0) {
    lines.push('Flows that had failed by then:', '');
    stopped.forEach(({flow}) => lines.push(`- ❌ ${cell(flow)}`));
    lines.push(
      '',
      'Screenshots: **Artifacts → `maestro-failure-screenshots`** at the bottom of this page.',
    );
  }
} else {
  const xml = fs.readFileSync(reportPath, 'utf8');
  const suite = (xml.match(/<testsuite\b[^>]*>/) || [''])[0];
  const cases = [...xml.matchAll(/<testcase\b([^>]*?)(?:\/>|>([\s\S]*?)<\/testcase>)/g)].map(
    ([, attrs, body = '']) => {
      const failure = body.match(/<failure\b[^>]*>([\s\S]*?)<\/failure>/);
      return {
        name: attr(` ${attrs}`, 'name'),
        file: attr(` ${attrs}`, 'file'),
        time: attr(` ${attrs}`, 'time'),
        passed: attr(` ${attrs}`, 'status') === 'SUCCESS' && !failure,
        reason: failure ? decode(failure[1]) : '',
      };
    },
  );
  failed = cases.filter(c => !c.passed);
  const passedCount = cases.length - failed.length;
  const ordered = [...failed, ...cases.filter(c => c.passed)];

  lines.push('## Maestro end-to-end results', '');
  lines.push(
    `**${failed.length === 0 ? '✅ All passed' : `❌ ${failed.length} failed`}** · ${passedCount}/${cases.length} passed · ` +
      `${duration(attr(suite, 'time'))} on ${attr(suite, 'device') || 'emulator'}`,
    '',
  );
  lines.push('| | Flow | File | Duration | Failure |', '| --- | --- | --- | --- | --- |');
  for (const c of ordered) {
    lines.push(
      `| ${c.passed ? '✅' : '❌'} | ${cell(c.name)} | \`${cell(c.file)}\` | ${duration(c.time)} | ${cell(c.reason).slice(0, 300)} |`,
    );
  }
  if (failed.length > 0) {
    lines.push(
      '',
      'Screenshots of the failed flows: **Artifacts → `maestro-failure-screenshots`** at the bottom of this page ' +
        '(one folder per failed flow; the last screenshot is the moment it failed).',
    );
  }
}

// Screenshots of failed flows only: Maestro writes a screenshots/ folder only for flows that failed.
let copied = 0;
for (const {flow, dir} of flowDirs) {
  const shots = path.join(dir, 'screenshots');
  if (!fs.existsSync(shots)) continue;
  const target = path.join(screenshotsDir, flow.replace(/[^\w .()-]/g, '_'));
  fs.mkdirSync(target, {recursive: true});
  for (const file of fs.readdirSync(shots).filter(f => f.endsWith('.png'))) {
    fs.copyFileSync(path.join(shots, file), path.join(target, file));
    copied += 1;
  }
}

const markdown = `${lines.join('\n')}\n`;
if (process.env.GITHUB_STEP_SUMMARY) {
  fs.appendFileSync(process.env.GITHUB_STEP_SUMMARY, markdown);
}
console.log(markdown);
console.log(`${copied} screenshot(s) of failed flows collected in ${screenshotsDir}`);
