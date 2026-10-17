import QtQuick
import Quickshell
import Quickshell.Io

Item {
    required property var controller
    readonly property bool detecting: detection.running
    readonly property bool discovering: discovery.running
    readonly property bool grouping: grouping.running
    readonly property bool importing: importing.running
    function detect() { if (!detection.running) detection.running = true }
    function discover() { if (!discovery.running) discovery.running = true }
    function regroup() { if (!grouping.running) grouping.running = true }
    function dismiss() { if (!dismissal.running) dismissal.running = true }
    function enroll() { if (!importing.running) importing.running = true }
    Process {
        id: detection
        command: ["miilo-owl", "local-agents"]
        running: controller.active
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var result = JSON.parse(text);
                    controller.agents = (result.agents || []).filter(a => a.found);
                    controller.fingerprint = result.fingerprint || "";
                    if (controller.agents.length && !result.dismissed && !controller.busy)
                        controller.mode = "invite";
                } catch (e) { /* An unavailable helper must not masquerade as detected agents. */ }
            }
        }
    }
    Process {
        id: dismissal
        command: ["miilo-owl", "dismiss-local", controller.fingerprint]
    }
    Process {
        id: discovery
        command: [Quickshell.env("MIILO_LOCAL_EXECUTABLE") || "miilo-local", "discover", controller.project]
        stdout: StdioCollector {
            onStreamFinished: {
                if (controller.mode === "")
                    return;
                try {
                    var result = JSON.parse(text);
                    controller.sessions = result.sessions || [];
                    if (!controller.groupsLoaded) { controller.groups = result.savedGroups || []; controller.groupsLoaded = true; }
                    controller.selected = [];
                    controller.error = (result.errors || []).join(". ");
                    controller.mode = "review";
                    controller.regroup();
                } catch (e) {
                    controller.mode = "review";
                    controller.error = "Local session discovery is unavailable. Check that the Miilo local connector is installed.";
                }
            }
        }
        onExited: code => {
            if (code !== 0 && controller.mode !== "") {
                controller.mode = "review";
                controller.error = "Could not list local sessions. Check the project directory and try again.";
            }
        }
    }
    Process {
        id: grouping
        command: [Quickshell.env("MIILO_LOCAL_EXECUTABLE") || "miilo-local", "groups"]
        stdinEnabled: true
        onStarted: write(JSON.stringify({sessions:controller.sessions,groups:controller.pendingGroups || controller.groups}) + "\n")
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var result = JSON.parse(text);
                    controller.grouped = result.groups || [];
                    if (controller.pendingGroups) { controller.groups = controller.pendingGroups; controller.groupsDirty = true; controller.mode = "review"; }
                    controller.pendingGroups = null; controller.error = ""; controller.rebuildRows();
                } catch (e) { controller.pendingGroups = null; controller.error = "Could not preview these groups."; }
            }
        }
        stderr: StdioCollector { onStreamFinished: if (text.trim()) controller.error = text.trim() }
        onExited: code => { if (code !== 0) { controller.pendingGroups = null; if (!controller.error) controller.error = "Check the group name, folder, and pattern."; } }
    }
    Process {
        id: importing
        command: [Quickshell.env("MIILO_LOCAL_EXECUTABLE") || "miilo-local", "import"]
        stdinEnabled: true
        onStarted: {
            var sessions = controller.sessions.filter(s => controller.selected.indexOf(s.kind + ":" + s.id) >= 0).map(s => ({
                        kind: s.kind,
                        id: s.id
                    }));
            write(JSON.stringify({
                sessions: sessions,
                project: controller.project
                ,groups: controller.groups
            }) + "\n");
        }
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    controller.reply = JSON.parse(text);
                } catch (e) {
                    controller.reply = {
                        status: "failed",
                        message: "The local connector did not complete the import."
                    };
                }
            }
        }
        onExited: code => {
            if (code === 0 && controller.reply.status === "connected") {
                controller.dismiss();
                controller.connected(controller.reply.sessions || 0);
            } else {
                controller.mode = "review";
                controller.error = controller.reply.message || "Import could not be completed. Your other Miilo connections were preserved.";
            }
        }
    }

}
