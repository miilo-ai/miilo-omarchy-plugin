import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root
    property string program: "miilo-voice-session"
    property var prefix: ["env", "PATH=" + Quickshell.env("HOME") + "/.local/bin:" + Quickshell.env("PATH")]
    property bool active: false
    property bool loadSettings: true
    property bool previewAllowed: false
    property bool previewing: false
    property bool ready: false
    property bool terminating: false
    readonly property bool busy: request.running || terminating
    property string phase: "off"
    property string error: ""
    property string payload: ""
    function cancel() {
        terminating = terminating || request.running;
        request.running = false; phase = "off"; previewing=false;
    }
    function speak(text) {
        if ((!active && !previewing) || busy || !text || !text.trim()) return false;
        if (!ready) { error = "Configure spoken replies in Voice settings."; return false; }
        if (text.length > 16000) { error = "Reply is too long for speech; read the text reply."; return false; }
        error = ""; payload = JSON.stringify({text:text}); phase = "preparing_playback";
        request.stdinEnabled = true; request.running = true; return true;
    }
    function preview() {
        if(!previewAllowed || busy)return false;
        previewing=true;
        const started=speak("Miilo is ready.");
        if(!started)previewing=false;
        return started;
    }
    function probe() { if (!status.running) status.running = true; }
    onActiveChanged: if (!active && !previewing) cancel()
    onPreviewAllowedChanged: if(!previewAllowed)cancel()
    Component.onCompleted: if(loadSettings) probe()
    property Process status: Process {
        command: root.prefix.concat([root.program,"playback-status"])
        stdout: StdioCollector { id: configuration }
        onExited: code => {
            try { root.ready = code === 0 && JSON.parse(configuration.text).ready === true; }
            catch (_) { root.ready = false; }
        }
    }
    property Process request: Process {
        command: root.prefix.concat([root.program,"speak"])
        stdinEnabled: true
        onStarted: { if (root.active || (root.previewing && root.previewAllowed)) { write(root.payload); stdinEnabled=false; } else root.cancel(); }
        stdout: SplitParser {
            onRead: line => {
                if (line.length>8192) {root.error="Invalid speech response.";root.cancel();return;}
                try {
                    const value=JSON.parse(line);
                    if ((root.active || root.previewing) && value.type==="state" && ["preparing_playback","speaking","done"].indexOf(value.phase)>=0) root.phase=value.phase;
                    else if(value.type==="error") root.error="Spoken reply failed; the text reply is available.";
                } catch (_) {root.error="Invalid speech response.";root.cancel();}
            }
        }
        onExited: code => {
            root.terminating=false;root.phase="off";
            if(code!==0 && root.active && !root.error) root.error="Spoken reply failed; the text reply is available.";
            root.payload="";root.previewing=false;
        }
    }
}
