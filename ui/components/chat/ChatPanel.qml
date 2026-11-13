import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".." as Miilo
import "../onboarding/controls" as Controls

FocusScope {
    id: root
    required property var theme
    required property var surface
    property var target: null
    property bool sessionUnlocked: false
    property bool loadVoiceSettings: true
    property alias handsFree: handsFree
    VoiceSession {
        id: handsFree
        objectName: "chat-hands-free"
        permitted: root.visible && consent.checked
        unlocked: root.sessionUnlocked
        paused: session.busy || voice.owned
        loadSavedSettings: root.loadVoiceSettings
        onTranscript: text => { if (consent.checked && !session.busy) session.send(text); }
    }
    VoiceOptions {
        id: voiceOptions; objectName: "chat-voice-options"; parent: root
        context: root.context; voice: handsFree; consent: consent.checked
        onProviderSettingsRequested: voice.settings()
        onEnableRequested: { consent.checked = true; Qt.callLater(() => handsFree.arm()); }
    }
    readonly property var context: ({theme: theme, widget: surface.widget})
    signal closed()
    Keys.onEscapePressed: { voice.cancel(); root.closed(); }
    onVisibleChanged: if (!visible) { handsFree.disarm(); consent.checked = false; voice.cancel(); }
    onTargetChanged: { handsFree.disarm(); consent.checked = false; voice.cancel(); }
    ChatSession { id: session; objectName: "chat-session"; active: root.visible; target: root.target }
    Shortcut { sequence: "Ctrl+Shift+D"; enabled: root.visible && !session.busy && !handsFree.armed; onActivated: voice.recording ? voice.stop() : voice.start() }
    Miilo.NativeDictation {
        id: voice
        objectName: "native-dictation"
        active: root.visible && !session.busy && !handsFree.armed
        focusSafe: draft.activeFocus && Window.active
        onFocusRequested: draft.forceActiveFocus()
    }
    ColumnLayout {
        anchors.fill: parent; anchors.margins: root.theme.gap * 2; spacing: root.theme.gap
        RowLayout {
            Miilo.ToolbarButton { id: back; objectName:"chat-back";theme: root.theme; kind: "back"; label: "Back to overview"; onClicked: root.closed() }
            Miilo.TypeText {objectName:"chat-title";typography: root.theme.typography; text: "Ask Miilo"; color: root.theme.foreground; Layout.fillWidth: true;Layout.preferredHeight:back.implicitHeight;verticalAlignment:Text.AlignVCenter;lineHeight:1;font.weight: Font.DemiBold }
        }
        Miilo.TypeText {
            typography: root.theme.typography; role: "small"; color: root.theme.foreground
            Layout.fillWidth: true
            text: root.target ? "Discuss the selected work with your configured model. Replies are advice; they cannot control an agent." : "Discuss your observed work with your configured model. Replies are advice; they cannot control an agent."
        }
        ScrollView {
            id: conversation
            objectName: "chat-conversation"
            visible: session.value("history").length > 0 || session.busy || !!session.value("answer") || !!session.value("error") || !!session.value("context")
            Layout.fillWidth: true; Layout.fillHeight: true; clip: true
            contentWidth: availableWidth
            ColumnLayout {
                width: conversation.availableWidth; spacing: 10
                Repeater {
                    model: session.value("history")
                    Miilo.TypeText {
                        required property var modelData
                        typography: root.theme.typography; color: root.theme.foreground
                        Layout.fillWidth: true
                        text: (modelData.role === "user" ? "You: " : "Miilo: ") + modelData.text
                    }
                }
                Miilo.TypeText {
                    typography: root.theme.typography; color: root.theme.foreground; Layout.fillWidth: true
                    visible: session.value("phase") !== "done"
                    text: session.value("answer") || (session.busy ? "Waiting for your model…" : "")
                }
                Miilo.TypeText {
                    typography: root.theme.typography; role: "small"; color: root.theme.foreground; Layout.fillWidth: true
                    text: session.value("context") ? "Context: " + session.value("context").status + " · " + session.value("context").references.length + " references · " + session.value("context").omitted + " omitted" : ""
                }
                Miilo.TypeText {
                    typography: root.theme.typography; role: "small"; color: root.theme.foreground
                    Layout.fillWidth: true; text: session.value("error")
                }
            }
        }
        Controls.Check {
            id: consent
            objectName: "chat-consent"
            context: root.context
            textRole: "small"
            Layout.fillWidth: true
            enabled: !session.busy
            text: "Share observed context and messages with my configured model"
        }
        TextArea {
            id: draft
            objectName: "chat-draft"
            Layout.fillWidth: true; Layout.preferredHeight: 80
            enabled: !session.busy
            wrapMode: TextEdit.Wrap; textFormat: TextEdit.PlainText
            selectByMouse: true; color: root.theme.foreground
            placeholderText: "Ask about your work"
            placeholderTextColor: root.surface.widget.ink("muted")
            padding: root.theme.gap
            selectionColor: root.theme.selectionFill
            selectedTextColor: root.theme.foreground
            font.family: root.theme.typography.family
            font.pixelSize: root.theme.typography.size("body")
            Accessible.name: "Message to Miilo"
            background: Rectangle { color: root.theme.inset; border.width: 1; border.color: draft.activeFocus ? root.theme.accent : root.theme.line; radius: root.theme.radius }
        }
        RowLayout {
            id: dictationRow
            objectName: "chat-dictation-row"
            Layout.fillWidth: true
            spacing: root.theme.gap
            Miilo.ToolbarButton {
                id: dictationButton
                objectName: "chat-dictation-button"
                theme: root.theme; kind: handsFree.armed && handsFree.muted ? "muted" : voice.recording ? "stop" : "voice"
                circular: true; selected: voice.owned
                implicitWidth: 32; implicitHeight: 32; padding: 8
                label: handsFree.armed ? (handsFree.muted ? "Unmute microphone" : "Mute microphone") : voice.recording ? "Stop dictation" : "Dictate with Superwhisper"
                focusPolicy: Qt.NoFocus
                enabled: handsFree.armed || voice.recording || (voice.ready && !voice.busy && !voice.owned && !session.busy)
                onClicked: handsFree.armed ? handsFree.toggleMute() : voice.recording ? voice.stop() : voice.start()
            }
            Miilo.TypeText {
                objectName: "chat-dictation-status"
                typography: root.theme.typography; role: "small"; color: root.theme.foreground
                text: handsFree.armed || handsFree.error ? handsFree.message : voice.message
                Layout.fillWidth: true
                Layout.minimumHeight: dictationButton.implicitHeight
                verticalAlignment: Text.AlignVCenter
                lineHeight: 1
            }
            Controls.Action { context: root.context; visible: voice.owned; text: "Cancel"; focusPolicy: Qt.NoFocus; onClicked: voice.cancel() }
            Miilo.ToolbarButton { objectName: "chat-dictation-settings"; theme: root.theme; kind: "settings"; label: "Voice settings"; onClicked: voiceOptions.open() }
            Controls.Action { context: root.context; text: "Recheck"; visible: !voice.ready; enabled: !voice.busy && !voice.owned; onClicked: voice.probe() }
        }
        RowLayout {
            id: commands
            objectName: "chat-commands"
            Layout.alignment: root.surface.viewValue("leftHanded") === true ? Qt.AlignLeft : Qt.AlignRight
            Controls.Action { context: root.context; text: "New conversation"; enabled: !session.busy && !voice.owned; onClicked: { session.reset(); consent.checked = false; } }
            Controls.Action {
                objectName: "chat-send"
                context: root.context; text: session.busy ? "Stop waiting" : "Send"; primary: true
                enabled: session.busy || (consent.checked && draft.text.trim().length > 0 && !voice.owned && !voice.pendingStart)
                onClicked: { if (session.busy) session.cancel(); else if (session.send(draft.text)) draft.text = ""; }
            }
        }
        Item { Layout.fillHeight: true; visible: !conversation.visible }
    }
}
