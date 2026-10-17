pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import ".." as Miilo

ItemDelegate {
    id: root
    required property var agent
    required property var widget
    required property var theme
    property bool expanded: false
    readonly property bool supported: agent.observationSupported === true
    readonly property var locations: agent.locations || []
    Layout.fillWidth: true
    Layout.minimumWidth: 0
    implicitHeight: Math.max(theme.typography.touchTarget, contentItem.implicitHeight + 12)
    leftPadding: 8; rightPadding: 8; topPadding: 6; bottomPadding: 6
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
    contentItem: RowLayout {
        spacing: 10
        RobotPortrait {
            widget: root.widget
            agentKey: "setup-" + root.agent.name
            Layout.preferredWidth: 38; Layout.preferredHeight: 38
            ink: root.widget.ink(root.supported ? "foreground" : "muted")
            accent: root.widget.ink(root.supported ? "accent" : "muted")
            expression: "ready"
            motion: "off"
        }
        ColumnLayout {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            spacing: 3
            GridLayout {
                Layout.fillWidth: true
                columns: width < 320 * root.theme.typography.effectiveScale ? 1 : 2
                Miilo.TypeText {
                    typography: root.theme.typography
                    Layout.fillWidth: true; Layout.minimumWidth: 0
                    text: root.agent.name
                    font.weight: Font.DemiBold
                    color: root.widget.ink(root.supported ? "foreground" : "muted")
                }
                RowLayout {
                    Miilo.AvailabilityIcon {
                        objectName: "setupStatus"
                        available: root.supported
                        ink: root.widget.ink(root.supported ? "accent" : "muted")
                        size: root.theme.typography.size("label") + 4
                    }
                    Miilo.TypeText {
                        typography: root.theme.typography
                        role: "label"
                        text: root.supported ? "Review available" : "Detected only"
                        color: root.widget.ink(root.supported ? "accent" : "muted")
                    }
                }
            }
            Miilo.TypeText {
                typography: root.theme.typography
                objectName: "setupPath"
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                text: root.expanded ? (root.locations.length ? root.locations.map(p => root.displayPath(p)).join("\n") : "Installed command found") + (root.supported ? "" : "\nObservation is not available for this agent yet.") : root.locations.length ? root.locations.length + (root.locations.length === 1 ? " location · show details" : " locations · show details") : "Installed command · show details"
                role: "small"
                color: root.expanded && root.supported ? root.theme.pathText : root.widget.ink("muted")
                wrapMode: Text.WrapAnywhere
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
}
