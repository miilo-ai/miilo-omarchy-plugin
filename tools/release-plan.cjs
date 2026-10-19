// Resolve a stable manifest version without creating or moving tags.
const fs=require('node:fs');
const cp=require('node:child_process');
function numbers(value){
 if(!/^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$/.test(value))throw Error('Expected a stable semantic version');
 return value.split('.').map(BigInt);
}
function compare(a,b){for(let i=0;i<3;i++){if(a[i]>b[i])return 1;if(a[i]<b[i])return -1;}return 0;}
function plan(version,tags){
 const current=numbers(version),tag='v'+version;
 const stable=tags.filter(t=>/^v\d+\.\d+\.\d+$/.test(t));
 for(const t of stable)if(compare(numbers(t.slice(1)),current)>0)throw Error('Manifest version is below an existing tag');
 return {tag,new_version:!tags.includes(tag)};
}
if(require.main===module){
 const version=JSON.parse(fs.readFileSync('manifest.json','utf8')).version;
 const tags=cp.execFileSync('git',['tag','--list'],{encoding:'utf8'}).trim().split('\n').filter(Boolean);
 const result=plan(version,tags);
 console.log(result.new_version?`New release: ${result.tag}`:`No release has been made: ${result.tag} is already tagged`);
 if(process.env.GITHUB_OUTPUT)fs.appendFileSync(process.env.GITHUB_OUTPUT,Object.entries(result).map(([k,v])=>`${k}=${v}\n`).join(''));
}
module.exports={plan};
