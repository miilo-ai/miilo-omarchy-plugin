import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import test from 'node:test';
import assert from 'node:assert/strict';
const script=path.resolve(import.meta.dirname,'../uninstall.sh');
function fixture(t){
  const root=fs.realpathSync(fs.mkdtempSync(path.join(os.tmpdir(),'miilo-uninstall-')));
  t.after(()=>fs.rmSync(root,{recursive:true,force:true}));
  fs.writeFileSync(path.join(root,'present'),'');fs.writeFileSync(path.join(root,'private-config'),'keep');
  const manager=path.join(root,'omarchy');
  fs.writeFileSync(manager,`#!/bin/bash
set -eu
printf '%s\\n' "$*" >> "$STATE/calls"
case "$2" in
list)
  [ "\${FAIL_LIST:-0}" = 0 ] || exit 3
  if [ -f "$STATE/present" ]; then printf '[{"id":"io.miilo.bar"},{"id":"other.widget"}]'; else printf '[{"id":"other.widget"}]'; fi ;;
disable) [ "\${FAIL_DISABLE:-0}" = 0 ] || exit 4; touch "$STATE/disabled" ;;
remove)
  [ -f "$STATE/disabled" ] || exit 9
  [ "\${FAIL_REMOVE:-0}" = 0 ] || exit 5
  rm "$STATE/present" ;;
*) exit 8 ;;
esac
`,{mode:0o755});
  return {root,run:(args=[],extra={})=>spawnSync('bash',[script,...args],{encoding:'utf8',env:{...process.env,HOME:root,MIILO_OMARCHY_EXECUTABLE:manager,STATE:root,...extra}})};
}
test('default preview does not disable or remove; warns about retained observers',t=>{
  const {root,run}=fixture(t),r=run();assert.equal(r.status,0,r.stderr);
  assert.match(r.stdout,/observer continues/);assert.match(r.stdout,/Plan:/);
  assert.equal(fs.readFileSync(path.join(root,'calls'),'utf8').trim(),'plugin list --json');
});
test('confirmed removal disables first, verifies absence, retains data and repeats safely',t=>{
  const {root,run}=fixture(t),r=run(['--confirm']);assert.equal(r.status,0,r.stderr);
  assert.equal(fs.existsSync(path.join(root,'present')),false);
  assert.equal(fs.readFileSync(path.join(root,'private-config'),'utf8'),'keep');
  assert.match(fs.readFileSync(path.join(root,'calls'),'utf8'),/plugin disable io.miilo.bar\nplugin remove io.miilo.bar --yes/);
  assert.match(run(['--confirm']).stdout,/already absent/);
});
test('failed unload prevents removal',t=>{
  const {root,run}=fixture(t),r=run(['--confirm'],{FAIL_DISABLE:'1'});assert.notEqual(r.status,0);
  assert.equal(fs.existsSync(path.join(root,'present')),true);
  assert.doesNotMatch(fs.readFileSync(path.join(root,'calls'),'utf8'),/plugin remove/);
});
test('failed manager removal reports incomplete cleanup and preserves data',t=>{
  const {root,run}=fixture(t),r=run(['--confirm'],{FAIL_REMOVE:'1'});assert.notEqual(r.status,0);
  assert.match(r.stderr,/failed after disable/);assert.equal(fs.readFileSync(path.join(root,'private-config'),'utf8'),'keep');
});
test('unavailable inventory and conflicting/unknown flags never remove',t=>{
  const {root,run}=fixture(t);
  for(const [args,env] of [[['--confirm'],{FAIL_LIST:'1'}],[['--dry-run','--confirm'],{}],[['--purge'],{}]])assert.notEqual(run(args,env).status,0);
  assert.equal(fs.existsSync(path.join(root,'present')),true);
  assert.doesNotMatch(fs.readFileSync(path.join(root,'calls'),'utf8'),/plugin (remove|disable)/);
});

test('locally edited installed Git checkout is not removed',t=>{
  const {root,run}=fixture(t),installed=path.join(root,'.config/omarchy/plugins/io.miilo.bar');
  fs.mkdirSync(installed,{recursive:true});
  assert.equal(spawnSync('git',['init',installed],{encoding:'utf8'}).status,0);
  fs.writeFileSync(path.join(installed,'user-edit'),'preserve');
  const r=run(['--confirm']);assert.notEqual(r.status,0);assert.match(r.stderr,/local changes/);
  assert.equal(fs.existsSync(path.join(root,'present')),true);
  assert.doesNotMatch(fs.readFileSync(path.join(root,'calls'),'utf8'),/plugin (remove|disable)/);
});
