#!/usr/bin/env node
/**
 * Builds the SDK's JavaScript for one platform and installs it into the native SDK.
 *
 *   node scripts/bundle.mjs --platform android|ios --out <dir>
 *     [--entries hyperswitch,hyperswitch-payment-methods,...] [--assets-dest <dir>] [--hermes]
 *
 * Every entry is built in one compilation (rspack.config.mjs, shared build), so the
 * code the entries have in common is one set of chunk files that all of them load:
 *
 *   <entry>.bundle                       one per React host (--entries, default: all)
 *   hyperswitch.<chunk>.chunk.bundle     every chunk, shared by the entries
 *
 * Images go to --assets-dest (Android `res/`), or to <out>/assets/ on iOS. Source
 * maps go to build/sourcemaps/<platform>/, never into the SDK. Chunk files of a
 * previous build are removed from <out>, so a chunk that is gone stays gone.
 *
 * --hermes compiles every chunk to Hermes bytecode (release). Entries are left as
 * JavaScript; the Android gradle plugin and the iOS build phase compile those.
 */
import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');

const ALL_ENTRIES = [
  'hyperswitch',
  'hyperswitch-payment-methods',
  'hyperswitch-payment-method-management',
];
const CHUNK_PREFIX = 'hyperswitch.';
const CHUNK_SUFFIX = '.chunk.bundle';

function arg(name, fallback) {
  const i = process.argv.indexOf(`--${name}`);
  if (i === -1) return fallback;
  const value = process.argv[i + 1];
  return value === undefined || value.startsWith('--') ? true : value;
}

const platform = arg('platform');
const out = typeof arg('out') === 'string' ? path.resolve(root, arg('out')) : undefined;
const assetsDest =
  typeof arg('assets-dest') === 'string' ? path.resolve(root, arg('assets-dest')) : undefined;
const entries = typeof arg('entries') === 'string' ? arg('entries').split(',') : ALL_ENTRIES;
const hermes = arg('hermes', false) === true;

if (!['android', 'ios'].includes(platform) || !out) {
  console.error(
    'usage: bundle.mjs --platform android|ios --out <dir> [--entries a,b] [--assets-dest <dir>] [--hermes]'
  );
  process.exit(1);
}
const unknown = entries.filter((e) => !ALL_ENTRIES.includes(e));
if (unknown.length) {
  console.error(`unknown entries: ${unknown.join(', ')} (known: ${ALL_ENTRIES.join(', ')})`);
  process.exit(1);
}

// Every dependency must be installed. One that is not would be built as a stub
// with no chunk (rspack.config.mjs), and the install step below would then delete
// the SDK's copy of that chunk: after a pull that adds a package, run yarn install.
const { dependencies = {} } = JSON.parse(fs.readFileSync(path.join(root, 'package.json'), 'utf8'));
const notInstalled = Object.keys(dependencies).filter(
  (name) => !fs.existsSync(path.join(root, 'node_modules', name, 'package.json'))
);
if (notInstalled.length) {
  console.error(
    `package.json lists dependencies that are not installed:\n` +
      notInstalled.map((name) => `  ${name}`).join('\n') +
      `\nRun \`yarn install\`, then bundle again. Nothing was changed in ${path.relative(root, out)}.`
  );
  process.exit(1);
}

// Where Re.Pack writes the compilation (output.path in its defaults).
const built = path.join(root, 'build', 'generated', platform);
const maps = path.join(root, 'build', 'sourcemaps', platform);

execFileSync(
  process.execPath,
  [
    path.join(root, 'node_modules', 'react-native', 'cli.js'),
    'bundle',
    '--platform',
    platform,
    '--dev',
    'false',
    '--reset-cache',
  ],
  { cwd: root, stdio: 'inherit', env: { ...process.env, HYPERSWITCH_SHARED_BUILD: '1' } }
);

const isChunk = (file) => file.startsWith(CHUNK_PREFIX) && file.endsWith(CHUNK_SUFFIX);
const isEntry = (file) => ALL_ENTRIES.some((e) => file === `${e}.bundle`);

const produced = fs.readdirSync(built).filter((f) => fs.statSync(path.join(built, f)).isFile());
const missing = entries.filter((e) => !produced.includes(`${e}.bundle`));
if (missing.length) throw new Error(`the build produced no ${missing.join(', ')}`);

// Replace the previous build: every Hyperswitch chunk file (including the
// per-entry ones older builds made), and the entries being installed.
fs.mkdirSync(out, { recursive: true });
const previousChunks = fs.readdirSync(out).filter(isChunk);
for (const file of fs.readdirSync(out)) {
  const oldChunk = file.startsWith('hyperswitch') && file.endsWith(CHUNK_SUFFIX);
  if (oldChunk || entries.some((e) => file === `${e}.bundle`)) fs.rmSync(path.join(out, file));
}

const hermesc = (() => {
  const os =
    process.platform === 'darwin' ? 'osx-bin' : process.platform === 'win32' ? 'win64-bin' : 'linux64-bin';
  return [
    path.join(root, 'node_modules', 'hermes-compiler', 'hermesc', os, 'hermesc'),
    path.join(root, 'node_modules', 'react-native', 'sdks', 'hermesc', os, 'hermesc'),
  ].find((candidate) => fs.existsSync(candidate));
})();

fs.rmSync(maps, { recursive: true, force: true });
fs.mkdirSync(maps, { recursive: true });

const installed = [];
for (const file of produced) {
  const from = path.join(built, file);
  if (file.endsWith('.map')) {
    fs.copyFileSync(from, path.join(maps, file));
    continue;
  }
  const install = isChunk(file) || (isEntry(file) && entries.some((e) => file === `${e}.bundle`));
  if (!install) continue;
  const to = path.join(out, file);
  if (hermes && isChunk(file)) {
    if (!hermesc) throw new Error('hermesc not found; install react-native with Hermes or drop --hermes');
    execFileSync(hermesc, ['-emit-binary', '-O', '-out', to, from], { stdio: 'inherit' });
  } else {
    fs.copyFileSync(from, to);
  }
  installed.push(file);
}

// Images. Android: drawable-*/ folders, into res/ (--assets-dest). iOS: an assets/
// tree that React Native resolves next to the bundle, into <out>.
let images = 0;
const copyTree = (from, to) => {
  for (const name of fs.readdirSync(from)) {
    const src = path.join(from, name);
    if (fs.statSync(src).isDirectory()) {
      copyTree(src, path.join(to, name));
    } else {
      fs.mkdirSync(to, { recursive: true });
      fs.copyFileSync(src, path.join(to, name));
      images += 1;
    }
  }
};
const imageDirs = fs
  .readdirSync(built)
  .filter((f) => fs.statSync(path.join(built, f)).isDirectory());
for (const dir of imageDirs) {
  if (platform === 'ios' && dir === 'assets') copyTree(path.join(built, dir), path.join(out, 'assets'));
  if (platform === 'android' && dir.startsWith('drawable-') && assetsDest) {
    copyTree(path.join(built, dir), path.join(assetsDest, dir));
  }
}

console.log(`\n${platform}: installed ${installed.length} files in ${path.relative(root, out)}`);
for (const file of installed.sort()) {
  console.log(`  ${file}  ${(fs.statSync(path.join(out, file)).size / 1024).toFixed(0)} KB`);
}
if (images) {
  const where = platform === 'ios' ? path.join(out, 'assets') : assetsDest;
  console.log(`  + ${images} images in ${path.relative(root, where)}`);
}
console.log(`  source maps: ${path.relative(root, maps)}`);
const removed = previousChunks.filter((file) => !installed.includes(file));
if (removed.length) {
  console.warn(`  removed (this build has no such chunk): ${removed.join(', ')}`);
}
