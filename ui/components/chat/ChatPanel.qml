import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".." as Miilo
import "../onboarding/controls" as Controls

// An in-place conversation dock. The workspace remains visible and interactive.
FocusScope {
    id: root
    required property var theme
    required property var surface
    property var target: null
    property bool sessionUnlocked: false
    property bool loadVoiceSettings: true
    property bool sharing: false
    property bool composing: false
    property bool captions: false
    property bool overlayVisible: true
    property alias handsFree: handsFree
    property alias playback: playback
    readonly property string playbackPhase: playback.busy ? playback.phase : ""
    readonly property bool ready: session.configured && playback.ready
    readonly property var context: ({theme: theme, widget: surface.widget})
    readonly property bool expanded: overlayVisible && (composing || captions || !!session.value("error") || !!playback.error || !!handsFree.error)
    implicitHeight: expanded ? form.implicitHeight + theme.gap * 2 : 0
    signal settingsRequested()
    signal closed()
    function openConversation() {
        session.probe();
        if (handsFree.armed) { handsFree.disarm(); playback.cancel(); session.cancel(); return; }
        if (!handsFree.preferred) { composing = !composing; return; }
        sharing = true;
        Qt.callLater(() => { if (root.visible && root.sharing) handsFree.arm(); });
    }
    function stop() { handsFree.disarm(); playback.cancel(); session.cancel(); }
    onVisibleChanged: if (!visible) { stop(); sharing = false; composing = false; }
    onTargetChanged: { stop(); sharing = false; }
    VoiceSession {
        id: handsFree; objectName: "chat-hands-free"
        permitted: root.visible && root.sharing
        unlocked: root.sessionUnlocked
        paused: session.busy || playback.busy
        loadSavedSettings: root.loadVoiceSettings
        onTranscript: (text, traceParent) => { if (root.sharing && !session.busy) session.send(text, traceParent); }
        onMutedChanged: if (muted) { playback.cancel(); session.cancel(); }
    }
    VoicePlayback {
        id: playback; objectName: "chat-playback"
        loadSettings: root.loadVoiceSettings
        previewAllowed: root.visible && root.sessionUnlocked
        active: root.visible && root.sharing && handsFree.armed && !handsFree.muted && root.sessionUnlocked
    }
    ChatSession {
        id: session; objectName: "chat-session"
        active: root.visible && root.sharing && root.sessionUnlocked
        target: root.target; loadConfigStatus: root.loadVoiceSettings
        spoken: handsFree.armed
        onTurnStarted: playback.beginTurn()
        onAnswerDelta: text => playback.append(text, false)
        onTurnFinished: complete => { if (complete) playback.append("", true); else playback.cancel(); }
    }
    Rectangle {
        anchors.fill: parent; visible: root.expanded
        color: root.theme.surface; radius: root.theme.radius
        border.color: root.theme.line; border.width: 1
    }
    ColumnLayout {
        id: form; anchors { left: parent.left; right: parent.right; top: parent.top; margins: root.theme.gap }
        visible: root.expanded; spacing: root.theme.gap
        RowLayout {
            Layout.fillWidth: true
            Miilo.TypeText { typography: root.theme.typography; color: root.theme.foreground; text: "Miilo"; Layout.fillWidth: true }
            Miilo.ToolbarButton { theme: root.theme; kind: "settings"; label: "Voice settings"; onClicked: root.settingsRequested() }
            Controls.Action { context: root.context; text: "Hide"; onClicked: { root.composing = false; root.captions = false; session.dismissError(); playback.error = ""; handsFree.error = ""; } }
        }
        Miilo.TypeText {
            objectName: "chat-caption"; visible: root.captions; Layout.fillWidth: true
            typography: root.theme.typography; color: root.theme.foreground
            text: session.value("answer"); maximumLineCount: 3; elide: Text.ElideRight
        }
        Miilo.TypeText {
            Layout.fillWidth: true; visible: !!text
            typography: root.theme.typography; role: "small"; color: root.theme.foreground
            text: session.value("error") || playback.error || handsFree.error
        }
        Controls.Check {
            objectName: "chat-consent"; context: root.context; visible: root.composing
            text: "Share observed context and messages with my configured model"
            checked: root.sharing; onToggled: root.sharing = checked
        }
        RowLayout {
            visible: root.composing; Layout.fillWidth: true; spacing: root.theme.gap
            TextField {
                id: draft; objectName: "chat-draft"; Layout.fillWidth: true
                placeholderText: "Ask about your work"; color: root.theme.foreground
                placeholderTextColor: root.surface.widget.ink("muted")
                font.family: root.theme.typography.family; font.pixelSize: root.theme.typography.size("body")
                padding: root.theme.gap; enabled: !session.busy
                background: Rectangle { color: root.theme.inset; radius: root.theme.radius; border.color: root.theme.line; border.width: 1 }
                onAccepted: if (root.sharing && session.send(text)) text = ""
            }
            Controls.Action {
                objectName: "chat-send"; context: root.context; text: session.busy ? "Stop" : "Send"
                enabled: session.busy || (root.sessionUnlocked && root.sharing && draft.text.trim().length > 0)
                onClicked: { if (session.busy) session.cancel(); else if (session.send(draft.text)) draft.text = ""; }
            }
        }
    }
}
