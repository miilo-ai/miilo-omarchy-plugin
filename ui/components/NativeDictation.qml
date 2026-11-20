import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    property bool active: false
    property bool focusSafe: false
    property string program: "superwhisper"
    property string selector: "omarchy-default-dictation"
    property var prefix: ["env", "PATH=" + Quickshell.env("HOME") + "/.local/bin:" + Quickshell.env("PATH")]
    property string phase: "unavailable"
    property string message: "Checking dictation…"
    property bool available: false
    property bool ready: false
    property string failure: ""
    property bool owned: false
    property bool pendingStart: false
    property bool cancelPending: false
    property string operation: ""
    property string baselineStamp: ""
    property bool sawRecording: false
    property int idleChecks: 0
    property int commandTimeout: 8000
    readonly property bool busy: command.running || status.running || selection.running
    readonly property bool recording: owned && phase === "recording"
    readonly property bool processing: owned && !recording
    signal focusRequested()
    function probe() {
        if (active && !busy && !owned) {
            available = false;
            ready = false;
            selection.running = true;
        }
    }
    function inspect() { if (active && !status.running && !command.running) status.running = true; }
    function invoke(action) {
        operation = action;
        command.running = true;
    }
    function start() {
        if (!active || !ready || owned || busy || pendingStart) return;
        failure = "";
        focusRequested();
        pendingStart = true;
        selection.running = true;
    }
    function stop() {
        if (!owned || command.running) return;
        focusRequested();
        invoke("stop");
    }
    function cancel() {
        pendingStart = false;
        if (!owned) return;
        cancelPending = true;
        message = "Cancelling dictation…";
        if (!command.running) invoke("cancel");
    }
    function settings() {
        cancel();
        if (!setup.running) setup.running = true;
    }
    onActiveChanged: { if (active) probe(); else cancel(); }
    onFocusSafeChanged: if (!focusSafe) cancel();
    Component.onCompleted: if (active) probe()
    Component.onDestruction: if (owned) Quickshell.execDetached(prefix.concat([program, "cancel"]))
    Process {
        id: selection
        command: root.prefix.concat([root.selector])
        stdout: StdioCollector { id: selected }
        onExited: code => {
            if (code === 0 && selected.text.trim() === "superwhisper") root.inspect();
            else {
                root.pendingStart = false;
                root.available = false;
                root.ready = false;
                root.phase = "unavailable";
                root.message = "Select Superwhisper in Omarchy’s Dictation settings.";
            }
        }
    }
    Process {
        id: status
        command: root.prefix.concat([root.program, "status"])
        stdout: StdioCollector { id: snapshot }
        onExited: code => {
            if (!root.active && !root.owned) return;
            try {
                if (code !== 0 || snapshot.text.length > 262144) throw Error();
                const value = JSON.parse(snapshot.text);
                if (typeof value.ready !== "boolean" || typeof value.phase !== "string" || value.error) throw Error();
                root.available = true;
                root.phase = value.phase || "idle";
                const idle = root.phase === "idle";
                root.ready = idle && value.ready;
                if (root.pendingStart) {
                    root.pendingStart = false;
                    if (!idle || !value.ready || !root.focusSafe) {
                        root.message = "Superwhisper is busy, warming up, or the draft lost focus.";
                        return;
                    }
                    root.baselineStamp = String(value.last?.createdAt || "");
                    root.sawRecording = false;
                    root.idleChecks = 0;
                    root.owned = true;
                    root.phase = "starting";
                    root.invoke("start");
                } else if (root.owned) {
                    if (root.phase === "recording") root.sawRecording = true;
                    if (idle) {
                        if (!root.sawRecording && String(value.last?.createdAt || "") === root.baselineStamp && ++root.idleChecks < 5) return;
                        root.owned = false;
                        root.message = String(value.last?.createdAt || "") !== root.baselineStamp
                            ? "Dictation finished. Review your draft before sending."
                            : "No new transcript confirmed. Check Superwhisper.";
                    } else root.message = root.phase === "recording" ? "Listening…" : "Processing dictation…";
                } else root.message = idle && value.ready ? "Superwhisper ready · check local/cloud settings" : "Superwhisper is busy or warming up.";
            } catch (_) {
                root.pendingStart = false;
                root.available = false;
                root.ready = false;
                root.message = "Cannot read Superwhisper status. Check its settings.";
                root.failure = root.message;
                root.cancel();
            }
        }
    }
    Process {
        id: command
        command: root.prefix.concat([root.program, root.operation])
        stdout: StdioCollector { id: result }
        onExited: code => {
            let failed = code !== 0;
            try { if (result.text.trim() && JSON.parse(result.text).error) failed = true; } catch (_) { failed = true; }
            if (root.operation === "cancel") {
                root.owned = false;
                root.cancelPending = false;
                root.phase = "idle";
                root.ready = !failed && root.available;
                root.message = failed ? "Cancellation could not be confirmed. Use Superwhisper’s cancel shortcut." : root.failure || "Dictation cancelled. Your draft was kept.";
            } else if (root.cancelPending) root.invoke("cancel");
            else if (failed) {
                root.message = "Dictation command failed. Check Superwhisper.";
                root.failure = root.message;
                root.cancel();
            } else {
                root.message = root.operation === "start" ? "Starting dictation…" : "Processing dictation…";
                root.inspect();
            }
        }
    }
    Process {
        id: setup
        command: root.prefix.concat(root.available ? [root.program, "settings"] : ["omarchy", "default", "dictation", "superwhisper"])
    }
    Timer { interval: 300; repeat: true; running: root.active && root.owned; onTriggered: root.inspect() }
    Timer {
        interval: 100; repeat: true; running: root.active && root.owned
        onTriggered: if (!root.focusSafe) root.cancel()
    }
    Timer {
        interval: root.commandTimeout; running: root.busy
        onTriggered: {
            root.pendingStart = false;
            selection.signal(15); status.signal(15); command.signal(15);
            root.message = "Superwhisper did not respond in time.";
            root.failure = root.message;
            root.cancel();
        }
    }
}
