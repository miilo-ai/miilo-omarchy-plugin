import fs from 'node:fs';
import Module from 'node:module';
import test from 'node:test';
import assert from 'node:assert/strict';

const runtime=new Module('owl');
runtime._compile(fs.readFileSync(new URL('../vendor/owl/Owl.js',import.meta.url),'utf8').replace(/^\.pragma library/,''),'owl');
const Owl=runtime.exports;
const program=Owl.compile(fs.readFileSync(new URL('../assets/70-miilo-fleet.owl',import.meta.url),'utf8'));
function* walk(n){yield n;for(const c of n.c||n.children||[])yield*walk(c);}
function crossedEyes(health,withActor=false){
  const errors=[],commands=[],palette=Owl.themeFromToml('');
  const instance=new Owl.Instance(program,{
    theme:k=>palette[k]??null,
    tile:k=>({linux:true,tileWidth:260,tileHeight:180,screenWidth:900,screenHeight:760})[k]??null,
    report:e=>errors.push(e),changed(){},act(){},runInto:c=>commands.push(c)
  },{observatoryView:'orbit',robotMotion:'off'});
  const data={configured:true,errors:[],snapshot:{providers:[{id:'system',name:'Sample system',health}],
    actors:withActor?[{_key:'actor',id:'actor',providerId:'system',status:'working',health:'unknown'}]:[],
    workItems:[],attention:[]}};
  const slot=program.globals.findIndex(g=>g.name==='feed');
  instance.setSource(slot,Owl.fromJson({ok:true,out:JSON.stringify(data),code:0,err:''}));
  instance.frame(1);
  const canvas=[...walk(instance.render(true))].find(n=>n.kind==='Canvas'&&n.p.height>25&&n.p.width===n.p.height&&!n.p.fill);
  assert(canvas);assert.deepEqual(errors,[]);assert.deepEqual(commands,[]);
  return canvas.draw(canvas.p.width,canvas.p.height).filter(op=>op.op==='line'&&Math.abs(op.args[0]-op.args[2])>0.01&&Math.abs(op.args[1]-op.args[3])>0.01).length;
}
test('healthy providers without actors retain reported health',()=>assert.equal(crossedEyes('healthy'),0));
test('unknown, stale and unavailable providers stay unavailable',()=>{
  for(const health of [undefined,'unknown','stale','unreachable'])assert.equal(crossedEyes(health),4);
});
test('healthy providers do not hide unavailable actors',()=>assert.equal(crossedEyes('healthy',true),4));
