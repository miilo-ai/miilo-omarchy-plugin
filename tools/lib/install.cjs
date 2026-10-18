// Backed-up native UI installation; no enrollment, services or shell lifecycle.
const fs=require('node:fs');
const path=require('node:path');
const {execFileSync}=require('node:child_process');
const {exists,noLinks,files,safeFile,digest,atomicCopy}=require('./files.cjs');
function manifestVersion(file,section) {
  const source=fs.readFileSync(file,'utf8'),start=source.indexOf('['+section+']');
  if(start<0)throw Error('Missing manifest section: '+section);
  const match=source.slice(start).split(/\n\s*\[/)[0].match(/^version\s*=\s*"([^"\n]+)"\s*$/m);
  if(!match)throw Error('Missing literal package version');return match[1];
}
function version(binary,expected) {
  const actual=execFileSync(binary,['--version'],{encoding:'utf8',timeout:10000,stdio:['ignore','pipe','pipe']}).trim();
  if(actual!==expected)throw Error(path.basename(binary)+' must report '+expected+'; rebuild with --rebuild first');
}
function install(root,args) {
  const parent=path.dirname(root),owlVersion=manifestVersion(path.join(parent,'miilo-owl-widgets/helper/Cargo.toml'),'package');
  const cliVersion=manifestVersion(path.join(parent,'miilo-cli/Cargo.toml'),'workspace.package');
  version(args.helper,'miilo-owl '+owlVersion);version(args.local,'miilo-local '+cliVersion);
  if(args.cli)version(args.cli,'miilo '+cliVersion);
  const target=path.resolve(args.pluginDir);noLinks(target);noLinks(args.stateDir);
  if(exists(path.join(target,'.git')))throw Error('Installed plugin is a Git checkout; reconcile before replacing');
  if(exists(target)&&JSON.parse(fs.readFileSync(path.join(target,'manifest.json'),'utf8')).id!=='io.miilo.bar')throw Error('Refusing to replace unrelated plugin');
  const managed=['ui','vendor','assets'].flatMap(folder=>files(path.join(root,folder)).map(name=>folder+'/'+name));
  managed.push('LICENSE','sources.lock.json','uninstall.sh','manifest.json');
  for(const relative of managed){safeFile(root,relative);noLinks(path.join(target,relative));}
  const binaries=[['miilo-owl',args.helper],['miilo-local',args.local]];
  if(args.cli)binaries.push(['miilo',args.cli]);
  if(args.installBinaries)for(const [name]of binaries)noLinks(path.join(args.binDir,name));
  fs.mkdirSync(args.stateDir,{recursive:true});
  const backup=fs.mkdtempSync(path.join(args.stateDir,'native-'));fs.chmodSync(backup,0o700);
  console.log('Backup: '+backup);
  if(exists(target))fs.cpSync(target,path.join(backup,'io.miilo.bar'),{recursive:true,dereference:false});
  if(args.installBinaries)for(const [name]of binaries)if(exists(path.join(args.binDir,name)))fs.copyFileSync(path.join(args.binDir,name),path.join(backup,name));
  fs.mkdirSync(target,{recursive:true});
  // The entry manifest is last so its UI exists before switching the entry point.
  for(const relative of managed)atomicCopy(path.join(root,relative),path.join(target,relative));
  if(args.installBinaries)for(const [name,source]of binaries)atomicCopy(source,path.join(args.binDir,name),true);
  for(const relative of managed)if(digest(path.join(target,relative))!==digest(path.join(root,relative)))throw Error('Installed file mismatch: '+relative);
  if(args.installBinaries)for(const [name,source]of binaries)if(digest(path.join(args.binDir,name))!==digest(source))throw Error('Installed binary mismatch: '+name);
  const git=args.gitMetadata||((...gitArgs)=>execFileSync('git',['-C',root,...gitArgs],{encoding:'utf8',timeout:10000}).trim());
  const evidence={plugin:'io.miilo.bar',sourceCommit:git('rev-parse','HEAD'),sourceDirty:Boolean(git('status','--porcelain')),files:Object.fromEntries(managed.map(name=>[name,digest(path.join(root,name))])),binaries:Object.fromEntries(binaries.map(([name,source])=>[name,digest(source)]))};
  fs.writeFileSync(path.join(backup,'installed.json'),JSON.stringify(evidence,null,2)+'\n',{mode:0o600});
  console.log('Installed canonical native io.miilo.bar; legacy UI and observation data preserved.');
  return backup;
}
module.exports={install,manifestVersion};
