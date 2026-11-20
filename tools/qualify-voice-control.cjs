const fs=require('node:fs');
const os=require('node:os');
const path=require('node:path');
const {spawn}=require('node:child_process');
const {createInterface}=require('node:readline');
const assert=require('node:assert/strict');
const directory=fs.mkdtempSync(path.join(os.tmpdir(),'miilo-voice-control-'));
fs.chmodSync(directory,0o700);
const binary=process.argv[2],peer=process.argv[3];
if(!binary||!peer)throw Error('Supply the built voice helper and capture-peer paths.');
const pidFile=path.join(directory,'capture.pid');
fs.writeFileSync(path.join(directory,'pw-record'),'#!/bin/sh\nexec "$MIILO_CAPTURE_PEER"\n',{mode:0o700});
function alive(pid){try{process.kill(pid,0);return true;}catch{return false;}}
function delay(ms){return new Promise(resolve=>setTimeout(resolve,ms));}
async function until(predicate){for(let i=0;i<100;i++){if(predicate())return;await delay(50);}throw Error('Voice-control qualification timed out.');}
function start(){
  fs.rmSync(pidFile,{force:true});
  const child=spawn(binary,['run'],{env:{...process.env,PATH:directory+path.delimiter+process.env.PATH,MIILO_CAPTURE_PEER:peer,MIILO_CAPTURE_PEER_PID_FILE:pidFile},stdio:['pipe','pipe','pipe']});
  child.stdin.on('error',()=>{});
  const events=[];let closed=false;
  createInterface({input:child.stdout}).on('line',line=>events.push(JSON.parse(line)));
  child.on('close',()=>{closed=true;});
  child.stderr.resume();
  return {child,events,closed:()=>closed,send:value=>child.stdin.write(JSON.stringify(value)+'\n')};
}
(async()=>{
  let processState;
  try{
    processState=start();
    await until(()=>processState.events.some(e=>e.type==='ready'));
    assert.equal(fs.existsSync(pidFile),false,'startup must not capture');
    const heartbeat=setInterval(()=>processState.send({type:'heartbeat',paused:false}),200);
    processState.send({type:'heartbeat',paused:false});
    await until(()=>fs.existsSync(pidFile));
    const first=Number(fs.readFileSync(pidFile,'utf8'));
    assert(alive(first),'synthetic capture starts after explicit arm');
    processState.send({type:'mute'});
    await until(()=>processState.events.some(e=>e.phase==='muted'));
    await until(()=>!alive(first));
    await delay(500);
    assert.equal(fs.readFileSync(pidFile,'utf8'),String(first),'heartbeat must not reopen muted capture');
    processState.send({type:'unmute'});
    await until(()=>fs.readFileSync(pidFile,'utf8')!==String(first));
    const second=Number(fs.readFileSync(pidFile,'utf8'));
    clearInterval(heartbeat);
    processState.child.kill('SIGKILL');
    await until(()=>processState.closed());
    await until(()=>!alive(second));
    processState=start();
    await until(()=>processState.events.some(e=>e.type==='ready'));
    await until(()=>processState.closed());
    assert.equal(fs.existsSync(pidFile),false,'missing heartbeat must never capture');
    assert(processState.events.some(e=>e.type==='error'&&e.message.includes('heartbeat')));
    console.log('VOICE_CONTROL_OK: mute closes capture, stays muted, explicit unmute works, parent death kills capture, missing heartbeat fails closed. No microphone used.');
  }finally{
    if(processState&&!processState.closed())processState.child.kill('SIGKILL');
    fs.rmSync(directory,{recursive:true,force:true});
  }
})().catch(error=>{console.error(error);process.exitCode=1;});
