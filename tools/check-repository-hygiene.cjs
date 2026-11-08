const fs=require('node:fs');
const path=require('node:path');
const {execFileSync}=require('node:child_process');

function forbidden(name) {
  return /(^|\/)(target|node_modules|__pycache__|\.ipynb_checkpoints|\.runtime|\.validation|\.specify)(\/|$)/.test(name)
    || (/^\.env(?:\.|$)/.test(path.basename(name))&&path.basename(name)!=='.env.example')
    || /\.(bundle|sqlite|sqlite3)$/.test(name);
}
function candidates(root) {
  try {
    const top=execFileSync('git',['rev-parse','--show-toplevel'],{cwd:root,encoding:'utf8',stdio:['ignore','pipe','ignore']}).trim();
    if(fs.realpathSync(top)===fs.realpathSync(root)) {
      return [...new Set(execFileSync('git',['ls-files','--cached','--others','--exclude-standard','-z'],{cwd:root,encoding:'utf8'}).split('\0'))]
        .filter(name=>name&&fs.existsSync(path.join(root,name)));
    }
  } catch {}
  function walk(directory,prefix='') {
    return fs.readdirSync(directory,{withFileTypes:true}).flatMap(entry=>{
      if(entry.name==='.git')return [];
      const name=prefix+entry.name;
      return entry.isDirectory()&&!forbidden(name)?walk(path.join(directory,entry.name),name+'/'):[name];
    });
  }
  return walk(root);
}
function violations(root){return candidates(root).filter(forbidden);}
if(require.main===module) {
  const problems=violations(path.resolve(__dirname,'..'));
  if(problems.length){console.error('Generated or internal files in source candidate:\n'+problems.join('\n'));process.exitCode=1;}
  else console.log('Repository hygiene passed: no generated artifacts, local credential files or internal tracking files in source candidates.');
}
module.exports={violations};
