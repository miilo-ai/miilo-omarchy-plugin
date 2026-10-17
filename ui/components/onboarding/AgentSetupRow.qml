import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

ItemDelegate {
    id: root
    required property var agent
    required property var widget
    required property var theme
    property bool expanded: false
    readonly property var locations: agent.locations || []
    Layout.fillWidth: true
    implicitHeight: contentItem.implicitHeight + 12
    leftPadding: 8; rightPadding: 8; topPadding: 6; bottomPadding: 6
    activeFocusOnTab: true
    Accessible.name: agent.name + ". " + (agent.observationSupported ? "Sessions can be reviewed" : "Detected only") + ". " + (expanded ? "Hide locations" : "Show locations")
    onClicked: expanded = !expanded
    background: Rectangle {
        radius: 8
        color: root.down ? root.theme.pressedFill : root.activeFocus ? root.theme.focusFill : root.hovered ? root.theme.hoverFill : root.theme.selectedFill
        border.width: root.activeFocus ? 1 : 0
        border.color: root.theme.accent
    }
    contentItem: RowLayout {
        spacing: 10
        RobotPortrait {
            widget: root.widget
            agentKey: "setup-" + root.agent.name
            Layout.preferredWidth: 38
            Layout.preferredHeight: 38
            ink: root.widget.ink("foreground")
            accent: root.widget.ink(root.agent.observationSupported ? "accent" : "muted")
            expression: "ready"
            motion: "off"
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3
            RowLayout {
                Layout.fillWidth: true
                Text { Layout.fillWidth: true; text: root.agent.name; font.pixelSize: 14; font.weight: Font.DemiBold; color: root.widget.ink("foreground"); elide: Text.ElideRight }
                Text { text: root.agent.observationSupported ? "Review available" : "Detected only"; font.pixelSize: 11; color: root.widget.ink(root.agent.observationSupported ? "accent" : "muted") }
            }
            Text {
                Layout.fillWidth: true
                text: root.expanded ? (root.locations.length ? root.locations.map(p => p.replace(Quickshell.env("HOME"), "~")).join("\n") : "Installed command found") + (root.agent.observationSupported ? "" : "\nObservation is not available for this agent yet.") : root.locations.length ? root.locations.length + (root.locations.length === 1 ? " location · show details" : " locations · show details") : "Installed command · show details"
                font.pixelSize: 12
                color: root.widget.ink("muted")
                wrapMode: Text.WrapAnywhere
            }
        }
        Text { text: root.expanded ? "−" : "+"; font.pixelSize: 18; color: root.widget.ink("muted"); Layout.alignment: Qt.AlignVCenter }
    }
}
