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

if (!fs.existsSync(reportPath)) {
  lines.push('## Maestro end-to-end results', '');
  lines.push('No report: the test step stopped before Maestro wrote one. See the "Maestro test" step log.');
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
if (fs.existsSync(outputDir)) {
  for (const run of fs.readdirSync(outputDir)) {
    const runDir = path.join(outputDir, run);
    if (!fs.statSync(runDir).isDirectory()) continue;
    for (const flow of fs.readdirSync(runDir)) {
      const shots = path.join(runDir, flow, 'screenshots');
      if (!fs.existsSync(shots)) continue;
      const target = path.join(screenshotsDir, flow.replace(/[^\w .()-]/g, '_'));
      fs.mkdirSync(target, {recursive: true});
      for (const file of fs.readdirSync(shots).filter(f => f.endsWith('.png'))) {
        fs.copyFileSync(path.join(shots, file), path.join(target, file));
        copied += 1;
      }
    }
  }
}

const markdown = `${lines.join('\n')}\n`;
if (process.env.GITHUB_STEP_SUMMARY) {
  fs.appendFileSync(process.env.GITHUB_STEP_SUMMARY, markdown);
}
console.log(markdown);
console.log(`${copied} screenshot(s) of failed flows collected in ${screenshotsDir}`);
