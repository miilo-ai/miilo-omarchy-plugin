import test from 'node:test';
import assert from 'node:assert/strict';
import vm from 'node:vm';
import { readFileSync } from 'node:fs';
const api=vm.createContext({});vm.runInContext(readFileSync(new URL('../ui/components/intake/IntakeState.js',import.meta.url),'utf8'),api);
const item={providerId:'custom',id:'task',revision:'r1',health:'healthy',extensions:{'io.miilo.intake':{version:1,source:{connectionId:'source',externalId:'TASK-1',revision:'source-r1'},workflowId:'project',synchronization:'not_required',decision:'pending',execution:'not_started'}},actions:[{id:'intake.accept',risk:'bounded',confirmation:'explicit',available:true}]};
test('unknown intake versions and unadvertised actions remain unavailable',()=>{
 assert.equal(api.available(item,'accept'),true);assert.equal(api.available(item,'dismiss'),false);
 const future=structuredClone(item);future.extensions['io.miilo.intake'].version=2;assert.equal(api.available(future,'accept'),false);
});
test('decision preserves exact revision and request identity without shell interpolation',()=>{
 const args=api.command(item,'accept','req','2026-11-27T00:00:00Z','');
 assert.deepEqual(Array.from(args),['decide','custom/task','--action','accept','--revision','r1','--request-id','req','--confirmed-at','2026-11-27T00:00:00Z']);
 assert.throws(()=>api.command(item,'dismiss','req','now',''));
});

test('typed and dictated decisions resolve only one advertised target',()=>{
 const one=structuredClone(item);one.extensions['io.miilo.intake'].source={connectionId:'source',revision:'source-r1',externalId:'TASK-1'};
 assert.equal(api.resolve('please accept TASK-1',[one]).action,'accept');
 assert.equal(api.resolve('accept',[one,structuredClone(one)]).item,undefined);
 assert.equal(api.resolve('do not accept TASK-1',[one]).handled,false);
 assert.equal(api.resolve('',[one]).handled,false);
 assert.equal(api.resolve('dismiss TASK-1',[one]).item,undefined);
});

test('source references disambiguate duplicate external IDs and unsafe links are not opened',()=>{
 const one=structuredClone(item),two=structuredClone(item);
 one.extensions['io.miilo.intake'].source={revision:'source-r1',externalId:'42',connectionId:'source-a'};one.extensions['io.miilo.intake'].workflowId='project-a';
 two.extensions['io.miilo.intake'].source={revision:'source-r1',externalId:'42',connectionId:'source-b'};two.extensions['io.miilo.intake'].workflowId='project-b';
 assert.equal(api.resolve('accept 42',[one,two]).item,undefined);
 assert.equal(api.resolve('accept project-b/42',[one,two]).item,two);
 assert.equal(api.safeLink('javascript:alert(1)'),false);assert.equal(api.safeLink('https://example.test/\nunsafe'),false);assert.equal(api.safeLink('https://example.test/pull/1'),true);
});

test('strong confirmations and unsupported required inputs remain disabled',()=>{
 const strong=structuredClone(item);strong.actions[0].confirmation='strong';assert.equal(api.available(strong,'accept'),false);
 const custom=structuredClone(item);custom.actions[0].inputSchema={required:['accountPassword']};assert.equal(api.available(custom,'accept'),false);
});

 test('malformed metadata, stale items and privileged actions cannot enable decisions',()=>{
  for (const change of [x=>delete x.extensions['io.miilo.intake'].source.revision,x=>x.health='stale',x=>x.actions[0].risk='privileged',x=>x.actions[0].confirmation='invented']) {
   const value=structuredClone(item);change(value);assert.equal(api.available(value,'accept'),false);
  }
  const value=structuredClone(item);value.extensions['io.miilo.intake'].synchronization='failed';assert.equal(api.label(value),'Source update failed');
 });
