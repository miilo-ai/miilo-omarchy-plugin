const fs=require('node:fs');
const path=require('node:path');
const {files,safeFile,digest}=require('./files.cjs');
function localImport(root,file,item) {
  const imported=path.resolve(path.dirname(file),item),relative=path.relative(root,imported);
  if(relative==='..'||relative.startsWith('../')||path.isAbsolute(relative)||!fs.existsSync(imported))throw Error('Missing or escaped local import: '+item);
}
function check(root) {
  const manifest=JSON.parse(fs.readFileSync(path.join(root,'manifest.json'),'utf8'));
  for(const field of ['schemaVersion','id','name','version','author','license','description','kinds','entryPoints'])if(!manifest[field])throw Error('Missing manifest field: '+field);
  if(manifest.schemaVersion!==1||manifest.id!=='io.miilo.bar')throw Error('Unexpected schema or plugin identity');
  if(!/^\d+\.\d+\.\d+(?:-[A-Za-z0-9.-]+)?$/.test(manifest.version))throw Error('Expected semantic plugin version');
  if(JSON.stringify(manifest.kinds)!=='["bar-widget"]'||JSON.stringify(Object.keys(manifest.entryPoints))!=='["barWidget"]')throw Error('Only supported bar-widget entry may be declared');
  safeFile(root,manifest.entryPoints.barWidget);
  if(Object.hasOwn(manifest.omarchy||{},'clonedFrom'))throw Error('Clone-only identity must not ship');
  const names=files(root),lock=JSON.parse(fs.readFileSync(path.join(root,'sources.lock.json'),'utf8')),pinned=new Set();
  if(!/^[a-f0-9]{40}$/.test(lock.revision))throw Error('Source revision must be immutable');
  for(const record of lock.files) {
    if(pinned.has(record.path))throw Error('Duplicate provenance path: '+record.path);
    pinned.add(record.path);
    if(digest(safeFile(root,record.path))!==record.sha256)throw Error('Unreviewed source drift: '+record.path);
    for(const patch of record.patches||[])safeFile(root,patch);
  }
  for(const required of ['LICENSE','vendor/owl/LICENSE','vendor/owl/UPSTREAM.md','assets/70-miilo-fleet.owl']) {
    safeFile(root,required);if(!pinned.has(required))throw Error('Unpinned required asset: '+required);
  }
  for(const name of names) {
    if(!name.startsWith('vendor/')&&!name.startsWith('ui/'))continue;
    if(name.startsWith('vendor/')&&!pinned.has(name))throw Error('Unpinned runtime asset: '+name);
    if(!/\.(?:qml|js|owl)$/.test(name))continue;
    const file=path.join(root,name),text=fs.readFileSync(file,'utf8');
    if(name.startsWith('ui/')&&text.trimEnd().split('\n').length>200)throw Error('Authored QML exceeds 200 lines: '+name);
    if(/["'](?:quickshell|qs)["']/.test(text))throw Error('Native UI must not launch a second shell: '+name);
    for(const match of text.matchAll(/^import\s+"([^"]+)"|Qt\.resolvedUrl\("([^"]+)"\)/gm))localImport(root,file,match[1]||match[2]);
  }
}
module.exports={check};
