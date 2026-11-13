import {test} from 'node:test';
import assert from 'node:assert/strict';
import {createRequire} from 'node:module';
const {configured}=createRequire(import.meta.url)('../tools/configure-window-appearance.cjs');
test('uses native appearance policy without opacity literals or global Quickshell rules',()=>{
  const original='-- Existing settings\nhl.config({decoration={rounding=8}})\n';
  const updated=configured(original);
  assert(updated.startsWith(original));
  assert(updated.includes('o.transparent_window({ class = "^org[.]quickshell$", title = "^Miilo One$" })'));
  assert(!/opacity\s*=|0\.\d+/.test(updated));
  assert.equal(configured(updated),updated);
});
test('keeps products independent and preserves custom blocks',()=>{
  const one=configured('');const both=configured(one,'Miilo Bench');
  assert(both.includes('title = "^Miilo Bench$"'));assert(both.startsWith(one));
  assert.throws(()=>configured(one.replace('o.transparent_window','custom_window')),/preserved/);
  assert.throws(()=>configured('', '.*'));
});
