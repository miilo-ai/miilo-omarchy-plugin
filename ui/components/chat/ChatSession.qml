import QtQuick
import Quickshell.Io
import "StreamState.js" as Stream

QtObject {
    id: root
    property bool active: false
    property var target: null
    property var state: Stream.create()
    property int generation: 0
    property int serial: 0
    property string payload: ""
    property string program: "miilo-owl"
    property string traceParent: ""
    property bool terminating: false
    readonly property bool busy: request.running || terminating || value("phase") === "streaming"
    function value(key) { var revision = generation; return state[key]; }
    function reset() {
        Stream.cancel(state);
        terminating = terminating || request.running;
        request.running = false;
        state = Stream.create();
        Stream.select(state, target);
        generation++;
    }
    function cancel() { Stream.cancel(state); generation++; terminating = terminating || request.running; request.running = false; }
    function send(text, parent) {
        if (!active || busy) return false;
        try {
            const id = "native-" + Date.now() + "-" + (++serial);
            traceParent = typeof parent === "string" && /^00-[0-9a-f]{32}-[0-9a-f]{16}-01$/.test(parent) ? parent : "";
            payload = JSON.stringify(Stream.begin(state, id, text));
            generation++;
            request.turnId = id;
            request.stdinEnabled = true;
            request.running = true;
            return true;
        } catch (_) {
            state.error = "Enter a message of at most 4,000 characters.";
            generation++;
            return false;
        }
    }
    onTargetChanged: reset()
    onActiveChanged: if (!active) reset()
    property Process request: Process {
        property string turnId: ""
        command: [root.program, "chat"].concat(root.traceParent ? ["--trace-parent",root.traceParent] : [])
        stdinEnabled: true
        onStarted: { write(root.payload); stdinEnabled = false; }
        stdout: SplitParser {
            onRead: line => {
                Stream.receive(root.state, request.turnId, line);
                root.generation++;
            }
        }
        onExited: code => {
            root.terminating = false;
            Stream.exited(root.state, turnId);
            root.generation++;
        }
    }
}
