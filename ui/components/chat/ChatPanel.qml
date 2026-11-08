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
    readonly property var context: ({theme: theme, widget: surface.widget})
    signal closed()
    Keys.onEscapePressed: { voice.cancel(); root.closed(); }
    onVisibleChanged: if (!visible) { consent.checked = false; voice.cancel(); }
    onTargetChanged: { consent.checked = false; voice.cancel(); }
    Rectangle { anchors.fill: parent; color: root.surface.widget.ink("background") }
    ChatSession { id: session; objectName: "chat-session"; active: root.visible; target: root.target }
    Shortcut { sequence: "Ctrl+Shift+D"; enabled: root.visible && !session.busy; onActivated: voice.recording ? voice.stop() : voice.start() }
    Miilo.NativeDictation {
        id: voice
        objectName: "native-dictation"
        active: root.visible && !session.busy
        focusSafe: draft.activeFocus && Window.active
        onFocusRequested: draft.forceActiveFocus()
    }
    ColumnLayout {
        anchors.fill: parent; anchors.margins: root.theme.gap * 2; spacing: root.theme.gap * 1.5
        RowLayout {
            Miilo.ToolbarButton { theme: root.theme; kind: "back"; label: "Back to overview"; onClicked: root.closed() }
            Miilo.TypeText { typography: root.theme.typography; text: "Ask Miilo"; color: root.theme.foreground; Layout.fillWidth: true; font.weight: Font.DemiBold }
        }
        Miilo.TypeText {
            typography: root.theme.typography; role: "small"; color: root.theme.foreground
            Layout.fillWidth: true
            text: root.target ? "Discuss the selected work with your configured model. Replies are advice; they cannot control an agent." : "Discuss your observed work with your configured model. Replies are advice; they cannot control an agent."
        }
        ScrollView {
            id: conversation
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
        CheckBox {
            id: consent
            objectName: "chat-consent"
            enabled: !session.busy
            text: "Share observed context and messages with my configured model"
            contentItem: Miilo.TypeText {
                typography: root.theme.typography; role: "small"; color: root.theme.foreground
                text: consent.text; leftPadding: consent.indicator.width + 6
            }
        }
        TextArea {
            id: draft
            objectName: "chat-draft"
            Layout.fillWidth: true; Layout.preferredHeight: 80
            enabled: !session.busy
            wrapMode: TextEdit.Wrap; textFormat: TextEdit.PlainText
            selectByMouse: true; color: root.theme.foreground
            placeholderText: "Ask about your work"
            placeholderTextColor: root.theme.foreground
            font.family: root.theme.typography.family
            font.pixelSize: root.theme.typography.size("body")
            Accessible.name: "Message to Miilo"
            background: Rectangle { color: root.theme.secondaryFill; border.width: 1; border.color: root.theme.border; radius: 4 }
        }
        RowLayout {
            Layout.fillWidth: true
            Miilo.ToolbarButton {
                theme: root.theme; kind: voice.recording ? "stop" : "voice"
                circular: true; selected: voice.owned
                implicitWidth: 32; implicitHeight: 32; padding: 8
                label: voice.recording ? "Stop dictation" : "Dictate with Superwhisper"
                focusPolicy: Qt.NoFocus
                enabled: voice.recording || (voice.ready && !voice.busy && !voice.owned && !session.busy)
                onClicked: voice.recording ? voice.stop() : voice.start()
            }
            Miilo.TypeText { typography: root.theme.typography; role: "small"; color: root.theme.foreground; text: voice.message; Layout.fillWidth: true }
            Controls.Action { context: root.context; visible: voice.owned; text: "Cancel"; focusPolicy: Qt.NoFocus; onClicked: voice.cancel() }
            Miilo.ToolbarButton { theme: root.theme; kind: "menu"; label: "Superwhisper settings"; onClicked: voice.settings() }
            Controls.Action { context: root.context; text: "Recheck"; visible: !voice.ready; enabled: !voice.busy && !voice.owned; onClicked: voice.probe() }
        }
        RowLayout {
            Layout.alignment: root.surface.viewValue("leftHanded") === true ? Qt.AlignLeft : Qt.AlignRight
            Controls.Action { context: root.context; text: "New conversation"; enabled: !session.busy && !voice.owned; onClicked: { session.reset(); consent.checked = false; } }
            Controls.Action {
                objectName: "chat-send"
                context: root.context; text: session.busy ? "Stop waiting" : "Send"; primary: true
                enabled: session.busy || (consent.checked && draft.text.trim().length > 0 && !voice.owned && !voice.pendingStart)
                onClicked: { if (session.busy) session.cancel(); else if (session.send(draft.text)) draft.text = ""; }
            }
        }
    }
}
