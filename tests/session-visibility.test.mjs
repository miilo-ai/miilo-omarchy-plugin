// Exercise the shipped native OWL asset, with current work after historical sessions.
import fs from 'node:fs';
import path from 'node:path';
import Module from 'node:module';
import assert from 'node:assert/strict';
const root=path.resolve(import.meta.dirname,'..'),runtime=new Module('owl');
runtime._compile(fs.readFileSync(path.join(root,'vendor/owl/Owl.js'),'utf8').replace(/^\.pragma library/,'//'),'owl');
const Owl=runtime.exports;
const source=path.join(root,'assets/70-miilo-fleet.owl');
const program=Owl.compile(fs.readFileSync(source,'utf8'));
function* walk(n){yield n;for(const child of n.c||n.children||[])yield*walk(child);}
function fixture(){
  const providers=Array.from({length:13},(_,i)=>({id:`p${i}`,name:`Session ${i}`,health:'healthy'}));
  const actors=providers.map((p,i)=>({_key:`a${i}`,id:`a${i}`,name:p.name,providerId:p.id,status:i===8?'working':'resting',health:'healthy',extensions:{'dev.miilo.session':{runtimeStatusAuthoritative:false}}}));
  const workItems=providers.map((p,i)=>({_key:`w${i}`,id:`w${i}`,providerId:p.id,title:`Work ${i}`,lifecycle:i===8?'active':'waiting',phase:'implementing',attention:'none',_actorKeys:[`a${i}`],_revisionKey:'r1',actions:[]}));
  return {configured:true,errors:[],snapshot:{providers,actors,workItems,attention:[]}};
}
function scene(data,saved={},viewport={}){
  const errors=[],palette=Owl.themeFromToml('');
  const instance=new Owl.Instance(program,{
    theme:k=>palette[k]??null,tile:k=>({linux:true,tileWidth:260,tileHeight:180,screenWidth:900,screenHeight:760,...viewport})[k]??null,
    report:e=>errors.push(e),changed(){},act(){},runInto(){throw Error('Visibility must not invoke a provider');}
  },{observatoryView:'orbit',...saved});
  const slot=k=>program.globals.findIndex(g=>g.name===k);
  const feed=value=>instance.setSource(slot('feed'),Owl.fromJson({ok:true,out:JSON.stringify(value),err:'',code:0}));
  const set=(k,v)=>{instance.values[slot(k)]=Owl.fromJson(v);instance.invalidate();};
  const get=k=>Owl.toJson(instance.read(slot(k)));
  const render=()=>{const nodes=[...walk(instance.render(true))];assert.deepEqual(errors,[]);return nodes;};
  feed(data);return {instance,feed,set,get,render};
}
const data=fixture(),s=scene(data);
assert.equal(s.get('allProviders').length,13,'Enrollment inventory must stay intact');
assert.deepEqual(s.get('actors').map(a=>a._key),['a8'],'Observed working session must be visible despite original ninth position');
assert.deepEqual(s.get('selectableProviders').map(p=>p.id),['p8']);
assert.equal(s.get('allActors').filter(a=>a.status==='resting').length,12,'Never fake activity');
assert.equal(s.get('provs').length,1);
assert.equal(s.render().filter(n=>n.kind==='Canvas'&&n.p.height===82).length,1,'Only visible session gets an Orbit field');
assert.equal(s.get('systemsOpen'),false,'Menu starts collapsed');
// The native header owns navigation; its state drives the same selector projection.
s.set('systemsOpen',true);
assert.equal(s.get('systemsOpen'),true);
let nodes=s.render();
assert(nodes.some(n=>n.kind==='Button'&&n.p.text==='Session 8'));
assert(!nodes.some(n=>n.kind==='Button'&&n.p.text==='Session 0'),'Inactive sessions stay out of selector');
assert(!nodes.some(n=>String(n.p?.text||'').includes('inactive sessions')),'No inactive toggle');
const sleeping=fixture();sleeping.snapshot.actors[0].extensions['dev.miilo.session'].recentlyActive=true;
const recent=scene(sleeping,{showInactiveSessions:true});
assert.deepEqual(recent.get('provs').map(p=>p.id),['p8','p0']);
assert.equal(recent.get('actors')[1].status,'resting','Recent idle sessions keep sleeping animation');
assert.equal(recent.instance.persisted().showInactiveSessions,undefined,'Legacy reveal preference is ignored');
recent.set('systemsOpen',true);
assert(!recent.render().some(n=>n.kind==='Button'&&n.p.text==='All'),'No redundant all-systems control');
recent.set('system','p0');
recent.render().find(n=>n.kind==='Button'&&n.p.text==='All').h.onTap(0,0);
assert.equal(recent.get('system'),'','Compact clear-filter action works');
sleeping.snapshot.actors[0].extensions['dev.miilo.session'].recentlyActive=false;
recent.feed(sleeping);assert.deepEqual(recent.get('provs').map(p=>p.id),['p8'],'Session expires on next snapshot');
s.set('selectedWork','w8');
const ended=fixture();ended.snapshot.actors[8].status='resting';ended.snapshot.workItems[8].lifecycle='waiting';
s.feed(ended);
assert.equal(s.get('provs').length,0);
assert.equal(s.get('focused')._key,'w8','Do not discard an open work detail when activity ends');
s.set('selectedWork','');
assert(s.render().some(n=>n.p?.text==='No systems to display'));
const resumed=fixture();resumed.snapshot.actors[2].status='reviewing';s.feed(resumed);
assert.deepEqual(s.get('provs').map(p=>p.id),['p2','p8'],'Fresh activity rejoins automatically');
const needsYou=fixture();needsYou.snapshot.workItems[0].attention='approval';
assert.deepEqual(scene(needsYou).get('provs').map(p=>p.id),['p0','p8'],'Pending decisions must not disappear');
const offline=fixture();offline.snapshot.actors[8].health='unreachable';
assert.equal(scene(offline).get('provs').length,0,'Unavailable session must not be inferred active');
const remote=fixture();remote.snapshot.actors[0].extensions={};
assert.deepEqual(scene(remote).get('provs').map(p=>p.id),['p8','p0'],'Idle persistent remote factories stay accessible');
const quiet=scene(data,{observatoryView:'quiet'});assert.equal(quiet.get('actors').length,1);quiet.render();
console.log('Session visibility passed: active-first, 12-hour sleeping visibility, lifecycle updates, decisions, remote factories and no provider commands.');

// The shipped Orbit tile opens system work without changing the saved view.
const orbitTile=scene(fixture(),{observatoryView:'orbit'});
const cluster=orbitTile.render().find(n=>n.kind==='Column'&&n.h?.onTap&&n.c?.some(c=>c.kind==='Row'&&c.c?.some(t=>t.p?.text==='Session 8')));
assert(cluster,'Shipped Orbit cluster must be clickable');
cluster.h.onTap(0,0);
assert.equal(orbitTile.get('observatoryView'),'orbit');
assert.equal(orbitTile.get('expandedSystem'),'p8');
assert(orbitTile.render().some(n=>n.p?.text==='Work 8'));
orbitTile.set('observatoryView','quiet');
orbitTile.render().find(n=>n.p?.text==='Back').h.onTap(0,0);
assert.equal(orbitTile.get('observatoryView'),'orbit','Back restores the entry mode explicitly');
assert.equal(orbitTile.get('expandedSystem'),'');
assert.equal(orbitTile.render().filter(n=>n.kind==='Canvas'&&n.p.height===82).length,1);

// Narrow desktop windows wrap filters and display modes into separate rows.
for (const width of [240, 260, 900]) {
  const layout = scene(fixture(), {}, {screenWidth:width}).render();
  const combined = layout.filter(n => n.kind === 'Row' && [...walk(n)].some(c => c.p?.text === 'All work') && [...walk(n)].some(c => c.p?.text === 'Compact'));
  assert.equal(combined.length > 0, width >= 340, 'Toolbar grouping must follow the actual viewport');
}

// Settings replace work content, then return to the same inspected task.
const settingsScene = scene(fixture(), {observatoryView:'orbit'});
settingsScene.set('selectedWork','w8');
settingsScene.set('setupSection','appearance'); settingsScene.set('setupOpen',true);
let settingsNodes = settingsScene.render();
assert(settingsNodes.some(n => n.p?.text === 'Appearance'));
assert(!settingsNodes.some(n => n.p?.text === 'Work 8'), 'Work details must not compete with settings');
settingsNodes.find(n => n.kind === 'Button' && n.p.text === 'Done').h.onTap(0,0);
assert.equal(settingsScene.get('setupOpen'),false);
assert.equal(settingsScene.get('selectedWork'),'w8', 'Settings must preserve the inspected work');
assert(settingsScene.render().some(n => n.p?.text === 'Work 8'));

// Fleet geometry follows viewport width while preserving the Compact/Detail column caps.
const fleetFixture = fixture(); fleetFixture.snapshot.actors.forEach(a => a.status = 'working');
for (const width of [240, 360, 600, 960]) {
  const compact = scene(fleetFixture,{observatoryView:'quiet'},{screenWidth:width}).render().find(n => n.kind === 'Grid');
  assert(compact); assert.equal(compact.p.columns,Math.max(1,Math.min(4,Math.floor((width-18)/88))));
  const detail = scene(fleetFixture,{observatoryView:'orbit'},{screenWidth:width}).render().find(n => n.kind === 'Row' && n.c?.some(c=>c.kind==='Column'&&c.p.weight===1));
  assert(detail); assert.equal(detail.c.length,Math.max(1,Math.min(4,Math.floor((width-14)/190))));
}

// Detail limits hide rows, never observations; View more opens the full system.
const factory = fixture();
factory.snapshot.providers = [{id:'factory',name:'Example Factory',health:'healthy'}];
factory.snapshot.actors = [{_key:'builder',id:'builder',providerId:'factory',name:'Builder',status:'working',health:'healthy'}];
factory.snapshot.workItems = Array.from({length:12},(_,i)=>({_key:`task${i}`,id:`task${i}`,providerId:'factory',title:`Factory task ${i}`,lifecycle:'active',phase:'implementing',attention:'none',_actorKeys:['builder'],_revisionKey:'r1',actions:[]}));
for (const [saved, count] of [[{},5],[{detailTaskLimit:3},3],[{detailTaskLimit:8},8],[{detailTaskLimit:10},10],[{detailTaskLimit:999},5]]) {
  const detail = scene(factory,saved), nodes = detail.render();
  assert.equal(nodes.filter(n=>n.kind==='Text'&&String(n.p.text).startsWith('Factory task ')).length,count);
  assert.equal(detail.get('allWorks').length,12,'Hidden rows must preserve the complete observation');
  const more = nodes.find(n=>n.kind==='Button'&&n.p.text==='View more');
  assert(more,'Overflow uses a concise standard button');
  more.h.onTap(0,0);
  assert.equal(detail.get('expandedSystem'),'factory');
  assert.equal(detail.get('pageSize'),12);
  assert(detail.render().some(n=>n.p?.text==='Factory task 9'),'Expanded system includes tasks beyond the card limit');
}
const preference = scene(factory);
assert.equal(preference.get('detailTaskLimit'),5);
preference.set('detailTaskLimit',8);
const restored = scene(factory,preference.instance.persisted());
assert.equal(restored.get('detailTaskLimit'),8,'Detail preference survives a new surface instance');

// Action alignment follows the persisted controls preference, in both directions.
for (const leftHanded of [false,true]) {
  const actions = scene(factory,{leftHanded}), nodes = actions.render();
  const row = nodes.find(n=>n.kind==='Row'&&n.c?.some(c=>c.kind==='Button'&&c.p.text==='View more'));
  assert(row);
  assert.equal(row.c[leftHanded?row.c.length-1:0].kind,'Spacer');
  const button = row.c.find(c=>c.kind==='Button');
  assert(button.p.scale < 1);
  assert.equal(actions.instance.persisted().leftHanded,leftHanded);
}
for (const count of [0,9,100]) {
  const inventory = structuredClone(factory);
  inventory.snapshot.workItems = Array.from({length:Math.max(1,count)},(_,i)=>({...factory.snapshot.workItems[0],_key:'decision'+i,id:'decision'+i,attention:i<count?'approval':'none'}));
  const filters = scene(inventory).render().find(n=>n.kind==='Box'&&n.c?.some(c=>c.p?.text===`Needs you (${count})`));
  assert(filters,'Filter retains its complete label and counter');
  assert(filters.p.width >= 104,'Filter reserves label and counter space');
}

const modeSwitch = scene(factory,{observatoryView:'quiet',expandedSystem:'factory',workflowActor:'builder',inspectionView:'quiet'});
modeSwitch.render().find(n=>n.kind==='Box'&&n.c?.some(c=>c.p?.text==='Detail')).h.onTap(0,0);
assert.equal(modeSwitch.get('expandedSystem'),'');
assert.equal(modeSwitch.get('workflowActor'),'');
assert.equal(modeSwitch.get('inspectionView'),'');
assert(modeSwitch.render().some(n=>n.kind==='Canvas'&&n.p.height===82),'First Detail activation must restore the overview');

// Both fleets remain centered even when the one-card group is narrower than the viewport.
for (const mode of ['quiet','orbit']) for (const width of [360,760,1200]) {
  const nodes = scene(factory,{observatoryView:mode},{screenWidth:width}).render();
  const centered = nodes.find(n=>n.kind==='Box'&&n.p.fill==='width'&&n.p.align==='top'&&n.c?.some(c=>c.kind==='Grid'||c.kind==='Row'&&c.c?.some(l=>l.kind==='Column'&&l.p.weight===1)));
  assert(centered,'Fleet must have a centered viewport container');
  assert(centered.c.find(c=>c.kind==='Grid'||c.kind==='Row').p.width<=width);
}
