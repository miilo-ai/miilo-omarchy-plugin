import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import test from 'node:test';
import assert from 'node:assert/strict';
const helper=path.resolve(import.meta.dirname,'../tools/shell-lifecycle.sh');
function run(t,mode,reply){
  const root=fs.mkdtempSync(path.join(os.tmpdir(),'miilo-shell-ready-'));
  t.after(()=>fs.rmSync(root,{recursive:true,force:true}));
  const executable=mode==='discovery'?'omarchy':'omarchy-shell';
  fs.writeFileSync(path.join(root,executable),`#!/bin/bash
echo call >> "$STATE/calls"
case "$REPLY" in
  delayed|delayed-transport)
    if [[ ! -e "$STATE/seen" ]]; then
      touch "$STATE/seen"
      [[ "$REPLY" != delayed-transport ]] || exit 1
      if [[ "$MODE" == discovery ]]; then echo '[]'; else echo unknown; fi
    else
      if [[ "$MODE" == discovery ]]; then echo '[{"id":"io.miilo.bar"}]'; else echo ok; fi
    fi ;;
  failure) exit 1 ;;
  never)
    if [[ "$MODE" == discovery ]]; then echo '[]'; else echo unknown; fi ;;
  *) echo "$REPLY" ;;
esac
`,{mode:0o755});
  const r=spawnSync('bash',['-c',`source "$1"
if [[ "$REPLY" == never || "$REPLY" == failure ]]; then sleep() { SECONDS=$((SECONDS + 2)); }; fi
miilo_wait_"$MODE"`,'test',helper],{
    encoding:'utf8',timeout:15000,env:{...process.env,PATH:root+':'+process.env.PATH,STATE:root,MODE:mode,REPLY:reply}
  });
  return {...r,calls:fs.readFileSync(path.join(root,'calls'),'utf8').trim().split('\n').length};
}
test('discovery and summon wait for semantic readiness',t=>{
  for(const mode of ['discovery','summon']){
    const r=run(t,mode,'delayed');assert.equal(r.status,0,r.stderr);assert.equal(r.calls,2);
  }
  const r=run(t,'summon','delayed-transport');assert.equal(r.status,0,r.stderr);assert.equal(r.calls,2);
});
test('transport failures and invalid responses fail without success',t=>{
  for(const mode of ['discovery','summon'])for(const reply of ['failure','{}']){
    const r=run(t,mode,reply);assert.notEqual(r.status,0);
    if(mode==='summon'&&reply==='failure')assert.match(r.stderr,/Timed out/);
    else assert.equal(r.calls,1);
    assert.doesNotMatch(r.stdout,/accepted summon/);
  }
});
test('permanent unknown response times out despite IPC exit zero',t=>{
  const r=run(t,'summon','never');assert.equal(r.error,undefined);
  assert.notEqual(r.status,0);assert.match(r.stderr,/Timed out/);
  assert.doesNotMatch(r.stdout,/accepted summon/);
});
