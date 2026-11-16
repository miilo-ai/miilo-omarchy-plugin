import QtQuick
import Quickshell
import Quickshell.Io
import "SpeechQueue.js" as Speech

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
    property bool interrupted: false
    property bool receiving: false
    property bool failed: false
    property var turn: Speech.create()
    property int queueRevision: 0
    readonly property bool busy: request.running || terminating || receiving || (queueRevision >= 0 && turn.queue.length > 0)
    property string phase: "off"
    property string error: ""
    function cancel() {
        receiving = false; turn = Speech.create(); queueRevision++;
        interrupted = interrupted || request.running;
        terminating = terminating || request.running;
        request.running = false; phase = "off"; previewing = false;
    }
    function beginTurn() {
        cancel(); failed = false;
        if (active) { receiving = true; phase = "preparing_playback"; error = ""; }
    }
    function append(text, final) {
        if ((!active && !previewing) || !receiving || failed) return;
        if (!ready) { fail("Configure spoken replies in Voice settings."); return; }
        try {
            Speech.append(turn, text, final); queueRevision++;
            if (final) receiving = false;
            pump();
        } catch (_) { fail("Spoken reply exceeded its limit."); }
    }
    function fail(message) { failed = true; cancel(); error = message; }
    function pump() {
        if (terminating || failed) return;
        if (!request.running) {
            if (!turn.queue.length) return;
            request.stdinEnabled = true; request.running = true;
            return;
        }
        if (!request.started) return;
        while (turn.queue.length) request.write(JSON.stringify({type:"text",text:turn.queue.shift()})+"\n");
        queueRevision++;
        if (turn.closed && request.stdinEnabled) {
            request.write('{"type":"done"}\n'); request.stdinEnabled = false;
        }
    }
    function speak(text) {
        if ((!active && !previewing) || busy || !text || !text.trim()) return false;
        failed = false; receiving = true;
        append(text, true); return !failed;
    }
    function preview() {
        if (!previewAllowed || busy) return false;
        previewing = true;
        const started = speak("Miilo is ready.");
        if (!started) previewing = false;
        return started;
    }
    function probe() { if (!status.running) status.running = true; }
    onActiveChanged: if (!active && !previewing) cancel()
    onPreviewAllowedChanged: if (!previewAllowed) cancel()
    Component.onCompleted: if (loadSettings) probe()
    property Process status: Process {
        command: root.prefix.concat([root.program,"playback-status"])
        stdout: StdioCollector { id: configuration }
        onExited: code => {
            try { root.ready = code === 0 && JSON.parse(configuration.text).ready === true; }
            catch (_) { root.ready = false; }
        }
    }
    property Process request: Process {
        property bool started: false
        command: root.prefix.concat([root.program,"speak-stream"])
        stdinEnabled: true
        onStarted: {
            started = true;
            if (root.active || (root.previewing && root.previewAllowed)) root.pump(); else root.cancel();
        }
        stdout: SplitParser {
            onRead: line => {
                if (line.length > 8192) { root.fail("Invalid speech response."); return; }
                try {
                    const value = JSON.parse(line);
                    if ((root.active || root.previewing) && value.type === "state" && ["preparing_playback","speaking","done"].indexOf(value.phase) >= 0)
                        root.phase = value.phase === "done" && root.busy ? "preparing_playback" : value.phase;
                    else if (value.type === "error") root.fail("Spoken reply failed. Check Voice settings.");
                } catch (_) { root.fail("Invalid speech response."); }
            }
        }
        onExited: code => {
            const cancelled = root.interrupted; root.interrupted = false;
            started = false; root.terminating = false; root.phase = "off";
            root.previewing = false;
            if (code !== 0 && !cancelled && !root.failed && (root.active || root.receiving)) root.fail("Spoken reply failed. Check Voice settings.");
            else if (cancelled) Qt.callLater(() => root.pump());
        }
    }
}
