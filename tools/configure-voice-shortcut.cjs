const fs=require('node:fs');
const path=require('node:path');
const os=require('node:os');
const {execFileSync}=require('node:child_process');
const directory=path.join(process.env.XDG_CONFIG_HOME||path.join(os.homedir(),'.config'),'hypr');
const file=path.join(directory,'bindings.lua');
const marker='-- Miilo voice mute BEGIN';
const end='-- Miilo voice mute END';
const block=marker+'\no.bind("SUPER + CTRL + M", "Mute Miilo microphone", "omarchy-shell miiloVoice mute", { locked = true })\n'+end;
const source=fs.readFileSync(file,'utf8');
if(source.includes(marker)) {
  if(!source.includes(block))throw Error('Existing custom Miilo shortcut preserved; reconcile it manually.');
  console.log('Miilo mute shortcut already configured.');
} else {
  const binds=JSON.parse(execFileSync('hyprctl',['binds','-j'],{encoding:'utf8',timeout:5000}));
  if(binds.some(item=>item.modmask===68&&String(item.key).toUpperCase()==='M'))throw Error('Super+Ctrl+M is already assigned. Choose a different shortcut in Omarchy keybindings.');
  const temp=file+'.miilo-next';
  fs.writeFileSync(temp,source+'\n'+block+'\n',{flag:'wx',mode:0o600});
  fs.renameSync(temp,file);
  console.log('Added global mute: Super+Ctrl+M. Customize it in Omarchy keybindings.');
}
