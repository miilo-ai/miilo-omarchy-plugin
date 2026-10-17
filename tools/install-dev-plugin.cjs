const path=require('node:path');
const os=require('node:os');
const {parseArgs}=require('node:util');
const {install}=require('./lib/install.cjs');
try {
  const home=os.homedir();
  const {values}=parseArgs({options:{'plugin-dir':{type:'string',default:path.join(process.env.XDG_CONFIG_HOME||path.join(home,'.config'),'omarchy/plugins/io.miilo.bar')},'bin-dir':{type:'string',default:path.join(home,'.local/bin')},'state-dir':{type:'string',default:path.join(process.env.XDG_STATE_HOME||path.join(home,'.local/state'),'miilo/plugin-backups')},helper:{type:'string'},local:{type:'string'},cli:{type:'string'},'install-binaries':{type:'boolean',default:false}}});
  if(!values.helper||!values.local)throw Error('--helper and --local are required');
  install(path.resolve(__dirname,'..'),{pluginDir:values['plugin-dir'],binDir:values['bin-dir'],stateDir:values['state-dir'],helper:values.helper,local:values.local,cli:values.cli,installBinaries:values['install-binaries']});
}catch(error){console.error('Miilo install stopped: '+error.message);process.exitCode=1;}
