import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import test from 'node:test';
import assert from 'node:assert/strict';
import installer from '../tools/lib/install.cjs';
const source=path.resolve(import.meta.dirname,'..');
function fixture(t){const base=fs.realpathSync(fs.mkdtempSync(path.join(os.tmpdir(),'miilo-install-')));t.after(()=>fs.rmSync(base,{recursive:true,force:true}));
  const root=path.join(base,'miilo-omarchy-plugin');fs.mkdirSync(root);
  for(const name of ['manifest.json','sources.lock.json','LICENSE','uninstall.sh','ui','vendor','assets'])fs.cpSync(path.join(source,name),path.join(root,name),{recursive:true});
  for(const [name,section,version]of [['miilo-owl-widgets/helper','package','1.4.0'],['miilo-cli','workspace.package','0.2.0']]){const folder=path.join(base,name);fs.mkdirSync(folder,{recursive:true});fs.writeFileSync(path.join(folder,'Cargo.toml'),'['+section+']\nversion = "'+version+'"\n');}
  const args={pluginDir:path.join(base,'plugins/io.miilo.bar'),binDir:path.join(base,'bin'),stateDir:path.join(base,'state'),installBinaries:true,gitMetadata:()=>''};
  const binary=(name,version)=>{const file=path.join(base,name);fs.writeFileSync(file,'#!/bin/sh\n[ "$1" = "--version" ] || exit 99\nprintf "%s\\n" "'+name+' '+version+'"\n',{mode:0o755});return file;};
  args.helper=binary('miilo-owl','1.4.0');args.local=binary('miilo-local','0.2.0');args.cli=binary('miilo','0.2.0');
  fs.mkdirSync(args.pluginDir,{recursive:true});fs.writeFileSync(path.join(args.pluginDir,'manifest.json'),'{"id":"io.miilo.bar"}');fs.writeFileSync(path.join(args.pluginDir,'LocalImport.qml'),'legacy UI retained');fs.writeFileSync(path.join(base,'connections.json'),'untouched');
  return {base,root,args,binary};
}
test('real install preserves data, backs up old UI and verifies bytes',t=>{const {base,root,args}=fixture(t),backup=installer.install(root,args);
  assert.equal(JSON.parse(fs.readFileSync(path.join(args.pluginDir,'manifest.json'))).entryPoints.barWidget,'ui/shell/BarWidget.qml');
  assert.deepEqual(fs.readFileSync(path.join(args.pluginDir,'assets/70-miilo-fleet.owl')),fs.readFileSync(path.join(root,'assets/70-miilo-fleet.owl')));
  assert.equal(fs.readFileSync(path.join(base,'connections.json'),'utf8'),'untouched');assert.match(fs.readFileSync(path.join(backup,'io.miilo.bar/LocalImport.qml'),'utf8'),/legacy UI/);
  assert.ok(Object.keys(JSON.parse(fs.readFileSync(path.join(backup,'installed.json'))).files).length>0);
  for(const name of ['miilo','miilo-local','miilo-owl'])assert.deepEqual(fs.readFileSync(path.join(args.binDir,name)),fs.readFileSync(path.join(base,name)));
});
test('stale binary stops before writes',t=>{const {root,args,binary}=fixture(t);args.helper=binary('miilo-owl','1.3.0');assert.throws(()=>installer.install(root,args),/rebuild/);assert.equal(fs.existsSync(args.stateDir),false);});
test('Git checkout is never overwritten',t=>{const {root,args}=fixture(t);fs.mkdirSync(path.join(args.pluginDir,'.git'));assert.throws(()=>installer.install(root,args),/Git checkout/);assert.equal(fs.existsSync(args.stateDir),false);});
test('managed symlink is never followed',t=>{const {base,root,args}=fixture(t),outside=path.join(base,'unrelated');fs.mkdirSync(outside);fs.symlinkSync(outside,path.join(args.pluginDir,'assets'));assert.throws(()=>installer.install(root,args),/Symlink/);assert.deepEqual(fs.readdirSync(outside),[]);});
test('binary destination symlink stops before backup or writes',t=>{const {base,root,args}=fixture(t);fs.mkdirSync(args.binDir);fs.symlinkSync(path.join(base,'connections.json'),path.join(args.binDir,'miilo'));assert.throws(()=>installer.install(root,args),/Symlink/);assert.equal(fs.existsSync(args.stateDir),false);});
