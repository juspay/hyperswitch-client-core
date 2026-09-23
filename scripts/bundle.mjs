#!/usr/bin/env node
/**
 * Builds one entry bundle with Re.Pack and installs it, with its chunk files and
 * images, into the native SDK.
 *
 *   node scripts/bundle.mjs --platform android|ios --entry index.js \
 *     --name hyperswitch --out <dir> [--assets-dest <dir>] [--hermes]
 *
 * Output, in <out>:
 *   <name>.bundle                    the entry the native host loads
 *   <name>.<chunk>.chunk.bundle      every chunk (react-native, sentry, paypal, ...)
 * Images go to --assets-dest (Android `res/`), or to <out>/assets/ on iOS.
 * Source maps go to build/sourcemaps/<platform>/, never into the SDK.
 * Chunk files of a previous build of the same entry are removed from <out>.
 *
 * --hermes compiles every chunk to Hermes bytecode (release). The entry is left
 * as JavaScript unless it is also listed; the Android gradle plugin and the iOS
 * build phase compile entries themselves.
 */
import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');

function arg(name, fallback) {
  const i = process.argv.indexOf(`--${name}`);
  if (i === -1) return fallback;
  const value = process.argv[i + 1];
  return value === undefined || value.startsWith('--') ? true : value;
}

const platform = arg('platform');
const entry = arg('entry', 'index.js');
const name = arg('name', 'hyperswitch');
const out = arg('out') && path.resolve(root, arg('out'));
const assetsDest = arg('assets-dest') && path.resolve(root, arg('assets-dest'));
const hermes = arg('hermes', false) === true;
if (!['android', 'ios'].includes(platform) || !out) {
  console.error('usage: bundle.mjs --platform android|ios --entry <file> --name <name> --out <dir> [--assets-dest <dir>] [--hermes]');
  process.exit(1);
}

const stage = path.join(root, 'build', 'bundles', platform, name);
const maps = path.join(root, 'build', 'sourcemaps', platform);
fs.rmSync(stage, { recursive: true, force: true });
fs.mkdirSync(stage, { recursive: true });
fs.mkdirSync(maps, { recursive: true });

const cli = path.join(root, 'node_modules', 'react-native', 'cli.js');
execFileSync(
  process.execPath,
  [
    cli, 'bundle',
    '--platform', platform,
    '--dev', 'false',
    '--reset-cache',
    '--entry-file', entry,
    '--bundle-output', path.join(stage, `${name}.bundle`),
    '--sourcemap-output', path.join(stage, `${name}.bundle.map`),
    '--assets-dest', path.join(stage, 'assets'),
  ],
  { cwd: root, stdio: 'inherit' }
);

const isChunk = (file) => file.startsWith(`${name}.`) && file.endsWith('.chunk.bundle');

// Remove chunk files a previous build of this entry left behind.
fs.mkdirSync(out, { recursive: true });
for (const file of fs.readdirSync(out)) {
  if (isChunk(file)) fs.rmSync(path.join(out, file));
}

// iOS puts chunk files (and their maps) in --assets-dest; Android next to the bundle.
const produced = new Map();
for (const dir of [stage, path.join(stage, 'assets')]) {
  if (!fs.existsSync(dir)) continue;
  for (const file of fs.readdirSync(dir)) {
    const full = path.join(dir, file);
    if (fs.statSync(full).isFile()) produced.set(file, full);
  }
}

const hermesc = (() => {
  const os = process.platform === 'darwin' ? 'osx-bin' : process.platform === 'win32' ? 'win64-bin' : 'linux64-bin';
  const candidates = [
    path.join(root, 'node_modules', 'hermes-compiler', 'hermesc', os, 'hermesc'),
    path.join(root, 'node_modules', 'react-native', 'sdks', 'hermesc', os, 'hermesc'),
  ];
  return candidates.find((c) => fs.existsSync(c));
})();

const installed = [];
for (const [file, full] of produced) {
  if (file.endsWith('.map')) {
    fs.copyFileSync(full, path.join(maps, file));
    continue;
  }
  if (file !== `${name}.bundle` && !isChunk(file)) continue;
  const target = path.join(out, file);
  if (hermes && isChunk(file)) {
    if (!hermesc) throw new Error('hermesc not found; install react-native with Hermes or drop --hermes');
    execFileSync(hermesc, ['-emit-binary', '-O', '-out', target, full], { stdio: 'inherit' });
  } else {
    fs.copyFileSync(full, target);
  }
  installed.push(file);
}

// Images. Android: drawable-*/ folders, into res/ (--assets-dest). iOS: an
// assets/ tree that React Native resolves next to the bundle, into <out>.
const imageSource = path.join(stage, 'assets');
const imageTarget = platform === 'ios' ? out : assetsDest;
let images = 0;
if (imageTarget && fs.existsSync(imageSource)) {
  const copy = (from, to) => {
    for (const entryName of fs.readdirSync(from)) {
      const src = path.join(from, entryName);
      if (fs.statSync(src).isDirectory()) {
        copy(src, path.join(to, entryName));
      } else if (!entryName.endsWith('.map') && !entryName.endsWith('.bundle')) {
        fs.mkdirSync(to, { recursive: true });
        fs.copyFileSync(src, path.join(to, entryName));
        images += 1;
      }
    }
  };
  copy(imageSource, imageTarget);
}

console.log(`\n${platform} ${name}: installed ${installed.length} files in ${path.relative(root, out)}`);
for (const file of installed.sort()) {
  console.log(`  ${file}  ${(fs.statSync(path.join(out, file)).size / 1024).toFixed(0)} KB`);
}
if (images) console.log(`  + ${images} images in ${path.relative(root, imageTarget)}`);
console.log(`  source maps: ${path.relative(root, maps)}`);
