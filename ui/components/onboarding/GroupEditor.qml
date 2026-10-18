pragma ComponentBehavior: Bound
import QtQuick
import ".." as Miilo
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "controls" as Controls

ScrollView {
    id: view
    objectName: "agentGroupEditor"
    required property var controller
    required property var widget
    required property var theme
    readonly property var context: view
    readonly property var agentKinds: ["all", "codex", "cursor", "opencode", "devin", "claude"]
    function focusEditor() { groupName.forceActiveFocus() }
    function rule() { return {name:groupName.text.trim(),folder:groupFolder.text.trim(),pattern:groupPattern.text.trim(),kind:view.agentKinds[groupKind.currentIndex],future:futureMatches.checked} }
    Layout.fillWidth: true
    Layout.fillHeight: true
    contentWidth: availableWidth
    ScrollBar.vertical: Controls.ThemeScrollBar { context: view;}
    ColumnLayout {
        width: parent.width
        spacing: 12
        Controls.Field { context: view; id: groupName; objectName: "groupName"; text: view.controller.draft.name || ""; placeholderText: "Group name"; Accessible.name: "Group name" }
        Controls.Field { context: view; id: groupFolder; objectName: "groupFolder"; text: view.controller.draft.folder || ""; placeholderText: "Absolute folder, e.g. /home/me/Work"; Accessible.name: "Group folder" }
        Controls.Field { context: view; id: groupPattern; objectName: "groupPattern"; text: view.controller.draft.pattern || ""; placeholderText: "Project pattern (blank matches all)"; Accessible.name: "Project pattern" }
        Controls.Choice { context: view; id: groupKind; objectName: "groupKind"; currentIndex: Math.max(0, view.agentKinds.indexOf(view.controller.draft.kind || "all")); model: ["All supported agents", "Codex", "Cursor", "OpenCode", "Devin CLI", "Claude Code"]; Accessible.name: "Agent type" }
        CheckBox {
            id: futureMatches
            objectName: "futureMatches"
            checked: !!view.controller.draft.future; text: "Include future matching sessions"
            Layout.fillWidth: true
            focusPolicy: Qt.StrongFocus
            indicator: Rectangle {
                implicitWidth: 20
                implicitHeight: 20
                anchors.verticalCenter: parent.verticalCenter
                color: view.widget.ink("background")
                border.width: futureMatches.activeFocus ? 2 : 1
                border.color: view.widget.ink(futureMatches.activeFocus ? "accent" : "foreground")
                Rectangle {
                    anchors.centerIn: parent
                    width: 10; height: 10
                    visible: futureMatches.checked
                    color: view.widget.ink("accent")
                }
            }
            contentItem: Miilo.TypeText { typography: view.theme.typography; leftPadding: 32; text: futureMatches.text; color: view.widget.ink(futureMatches.activeFocus ? "accent" : "foreground"); wrapMode: Text.WordWrap }
        }
        Miilo.TypeText { typography: view.theme.typography;
            Layout.fillWidth: true
            text: "Off by default. When enabled, Miilo checks every minute and enrolls new matching sessions, up to 100 total. Unchecking this on a later import stops future enrollment; existing selections remain."
            wrapMode: Text.WordWrap
            color: view.widget.ink("muted")
        }
    }
}
