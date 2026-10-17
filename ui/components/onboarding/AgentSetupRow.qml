pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import ".." as Miilo

ItemDelegate {
    id: root
    objectName: "setupRow"
    required property var agent
    required property var widget
    required property var theme
    property bool expanded: false
    readonly property bool supported: agent.observationSupported === true
    readonly property var locations: agent.locations || []
    Layout.fillWidth: true
    Layout.minimumWidth: 0
    implicitHeight: theme.typography.controlHeight(contentItem.implicitHeight, topPadding + bottomPadding)
    leftPadding: 8; rightPadding: 8; topPadding: 2.4; bottomPadding: 2.4
    activeFocusOnTab: true
    Accessible.name: agent.name + ". " + (supported ? "Sessions can be reviewed" : "Detected only") + ". " + (expanded ? "Hide locations" : "Show locations")
    onClicked: expanded = !expanded
    function displayPath(path) {
        var home = Quickshell.env("HOME") || "";
        return home && (path === home || path.indexOf(home + "/") === 0) ? "~" + path.slice(home.length) : path;
    }
    background: Rectangle {
        radius: 8
        color: root.down ? root.theme.pressedFill : root.activeFocus ? root.theme.focusFill : root.hovered ? root.theme.hoverFill : root.theme.selectedFill
        border.width: root.activeFocus ? 1 : 0
        border.color: root.theme.accent
    }
    contentItem: ColumnLayout {
        spacing: 2
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            RobotPortrait {
                objectName: "setupRobot"
                widget: root.widget
                agentKey: "setup-" + root.agent.name
                Layout.preferredWidth: 38; Layout.preferredHeight: 38
                Layout.alignment: Qt.AlignVCenter
                ink: root.widget.ink(root.supported ? "foreground" : "muted")
                accent: root.widget.ink(root.supported ? "accent" : "muted")
                expression: "ready"
                motion: "off"
            }
            GridLayout {
                Layout.fillWidth: true; Layout.minimumWidth: 0
                Layout.alignment: Qt.AlignVCenter
                columns: width < 320 * root.theme.typography.effectiveScale ? 1 : 2
                Miilo.TypeText {
                    objectName: "setupName"
                    typography: root.theme.typography
                    Layout.fillWidth: true; Layout.minimumWidth: 0
                    Layout.alignment: Qt.AlignVCenter
                    verticalAlignment: Text.AlignVCenter
                    text: root.agent.name
                    font.weight: Font.DemiBold
                    color: root.widget.ink(root.supported ? "foreground" : "muted")
                }
                RowLayout {
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 4
                    Miilo.AvailabilityIcon {
                        objectName: "setupStatus"
                        Layout.alignment: Qt.AlignVCenter
                        available: root.supported
                        ink: root.widget.ink(root.supported ? "accent" : "muted")
                        size: root.theme.typography.size("label") + 4
                    }
                    Miilo.TypeText {
                        objectName: "setupStatusLabel"
                        typography: root.theme.typography
                        Layout.alignment: Qt.AlignVCenter
                        verticalAlignment: Text.AlignVCenter
                        role: "label"
                        text: root.supported ? "Review available" : "Detected only"
                        color: root.widget.ink(root.supported ? "accent" : "muted")
                    }
                }
            }
            Miilo.TypeText {
                typography: root.theme.typography
                role: "title"
                text: root.expanded ? "−" : "+"
                color: root.widget.ink("muted")
                Layout.alignment: Qt.AlignVCenter
            }
        }
        Miilo.TypeText {
            typography: root.theme.typography
            objectName: "setupPath"
            visible: root.expanded
            Layout.fillWidth: true; Layout.minimumWidth: 0
            Layout.leftMargin: 46
            text: root.expanded ? (root.locations.length ? root.locations.map(p => root.displayPath(p)).join("\n") : "Installed command found") : ""
            role: "small"
            color: root.supported ? root.theme.pathText : root.widget.ink("muted")
            wrapMode: Text.WrapAnywhere
        }
        Miilo.TypeText {
            typography: root.theme.typography
            visible: root.expanded && !root.supported
            Layout.fillWidth: true; Layout.leftMargin: 46
            text: "Observation is not available for this agent yet."
            role: "small"
            color: root.widget.ink("muted")
        }
    }
}
