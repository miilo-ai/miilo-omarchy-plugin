const fs=require('node:fs');
const path=require('node:path');
const os=require('node:os');
const crypto=require('node:crypto');
function configured(source,title='Miilo One') {
  if(!['Miilo One','Miilo Bench'].includes(title))throw Error('Unsupported Miilo window title.');
  const begin='-- '+title+' window appearance BEGIN',end='-- '+title+' window appearance END';
  const block=begin+'\no.transparent_window({ class = "^org[.]quickshell$", title = "^'+title+'$" })\n'+end;
  if(source.includes(begin)) {
    if(!source.includes(block))throw Error('Custom Miilo appearance rule preserved; reconcile it manually.');
    return source;
  }
  return source+'\n'+block+'\n';
}
if(require.main===module) {
  const title=process.argv[2]||'Miilo One';
  const file=path.join(process.env.XDG_CONFIG_HOME||path.join(os.homedir(),'.config'),'hypr/looknfeel.lua');
  if(fs.lstatSync(file).isSymbolicLink())throw Error('Linked appearance config requires manual integration.');
  const source=fs.readFileSync(file,'utf8'),updated=configured(source,title);
  if(updated!==source) {
    const temp=file+'.miilo-'+crypto.randomUUID();
    try {fs.writeFileSync(temp,updated,{flag:'wx',mode:fs.statSync(file).mode&0o777});fs.renameSync(temp,file);}
    finally {fs.rmSync(temp,{force:true});}
  }
  console.log(title+' follows Omarchy window-opacity policy; no opacity values overridden.');
}
module.exports={configured};
