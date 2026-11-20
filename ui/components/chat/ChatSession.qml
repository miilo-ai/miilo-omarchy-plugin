import QtQuick
import Quickshell
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
    property bool loadConfigStatus: true
    property bool configured: false
    property bool spoken: false
    property bool spokenTurn: false
    signal turnStarted()
    signal answerDelta(string text)
    signal turnFinished(bool complete)
    function probe() { if(loadConfigStatus && !setupStatus.running)setupStatus.running=true; }
    Component.onCompleted: probe()
    readonly property bool busy: request.running || terminating || value("phase") === "streaming"
    function value(key) { var revision = generation; return state[key]; }
    function dismissError() { state.error = ""; generation++; }
    function reset() {
        Stream.cancel(state);
        terminating = terminating || request.running;
        request.running = false;
        state = Stream.create();
        Stream.select(state, target);
        generation++;
    }
    function cancel() { Stream.cancel(state); generation++; terminating = terminating || request.running; request.running = false; turnFinished(false); }
    function send(text, parent) {
        if (!active || busy) return false;
        try {
            const id = "native-" + Date.now() + "-" + (++serial);
            traceParent = typeof parent === "string" && /^00-[0-9a-f]{32}-[0-9a-f]{16}-01$/.test(parent) ? parent : "";
            payload = JSON.stringify(Stream.begin(state, id, text));
            spokenTurn = spoken;
            generation++;
            request.turnId = id;
            request.stdinEnabled = true;
            turnStarted();
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
        command: [root.program, "chat"].concat(root.spokenTurn ? ["--spoken"] : []).concat(root.traceParent ? ["--trace-parent",root.traceParent] : [])
        stdinEnabled: true
        onStarted: { write(root.payload); stdinEnabled = false; }
        stdout: SplitParser {
            onRead: line => {
                const before = root.state.answer.length;
                const accepted = Stream.receive(root.state, request.turnId, line);
                root.generation++;
                if (accepted && root.state.answer.length > before)
                    root.answerDelta(root.state.answer.slice(before));
                if (accepted && root.state.phase === "done") root.turnFinished(true);
                else if (root.state.phase === "incomplete") root.turnFinished(false);
            }
        }
        onExited: code => {
            root.terminating = false;
            Stream.exited(root.state, turnId);
            root.generation++;
            if (root.state.phase === "incomplete") root.turnFinished(false);
        }
    }
    property Process setupStatus: Process {
        command: ["env","PATH="+Quickshell.env("HOME")+"/.local/bin:"+Quickshell.env("PATH"),root.program,"chat-status"]
        stdout: StdioCollector { id: configuration }
        onExited: code => {try{root.configured=code===0 && JSON.parse(configuration.text).ready===true;}catch(_){root.configured=false;}}
    }
}
