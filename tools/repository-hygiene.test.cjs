const fs=require('node:fs');
const os=require('node:os');
const path=require('node:path');
const test=require('node:test');
const assert=require('node:assert/strict');
const {execFileSync}=require('node:child_process');
const {violations}=require('./check-repository-hygiene.cjs');
function repository(t) {
  const root=fs.mkdtempSync(path.join(os.tmpdir(),'miilo-source-'));
  t.after(()=>fs.rmSync(root,{recursive:true,force:true}));
  execFileSync('git',['init','--quiet'],{cwd:root});
  return root;
}
function write(root,name,text='synthetic') {fs.mkdirSync(path.dirname(path.join(root,name)),{recursive:true});fs.writeFileSync(path.join(root,name),text);}
test('ignored build outputs stay local, but force-tracked build and internal files fail',t=>{
  const root=repository(t);
  write(root,'.gitignore','target/\n.specify/\n.env\n');
  write(root,'tools/monitor/target/build.d');write(root,'.specify/evidence/test.md');write(root,'.env');write(root,'.env.example','KEY=');
  write(root,'ui/Widget.qml','import QtQuick\nItem {}');
  assert.deepEqual(violations(root),[]);
  execFileSync('git',['add','--force','tools/monitor/target/build.d','.specify/evidence/test.md','.env'],{cwd:root});
  assert.deepEqual(violations(root).sort(),['.env','.specify/evidence/test.md','tools/monitor/target/build.d']);
});
test('git archive omits internal tracking even if it exists in a historical tree',t=>{
  const root=repository(t);
  write(root,'.gitattributes',fs.readFileSync(path.join(__dirname,'../.gitattributes'),'utf8'));
  write(root,'.specify/evidence/test.md');write(root,'.runtime/capture.txt');write(root,'AGENTS.md');write(root,'README.md');
  execFileSync('git',['add','--all'],{cwd:root});
  execFileSync('git',['-c','user.name=Fixture','-c','user.email=fixture@example.invalid','-c','commit.gpgsign=false','commit','--quiet','-m','fixture'],{cwd:root});
  const archive=execFileSync('git',['archive','--format=tar','HEAD'],{cwd:root});
  const names=execFileSync('tar',['-tf','-'],{input:archive,encoding:'utf8'});
  assert.match(names,/README.md/);assert.doesNotMatch(names,/\.specify|\.runtime|AGENTS.md/);
});
