import QtQuick
import QtCore
import Quickshell
import Quickshell.Io
import "IntakeState.js" as Intake

Item {
    id: root
    property bool active: false
    property string program: "miilo"
    readonly property string settingsPath: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/miilo-one/intake.ini"
    property alias transport: config.transport
    property alias socketFile: config.socketFile
    property alias endpoint: config.endpoint
    property alias tokenFile: config.tokenFile
    property alias speakArrivals: config.speakArrivals
    signal decisionCompleted(string message)
    signal tasksArrived(int count)
    property var items: []
    property string cursor: ""
    property string error: ""
    property string message: ""
    property bool stale: true
    property int serial: 0
    property int connectionGeneration: 0
    property var commandArguments: ["list"]
    property bool mutating: false
    property var retryArguments: []
    readonly property bool configured: transport === "socket" ? socketFile.trim() !== "" : endpoint.trim() !== "" && tokenFile.trim() !== ""
    readonly property bool busy: process.running
    Settings {
        id: config
        category: "Intake"
        location: "file://" + root.settingsPath.split("/").map(encodeURIComponent).join("/")
        property string transport: "socket"
        property string socketFile: ""
        property string endpoint: ""
        property string tokenFile: ""
        property bool speakArrivals: false
        property string seen: "[]"
    }
    function refresh() {
        if (!configured || busy) return;
        mutating = false; commandArguments = ["list"]; process.requestGeneration = connectionGeneration; process.running = true;
    }
    function receiveText(text, method) {
        const value = Intake.resolve(text, items);
        if (!value.handled) return false;
        if (busy || stale) { message = "Refresh the inbox before deciding."; return true; }
        if (value.item) decide(value.item, value.action, method);
        else { message = value.message; decisionCompleted(message); }
        return true;
    }
    function announce(items) {
        let seen;
        try { seen = JSON.parse(config.seen); if (!Array.isArray(seen)) seen = []; } catch (_) { seen = []; }
        let count = 0;
        for (const item of items) {
            const details = Intake.details(item);
            if (!details || details.decision !== "pending") continue;
            const key = JSON.stringify([root.transport,root.socketFile,root.endpoint,item.providerId,item.id,item.revision]);
            if (!seen.includes(key)) { seen.push(key); count++; }
        }
        config.seen = JSON.stringify(seen.slice(-256));
        if (count) tasksArrived(count);
    }
    function decide(item, action, method) {
        if (busy || stale) return;
        const now = new Date();
        const id = "native-intake-" + now.getTime() + "-" + (++serial) + "-" + Math.floor(Math.random() * 1000000000);
        try {
            commandArguments = Intake.command(item, action, id, now.toISOString(), new Date(now.getTime() + 4 * 3600000).toISOString());
            commandArguments = commandArguments.concat(["--method", method === "voice" ? "voice" : "manual"]);
            retryArguments = commandArguments.slice(); mutating = true; error = ""; process.requestGeneration = connectionGeneration; process.running = true;
        } catch (_) { error = "Action unavailable. Refresh the inbox."; }
    }
    function retry() {
        if (!busy && retryArguments.length) { commandArguments = retryArguments.slice(); mutating = true; process.requestGeneration = connectionGeneration; process.running = true; }
    }
    function invalidateConnection() {
        connectionGeneration++; items = []; cursor = ""; stale = true; retryArguments = []; message = "";
        process.running = false;
        if (active) Qt.callLater(refresh);
    }
    onTransportChanged: invalidateConnection()
    onSocketFileChanged: invalidateConnection()
    onEndpointChanged: invalidateConnection()
    onTokenFileChanged: invalidateConnection()
    onActiveChanged: if (active) refresh()
    Process {
        id: process
        property int requestGeneration: -1
        command: ["env", "PATH=" + Quickshell.env("HOME") + "/.local/bin:" + Quickshell.env("PATH"), root.program, "--json"].concat(root.transport === "socket" ? ["--socket", root.socketFile] : ["--endpoint", root.endpoint, "--token-file", root.tokenFile]).concat(["inbox"]).concat(root.commandArguments)
        stdout: StdioCollector { id: reply }
        onExited: code => {
            if (requestGeneration !== root.connectionGeneration) return;
            try {
                if (code !== 0 || reply.text.length > 2097152) throw Error();
                const value = JSON.parse(reply.text);
                if (root.mutating) {
                    if (!["accepted", "completed"].includes(value.status)) throw Error();
                    root.message = value.message || "Decision recorded.";
                    root.decisionCompleted(root.message);
                    root.retryArguments = []; root.stale = true; refreshLater.start();
                } else {
                    if (!Array.isArray(value.items)) throw Error();
                    if (root.cursor !== value.cursor || root.stale) { root.announce(value.items); root.items = value.items; root.cursor = value.cursor; } root.stale = false;
                }
                root.error = "";
            } catch (_) {
                root.stale = true;
                root.error = root.mutating ? "Outcome unknown. Refresh or retry the same request." : "Intake unavailable. Check the connection.";
            }
        }
    }
    Timer { id: refreshLater; interval: 20; onTriggered: root.refresh() }
    Timer { interval: 15000; running: root.active && root.configured; repeat: true; onTriggered: root.refresh() }
    Timer { interval: 35000; running: process.running; onTriggered: { process.signal(15); root.stale = true; } }
}
