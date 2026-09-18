#!/usr/bin/env node
// Verifies the bundle split invariants:
//  1. reach(pmmindex.js)  must not contain src/Payments/**
//  2. reach(index.js)     must not contain src/PaymentMethodManagement/**
//  3. Shared code must be under src/Common/** (or src/specs/)
// Run with --trace to print the import chain to each violation.
const fs = require('fs');
const path = require('path');
const ROOT = path.resolve(__dirname, '..');
const exts = ['.bs.js', '.js', '.ts', '.mjs'];
// NOTE: ReScript emits `import * as $$Window from "..."` for escaped names
// (`$$`, `Caml_*`, ...), so the binding clause must accept any chars up to
// the specifier quote — a narrower class like [\w*{}\s,] silently drops
// those edges and lets shared code hide in src/Payments.
const importRe = /(?:^|\n)\s*import\s+(?:[^"'\n;]+\s+from\s+)?["']([^"']+)["']/g;
const exportRe = /(?:^|\n)\s*export\s+[^"'\n;]*\s*from\s+["']([^"']+)["']/g;

function resolveImport(fromFile, spec) {
  if (!spec.startsWith('.')) return null;
  const base = path.resolve(path.dirname(fromFile), spec);
  for (const c of [base, ...exts.map(e => base + e)]) {
    if (fs.existsSync(c) && fs.statSync(c).isFile()) return c;
  }
  // platform-variant bs files: './Foo' -> Foo.(web|native|android|ios).bs.js
  const dir = path.dirname(base), stem = path.basename(base);
  try {
    for (const f of fs.readdirSync(dir)) {
      if (f.startsWith(stem + '.') && (f.endsWith('.bs.js') || f.endsWith('.js'))) return path.join(dir, f);
    }
  } catch {}
  return null;
}
function reach(seeds) {
  const seen = new Set();
  const parent = new Map();
  const queue = [...seeds.map(p => path.join(ROOT, p))];
  while (queue.length) {
    const f = queue.pop();
    if (seen.has(f)) continue;
    seen.add(f);
    let src;
    try { src = fs.readFileSync(f, 'utf8'); } catch { continue; }
    for (const re of [importRe, exportRe]) {
      re.lastIndex = 0;
      let m;
      while ((m = re.exec(src))) {
        const r = resolveImport(f, m[1]);
        if (r && r.startsWith(ROOT + '/src') && !seen.has(r)) {
          if (!parent.has(r)) parent.set(r, f);
          queue.push(r);
        }
      }
    }
  }
  seen.chainTo = target => {
    let chain = [];
    for (let n = target; n; n = parent.get(n)) chain.unshift(path.relative(ROOT, n));
    return chain;
  };
  return seen;
}

const pmm = reach(['pmmindex.js']);
const pay = reach(['index.js']);
const rel = f => path.relative(ROOT, f);

const bad1 = [...pmm].map(rel).filter(f => f.startsWith('src/Payments/'));
const bad2 = [...pay].map(rel).filter(f => f.startsWith('src/PaymentMethodManagement/'));
const shared = [...pmm].map(rel)
  .filter(f => f.startsWith('src/'))
  .filter(f => pay.has(path.join(ROOT, f)))
  .filter(f => !f.startsWith('src/Common/') && !f.startsWith('src/specs/'));

console.log('PMM bundle modules under src/:', [...pmm].map(rel).filter(f => f.startsWith('src/')).length);
console.log('Payments bundle modules under src/:', [...pay].map(rel).filter(f => f.startsWith('src/')).length);
console.log('\n[INVARIANT 1] Payments modules reachable from pmmindex.js:', bad1.length ? 'FAIL' : 'PASS');
bad1.forEach(f => {
  console.log('  BAD:', f);
  if (process.argv.includes('--trace')) console.log('      ' + pmm.chainTo(path.join(ROOT, f)).join('\n     -> '));
});
console.log('[INVARIANT 2] PMM modules reachable from index.js:', bad2.length ? 'FAIL' : 'PASS');
bad2.forEach(f => {
  console.log('  BAD:', f);
  if (process.argv.includes('--trace')) console.log('      ' + pay.chainTo(path.join(ROOT, f)).join('\n     -> '));
});
console.log('[INVARIANT 3] Shared modules outside src/Common/:', shared.length ? 'FAIL' : 'PASS');
shared.forEach(f => console.log('  MISPLACED:', f));
if (bad1.length || bad2.length || shared.length) process.exit(1);
