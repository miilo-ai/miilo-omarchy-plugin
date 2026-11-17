import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "onboarding/controls" as Controls

ColumnLayout {
    id: root
    required property var context
    property var workers: []
    property string status: ""
    property string error: ""
    property var arguments: ["list"]
    property bool changing: false
    property bool requestsEnabled: true
    property int serial: 0
    readonly property bool busy: request.running
    readonly property var modes: ["paused", "available", "idle_only", "draining"]
    spacing: root.context.theme.gap * 1.5
    function refresh() { if (requestsEnabled && !busy) { changing = false; arguments = ["list"]; request.running = true; } }
    function change(worker, index) {
        if (busy || index < 0 || index >= modes.length || modes[index] === worker.availability.mode) return;
        const command = {paused:"pause", available:"available", idle_only:"idle-only", draining:"drain"}[modes[index]];
        changing = true;
        error = "";
        arguments = [command, worker.id, String(worker.availability.revision), "native-" + Date.now() + "-" + (++serial)];
        if (requestsEnabled) request.running = true;
    }
    onVisibleChanged: if (visible) refresh()
    Component.onCompleted: if (visible) refresh()
    Timer { interval: 15000; repeat: true; running: root.visible && root.requestsEnabled; onTriggered: root.refresh() }
    Process {
        id: request
        command: [Quickshell.env("HOME") + "/.local/bin/miilo-owl", "workers"].concat(root.arguments)
        stdout: StdioCollector { id: output }
        onExited: code => {
            try {
                const result = JSON.parse(output.text);
                if (code !== 0 || result.status === "failed") throw new Error("request failed");
                if (root.changing) {
                    root.status = "Change confirmed";
                    Qt.callLater(root.refresh);
                } else {
                    root.workers = Array.isArray(result.workers) ? result.workers.slice(0, 200) : [];
                    root.status = result.status === "unconfigured" ? "Configure a worker backend to manage your nodes." : "";
                }
            } catch (_) {
                root.error = root.changing ? "Change not confirmed. Refresh the node status before trying again." : "Worker status unavailable. Check the backend connection and unlock its keyring if needed.";
                if (root.changing) Qt.callLater(root.refresh);
            }
        }
    }
    RowLayout {
        Layout.fillWidth: true
        TypeText { typography:root.context.theme.typography; role:"small"; color:root.context.theme.foreground; Layout.fillWidth:true; text:"Choose when each computer accepts background work. Pausing preserves its current job." }
        Controls.Action { context:root.context; text:"Refresh"; enabled:!root.busy; onClicked:{root.error="";root.refresh();} }
    }
    Repeater {
        model: root.workers
        RowLayout {
            id: row
            required property var modelData
            Layout.fillWidth: true
            spacing: root.context.theme.gap * 1.5
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3
                TypeText { typography:root.context.theme.typography; color:root.context.theme.foreground; font.weight:Font.DemiBold; text:row.modelData.name || row.modelData.id; Layout.fillWidth:true }
                TypeText { typography:root.context.theme.typography; role:"small"; color:root.context.theme.foreground; Layout.fillWidth:true; text:row.modelData.enabled === false ? "Not enrolled" : row.modelData.runtime?.state !== "online" ? "Offline" : row.modelData.runtime.busy_runners > 0 ? "Working" : "Ready" }
            }
            Controls.Choice {
                context: root.context
                Layout.preferredWidth: 155
                enabled: !root.busy && row.modelData.enabled !== false
                Accessible.name: "Availability for " + row.modelData.id
                model: ["Paused", "Available", "Idle only", "Draining"]
                currentIndex: root.modes.indexOf(row.modelData.availability.mode)
                onActivated: root.change(row.modelData, currentIndex)
            }
        }
    }
    TypeText { typography:root.context.theme.typography; role:"small"; color:root.context.theme.foreground; Layout.fillWidth:true; text:root.error || root.status; visible:text.length>0 }
    TypeText { typography:root.context.theme.typography; role:"small"; color:root.context.theme.foreground; Layout.fillWidth:true; text:"Desktop and device tests require a separate reservation. Availability does not grant access to your screen or microphone." }
}
