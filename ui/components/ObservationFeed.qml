import QtQuick
import Quickshell.Io

Item {
    id: root
    property bool active: true
    property bool expanded: false
    property string program: "miilo-owl"
    property var snapshot: ({})
    property string raw: ""
    property bool stale: true
    property int failures: 0
    property double fetchedAt: 0
    property bool forceRead:false
    property int commandTimeout: 25000
    function refresh() {if(active&&!fetch.running){forceRead=expanded;fetch.running=true;}}
    onActiveChanged: if(active)refresh()
    onExpandedChanged: if(expanded)refresh()
    Component.onCompleted: refresh()
    Process {
        id: fetch
        command:[root.program,root.forceRead?"refresh":"snapshot"]
        stdout:StdioCollector {id:reply}
        onExited: code => {
            try {
                if(code!==0||reply.text.length>2097152)throw Error();
                const value=JSON.parse(reply.text);
                if(!value.snapshot||typeof value.snapshot!=="object")throw Error();
                root.raw=reply.text;root.snapshot=value;root.stale=false;root.failures=0;root.fetchedAt=Date.now();
            }catch(_){root.stale=true;root.failures=Math.min(6,root.failures+1);}
        }
    }
    Timer {interval:Math.min(30000,(root.expanded?1000:15000)*Math.pow(2,root.failures));running:root.active;repeat:true;onTriggered:root.refresh()}
    Timer {interval:root.commandTimeout;running:fetch.running;onTriggered:{fetch.signal(15);root.stale=true;}}
}
