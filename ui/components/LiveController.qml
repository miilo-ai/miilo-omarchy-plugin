import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    required property string appName
    required property string statePath
    property string program: Quickshell.env("HOME") + "/.local/bin/miilo-live-monitor"
    property bool focused: false
    property var config: ({enabled:false,completions:false,quiet:false,sources:[]})
    property var state: ({events:[],frames:{}})
    property var readIds: []
    property double clock: Date.now()
    property double heartbeat: 0
    property string stateSignature: ""
    readonly property bool monitorStale: config.enabled&&(!heartbeat||clock-heartbeat>30000)
    property string error: ""
    property bool deliveryFailed: false
    property var arguments: []
    property string input: ""
    property bool changing: false
    property bool enableAfterAdd: false
    property int commandTimeoutMs: 10000
    property string lastOpening: ""
    readonly property bool busy: request.running || changing
    readonly property int unread: (state.events || []).filter(e => !readIds.includes(e.id)).length
    signal openRequested(string source, string target)
    function invoke(args, text) {
        if (busy) return;
        changing = true; error = ""; arguments = args; input = text || "";
        request.stdinEnabled = input.length > 0; request.running = true;
    }
    function add(kind, helper, study) { invoke(["add","--kind",kind,"--program",helper].concat(study ? ["--config",study] : [])); }
    function watchJob(kind, helper, configPath, job, output) {
        if(busy)return;enableAfterAdd=true;
        invoke(["add","--kind",kind,"--program",helper,"--config",configPath].concat(job?["--job",job,"--output",output]:[]));
    }
    function enable(value) { invoke(["enable","--enabled",String(value)]); }
    function preferences(completions, quiet) { invoke(["preferences","--completions",String(completions),"--quiet",String(quiet)]); }
    function motion(value) {invoke(["preferences","--completions",String(config.completions),"--quiet",String(config.quiet),"--motion",value]);}
    function ack() { invoke(["ack"]); }
    function reload() { settings.reload(); journal.reload(); read.reload(); opening.reload(); delivery.reload(); pulse.reload(); }
    FileView {
        id:pulse;path:root.statePath+"/heartbeat.json";watchChanges:true;printErrors:false
        onFileChanged:reload()
        onLoaded:{try{root.heartbeat=Math.max(root.heartbeat,JSON.parse(text()).at||0);}catch(_){}}
    }
    FileView {
        id: delivery; path: root.statePath + "/delivery.json"; watchChanges: true; printErrors: false
        onFileChanged: reload()
        onLoaded: {try {root.deliveryFailed=JSON.parse(text()).failed===true;}catch(_){}}
    }
    FileView {
        id: settings; path: root.statePath + "/config.json"; watchChanges: true; printErrors: false
        onFileChanged: reload()
        onLoaded: { try { const value=JSON.parse(text()); if(Array.isArray(value.sources)&&JSON.stringify(value)!==JSON.stringify(root.config))root.config=value; } catch (_) {root.error="Cannot read monitoring preferences.";} }
    }
    FileView {
        id: journal; path: root.statePath + "/state.json"; watchChanges: true; printErrors: false
        onFileChanged: reload()
        onLoaded: { try { const value=JSON.parse(text()); if(Array.isArray(value.events)){root.heartbeat=Math.max(root.heartbeat,value.updated_at||0);const signature=JSON.stringify([value.events,value.frames]);if(signature!==root.stateSignature){root.stateSignature=signature;root.state=value;}} } catch (_) {root.error="Cannot read observation status.";} }
    }
    FileView {
        id: read; path: root.statePath + "/read.json"; watchChanges: true; printErrors: false
        onFileChanged: reload()
        onLoaded: {try {root.readIds=JSON.parse(text()).ids||[];}catch(_){}}
    }
    FileView {
        id: opening; path: root.statePath + "/open.json"; watchChanges: true; printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {const value=JSON.parse(text());const source=value.source;if(typeof source==="string"&&root.config.sources.some(s=>s.id===source)){const signature=JSON.stringify(value);if(signature!==root.lastOpening){root.lastOpening=signature;root.openRequested(source,typeof value.target==="string"?value.target:"");}if(!root.busy)root.invoke(["ack-open"]);}else root.lastOpening="";}catch(_){}
        }
    }
    Process {
        id: request
        command: [root.program,"--root",root.statePath,"--app",root.appName].concat(root.arguments)
        onStarted: {if(root.input){write(root.input);stdinEnabled=false;}}
        onExited: code => {
            root.changing=false;
            if(code!==0)root.error="Monitoring change failed. Check the helper and user service.";
            root.reload();
            if(root.enableAfterAdd){root.enableAfterAdd=false;if(code===0)Qt.callLater(()=>root.enable(true));}
        }
    }
    Process {
        id: focus
        command: [root.program,"--root",root.statePath,"--app",root.appName,"focus","--active",String(root.focused)]
    }
    onFocusedChanged: if(config.enabled&&!focus.running)focus.running=true
    Timer {interval:root.commandTimeoutMs;running:root.busy;onTriggered:{request.running=false;root.changing=false;root.enableAfterAdd=false;root.error="Monitoring helper did not respond. Check its installation and try again.";}}
    Timer { interval:5000;repeat:true;running:root.config.enabled;onTriggered:if(!focus.running)focus.running=true }
    Timer { interval:3000;repeat:true;running:root.visible;onTriggered:root.reload() }
    Timer { interval:1000;repeat:true;running:root.visible&&root.config.enabled;onTriggered:root.clock=Date.now() }
}
