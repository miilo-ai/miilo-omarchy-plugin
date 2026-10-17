const fs=require('node:fs');
const path=require('node:path');
const crypto=require('node:crypto');
function exists(file) {try{fs.lstatSync(file);return true;}catch(e){if(e.code==='ENOENT')return false;throw e;}}
function noLinks(file) {
  let current=path.resolve(file);
  for(;;) {
    if(exists(current)&&fs.lstatSync(current).isSymbolicLink())throw Error('Symlink in managed path');
    const parent=path.dirname(current);if(parent===current)break;current=parent;
  }
}
function files(root,prefix='') {
  return fs.readdirSync(path.join(root,prefix),{withFileTypes:true}).flatMap(entry=>{
    if(entry.name==='.git'||entry.name==='node_modules'||entry.name==='__pycache__')return [];
    const name=prefix?prefix+'/'+entry.name:entry.name;
    if(entry.isSymbolicLink())throw Error('Symlink in package: '+name);
    return entry.isDirectory()?files(root,name):[name];
  });
}
function safeFile(root,name) {
  if(typeof name!=='string'||!name||path.isAbsolute(name)||name.split('/').includes('..')||name.includes('\\'))throw Error('Unsafe repository path: '+name);
  const file=path.join(root,name);noLinks(file);
  if(!exists(file)||!fs.statSync(file).isFile())throw Error('Missing file: '+name);
  return file;
}
function digest(file){return crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');}
function atomicCopy(source,destination,executable=false) {
  noLinks(destination);fs.mkdirSync(path.dirname(destination),{recursive:true});
  const temp=path.join(path.dirname(destination),'.miilo-copy-'+crypto.randomUUID());
  try {const fd=fs.openSync(temp,'wx',executable?0o755:0o644);
    try{fs.writeFileSync(fd,fs.readFileSync(source));fs.fsyncSync(fd);}finally{fs.closeSync(fd);}
    fs.renameSync(temp,destination);
  }finally{fs.rmSync(temp,{force:true});}
}
module.exports={exists,noLinks,files,safeFile,digest,atomicCopy};
