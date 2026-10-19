// Native Qt evaluator timing in an isolated synthetic scene; excludes GPU paint.
const fs=require('node:fs'),path=require('node:path'),os=require('node:os');
const {spawnSync}=require('node:child_process'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..'),folder=fs.mkdtempSync(path.join(os.tmpdir(),'miilo-render-budget-'));
try {
 fs.mkdirSync(path.join(folder,'runtime'),{mode:0o700});
 fs.writeFileSync(path.join(folder,'shell.qml'),`import Quickshell\nimport "file:${root}/tests/typography" as Tests\nShellRoot { FloatingWindow { implicitWidth:580; implicitHeight:620; Tests.TestRenderBudget { scratchPath: "${folder}"; forceLayout: ${process.argv.includes('--force-layout')} } } }`);
 const env={...process.env,XDG_RUNTIME_DIR:path.join(folder,'runtime'),QT_QPA_PLATFORM:'offscreen',QT_QUICK_BACKEND:'software',QT_QPA_PLATFORMTHEME:'basic',QT_QUICK_CONTROLS_STYLE:'Basic'};delete env.WAYLAND_DISPLAY;
 const result=spawnSync('quickshell',['-p',path.join(folder,'shell.qml'),'--no-color'],{env,encoding:'utf8',timeout:25000});
 console.log(result.stdout||'',result.stderr||'');assert.equal(result.status,0);
 assert((result.stdout+result.stderr).includes('MIILO_RENDER_BUDGET_OK'),'Native evaluator benchmark did not finish');
}finally{fs.rmSync(folder,{recursive:true,force:true});}
