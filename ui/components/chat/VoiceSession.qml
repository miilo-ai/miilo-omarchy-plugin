import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    property string program: "miilo-voice-session"
    property var prefix: ["env", "PATH=" + Quickshell.env("HOME") + "/.local/bin:" + Quickshell.env("PATH")]
    property bool permitted: false
    property bool unlocked: false
    property bool paused: false
    property bool loadSavedSettings: true
    property string wakePhrase: "hey miilo"
    property int silenceMs: 1000
    property bool armed: false
    property bool muted: true
    property string phase: "off"
    property string error: ""
    readonly property string message: !armed ? error : muted ? "Microphone muted" : phase === "waiting" ? "Say “" + wakePhrase + "”" : phase === "listening" ? "Listening…" : phase === "transcribing" ? "Transcribing…" : phase === "paused" ? "Waiting for the reply…" : "Preparing hands-free…"
    signal transcript(string text)
    function control(value) { if (engine.running) engine.write(JSON.stringify(value)+"\n"); }
    function arm() {
        if (!permitted || !unlocked) { error = "Enable sharing in an unlocked session first."; return false; }
        error = ""; muted = false; phase = "starting"; armed = true; engine.running = true;
        return true;
    }
    function disarm() {
        muted = true; armed = false; phase = "off";
        control({type:"stop"}); engine.running = false;
    }
    function mute() { muted = true; control({type:"mute"}); }
    function toggleMute() {
        if (!armed) return;
        if (!muted) mute();
        else if (permitted && unlocked) { muted = false; control({type:"unmute"}); }
    }
    function receive(line) {
        if (line.length > 65536) { error = "Voice response exceeded its limit."; disarm(); return; }
        try {
            const value = JSON.parse(line);
            if (value.type === "state") phase = value.phase;
            else if (value.type === "error") { error = value.message || "Voice session failed."; disarm(); }
            else if (value.type === "transcript" && armed && !muted && permitted && unlocked && !paused && typeof value.text === "string" && value.text.trim() && value.text.length <= 4000) {
                phase = "paused";
                transcript(value.text);
            }
        } catch (_) { error = "Invalid voice-session response."; disarm(); }
    }
    function saveSettings(phrase, delay) {
        disarm();
        settings.command = prefix.concat([program,"settings","--phrase",phrase,"--silence-ms",String(delay)]);
        if (!settings.running) settings.running = true;
    }
    onPermittedChanged: if (!permitted) disarm()
    onUnlockedChanged: if (!unlocked) disarm()
    onPausedChanged: control({type:"heartbeat",paused:paused})
    Component.onCompleted: if (loadSavedSettings) settings.running = true
    Component.onDestruction: disarm()
    Process {
        id: engine
        command: root.prefix.concat([root.program,"run","--phrase",root.wakePhrase,"--silence-ms",String(root.silenceMs)])
        stdinEnabled: true
        onStarted: { if (root.armed && root.permitted && root.unlocked) root.control({type:"heartbeat",paused:root.paused}); else engine.running = false; }
        stdout: SplitParser { onRead: line => root.receive(line) }
        onExited: code => {
            if (root.armed) { root.error = "Voice session stopped. Enable it again when ready."; root.armed = false; root.muted = true; root.phase = "off"; }
        }
    }
    Timer { interval: 250; repeat: true; running: root.armed; onTriggered: { if (!root.permitted || !root.unlocked) root.disarm(); else root.control({type:"heartbeat",paused:root.paused}); } }
    Process {
        id: settings
        command: root.prefix.concat([root.program,"settings"])
        stdout: StdioCollector { id: saved }
        onExited: code => {
            try {
                const value = JSON.parse(saved.text);
                if (code !== 0 || value.type !== "settings") throw Error();
                root.wakePhrase = value.wake_phrase; root.silenceMs = value.silence_ms;
            } catch (_) { root.error = "Voice settings could not be loaded or saved."; }
        }
    }
}
