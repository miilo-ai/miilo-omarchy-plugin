import {test} from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {createRequire} from 'node:module';
const {plan}=createRequire(import.meta.url)('../tools/release-plan.cjs');
test('new stable version releases; existing tags are a no-op',()=>{
 assert.deepEqual(plan('0.3.0',['v0.1.0']),{tag:'v0.3.0',new_version:true});
 assert.equal(plan('0.3.0',['v0.3.0']).new_version,false);
 assert.equal(plan('0.10.0',['v0.9.0']).new_version,true);
});
test('invalid versions and downgrades fail closed',()=>{
 for(const v of ['01.2.0','0.3','0.3.0-rc.1','x;echo bad'])assert.throws(()=>plan(v,[]));
 assert.throws(()=>plan('0.2.0',['v0.3.0']));
});
test('automatic tagging follows source checks and explicitly dispatches the tag',()=>{
 const text=fs.readFileSync(new URL('../.github/workflows/version.yml',import.meta.url),'utf8');
 assert(text.includes('branches: [main]'));
 assert(text.indexOf('run: make check')<text.indexOf('git tag -a'));
 assert(text.includes('gh workflow run release.yml --ref "$TAG"'));
 assert(!text.includes('--force'));
 assert(text.includes("vars.MIILO_RELEASE_ENABLED != 'false'"));
 assert(text.includes('gh release view v1.5.0 --repo miilo-ai/miilo-owl-widgets'));
});
