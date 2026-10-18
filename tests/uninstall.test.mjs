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
  if [ -f "$STATE/disabled" ] && [ ! -f "$STATE/present" ]; then
    [ "\${FAIL_AFTER:-0}" = 0 ] || exit 3
    if [ "\${INVALID_AFTER:-0}" = 1 ]; then echo '{}'; exit; fi
    if [ "\${STALE_AFTER:-0}" = forever ] || { [ "\${STALE_AFTER:-0}" = 1 ] && [ ! -f "$STATE/stale-read" ]; }; then
      touch "$STATE/stale-read"; echo '[{"id":"io.miilo.bar"}]'; exit
    fi
  fi
  if [ -f "$STATE/present" ]; then printf '[{"id":"io.miilo.bar"},{"id":"other.widget"}]'; else printf '[{"id":"other.widget"}]'; fi ;;
disable) [ "\${FAIL_DISABLE:-0}" = 0 ] || exit 4; touch "$STATE/disabled" ;;
remove)
  [ -f "$STATE/disabled" ] || exit 9
  [ "\${FAIL_REMOVE:-0}" = 0 ] || exit 5
  rm "$STATE/present"
  if [ "\${REMOVE_INSTALL:-0}" = 1 ]; then mv "$STATE/.config/omarchy/plugins/io.miilo.bar" "$STATE/removed-install"; fi ;;
*) exit 8 ;;
esac
`,{mode:0o755});
  return {root,run:(args=[],extra={})=>spawnSync('bash',[script,...args],{encoding:'utf8',env:{...process.env,HOME:root,MIILO_OMARCHY_EXECUTABLE:manager,STATE:root,XDG_STATE_HOME:path.join(root,"state"),...extra}})};
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

test('waits for asynchronous removal inventory without repeating disable/remove',t=>{
  const {root,run}=fixture(t),r=run(['--confirm'],{STALE_AFTER:'1'});
  assert.equal(r.status,0,r.stderr);assert.match(r.stdout,/integration removed/);
  const calls=fs.readFileSync(path.join(root,'calls'),'utf8');
  assert.equal(calls.match(/plugin remove/g).length,1);
  assert.equal(calls.match(/plugin list/g).length,3);
});
test('post-removal unavailable or malformed inventory never reports success',t=>{
  for(const env of [{FAIL_AFTER:'1'},{INVALID_AFTER:'1'}]){
    const {run}=fixture(t),r=run(['--confirm'],env);
    assert.notEqual(r.status,0);assert.doesNotMatch(r.stdout,/integration removed/);
  }
});
test('permanently stale inventory times out instead of claiming removal',t=>{
  const {run}=fixture(t),r=run(['--confirm'],{STALE_AFTER:'forever'});
  assert.notEqual(r.status,0);assert.match(r.stderr,/Timed out/);
  assert.doesNotMatch(r.stdout,/integration removed/);
});
test('absent inventory cannot hide an install path left by the manager',t=>{
  const {root,run}=fixture(t);
  fs.mkdirSync(path.join(root,'.config/omarchy/plugins/io.miilo.bar'),{recursive:true});
  const r=run(['--confirm']);assert.notEqual(r.status,0);
  assert.match(r.stderr,/install path remains/);
});

function gitInstall(root){
  const installed=path.join(root,'.config/omarchy/plugins/io.miilo.bar');
  fs.mkdirSync(installed,{recursive:true});
  const git=(...args)=>{
    const r=spawnSync('git',['-C',installed,...args],{encoding:'utf8'});
    assert.equal(r.status,0,r.stderr);return r.stdout.trim();
  };
  git('init');git('config','user.name','Synthetic test');git('config','user.email','test@example.invalid');
  fs.writeFileSync(path.join(installed,'.gitignore'),'private-notes\n');
  git('add','.');git('commit','-m','Synthetic baseline');
  git('update-ref','refs/remotes/origin/main',git('rev-parse','HEAD'));
  return {installed,git};
}
test('absent inventory with leftover installation or dangling link fails before mutation',t=>{
  for(const link of [false,true]){
    const {root,run}=fixture(t),installed=path.join(root,'.config/omarchy/plugins/io.miilo.bar');
    fs.rmSync(path.join(root,'present'));fs.mkdirSync(path.dirname(installed),{recursive:true});
    if(link)fs.symlinkSync(path.join(root,'missing'),installed);else fs.mkdirSync(installed);
    const r=run(['--confirm']);assert.notEqual(r.status,0);assert.match(r.stderr,/install path remains/);
    assert.doesNotMatch(fs.readFileSync(path.join(root,'calls'),'utf8'),/plugin (remove|disable)/);
  }
});
test('Git removal privately archives ignored files and unpublished commits',t=>{
  const {root,run}=fixture(t),{installed,git}=gitInstall(root);
  fs.writeFileSync(path.join(installed,'unpublished'),'synthetic unpublished work');
  git('add','.');git('commit','-m','Synthetic unpublished commit');
  const head=git('rev-parse','HEAD');
  fs.writeFileSync(path.join(installed,'private-notes'),'synthetic ignored notes');
  assert.equal(git('status','--porcelain'),'');
  const r=run(['--confirm'],{REMOVE_INSTALL:'1'});assert.equal(r.status,0,r.stderr);
  const backups=path.join(root,'state/miilo/plugin-backups');
  const directory=path.join(backups,fs.readdirSync(backups)[0]),archive=path.join(directory,'checkout.tar');
  assert.equal(fs.statSync(directory).mode & 0o777,0o700);
  assert.equal(fs.statSync(archive).mode & 0o777,0o600);
  const restored=path.join(root,'restored');fs.mkdirSync(restored);
  assert.equal(spawnSync('tar',['-xpf',archive,'-C',restored]).status,0);
  assert.equal(fs.readFileSync(path.join(restored,'private-notes'),'utf8'),'synthetic ignored notes');
  assert.equal(fs.readFileSync(path.join(restored,'unpublished'),'utf8'),'synthetic unpublished work');
  assert.equal(spawnSync('git',['-C',restored,'rev-parse','HEAD'],{encoding:'utf8'}).stdout.trim(),head);
  assert.equal(fs.existsSync(installed),false);
});
test('backup failure and linked Git metadata stop before disable or remove',t=>{
  for(const linked of [false,true]){
    const {root,run}=fixture(t),{installed}=gitInstall(root);
    if(linked){fs.renameSync(path.join(installed,'.git'),path.join(root,'git-data'));fs.writeFileSync(path.join(installed,'.git'),'gitdir: '+path.join(root,'git-data')+'\n');}
    const r=run(['--confirm'],linked?{}:{XDG_STATE_HOME:'/dev/null/not-a-directory'});
    assert.notEqual(r.status,0);
    assert.doesNotMatch(fs.readFileSync(path.join(root,'calls'),'utf8'),/plugin (remove|disable)/);
    assert.equal(fs.existsSync(installed),true);
  }
});

test('archive write failure never reaches disable or removal',t=>{
  const {root,run}=fixture(t);gitInstall(root);
  fs.writeFileSync(path.join(root,'tar'),'#!/bin/sh\nexit 1\n',{mode:0o755});
  const r=run(['--confirm'],{PATH:root+':'+process.env.PATH});
  assert.notEqual(r.status,0);assert.match(r.stderr,/Checkout backup failed/);
  assert.doesNotMatch(fs.readFileSync(path.join(root,'calls'),'utf8'),/plugin (remove|disable)/);
});
test('symlinked state cannot place the archive inside the checkout',t=>{
  const {root,run}=fixture(t),{installed,git}=gitInstall(root);
  fs.appendFileSync(path.join(installed,'.gitignore'),'backup-state/\n');
  git('add','.');git('commit','-m','Ignore synthetic state');
  fs.mkdirSync(path.join(installed,'backup-state'));
  fs.symlinkSync(path.join(installed,'backup-state'),path.join(root,'state-link'));
  const r=run(['--confirm'],{XDG_STATE_HOME:path.join(root,'state-link')});
  assert.notEqual(r.status,0);assert.match(r.stderr,/Backup resolves inside/);
  assert.doesNotMatch(fs.readFileSync(path.join(root,'calls'),'utf8'),/plugin (remove|disable)/);
});
