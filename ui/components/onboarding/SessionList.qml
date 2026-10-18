pragma ComponentBehavior: Bound
import QtQuick
import ".." as Miilo
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "controls" as Controls

ListView {
    id: view
    required property var controller
    required property var widget
    required property var theme
    readonly property var context: view
    readonly property bool desktop: theme.typography.profile !== "phone"
    objectName: "sessionList"
    Layout.fillWidth: true
    Layout.fillHeight: true
    clip: true
    spacing: desktop ? 0 : 4
    model: controller.rows
    activeFocusOnTab: true
    keyNavigationEnabled: true
    highlightMoveDuration: 0
    Keys.onSpacePressed: controller.activateRow(currentIndex)
    Keys.onReturnPressed: {
        var row = controller.rows[currentIndex];
        if (row && row.header) controller.collapseGroup(row.group); else controller.activateRow(currentIndex);
    }
    Keys.onLeftPressed: { var row = controller.rows[currentIndex]; if (row) controller.collapseGroup(row.group,true); }
    Keys.onRightPressed: { var row = controller.rows[currentIndex]; if (row) controller.collapseGroup(row.group,false); }
    delegate: ItemDelegate {
        id: choice
        required property var modelData
        required property int index
        enabled: modelData.header || modelData.session.observable === true
        width: ListView.view.width
        Accessible.role: modelData.header ? Accessible.Grouping : Accessible.CheckBox
        Accessible.checkable: selectable
        Accessible.checked: checked
        focusPolicy: Qt.NoFocus
        readonly property var groupSessions: controller.grouped[modelData.group] ? controller.grouped[modelData.group].sessions.filter(s => s.observable) : []
        readonly property string sessionContext: {
            if (modelData.header) return "";
            var session = modelData.session;
            var group = controller.grouped[modelData.group];
            var location = session.cwd || session.id;
            var repeated = group && !group.rule && group.name === session.kind + " / " + location;
            var detail = repeated ? "" : session.kind + " · " + location;
            return detail + (session.observable ? "" : (detail ? " · " : "") + "Import not available yet");
        }
        readonly property bool selectable: modelData.header ? groupSessions.length > 0 : modelData.session.observable === true
        readonly property int selectedCount: groupSessions.filter(s => controller.selected.indexOf(s.kind + ":" + s.id) >= 0).length
        readonly property bool partial: modelData.header && selectedCount > 0 && selectedCount < groupSessions.length
        readonly property bool cursor: view.activeFocus && view.currentIndex === index
        checked: modelData.header ? groupSessions.length > 0 && groupSessions.every(s => controller.selected.indexOf(s.kind + ":" + s.id) >= 0) : controller.selected.indexOf(modelData.session.kind + ":" + modelData.session.id) >= 0
        onClicked: { view.currentIndex = index; view.forceActiveFocus(); controller.activateRow(view.currentIndex); }
        leftPadding: modelData.header ? (view.desktop ? 6 : 8) : (view.desktop ? 44 : 64)
        rightPadding: view.desktop ? 32 : 36
        topPadding: view.desktop ? 1 : 3.2; bottomPadding: topPadding
        topInset: 0; bottomInset: 0
        implicitHeight: view.theme.typography.controlHeight(contentItem.implicitHeight, topPadding + bottomPadding)
        background: Rectangle {
            color: choice.down ? view.theme.pressedFill : choice.cursor ? view.theme.focusFill : choice.checked || choice.partial ? view.theme.selectedFill : choice.hovered ? view.theme.hoverFill : choice.modelData.header ? view.widget.ink("lighter_background") : "transparent"
            Rectangle { anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; width: 3; height: Math.min(24, parent.height - 4); visible: choice.cursor; color: view.theme.accent }
        }
        Rectangle {
            objectName: "sessionCheckbox"
            anchors.right: parent.right
            anchors.rightMargin: view.desktop ? 14 : 10
            anchors.verticalCenter: parent.verticalCenter
            width: view.desktop ? 12 : 16
            height: width
            visible: choice.selectable
            radius: 0
            color: "transparent"
            border.width: 1
            border.color: view.widget.ink(choice.modelData.header || choice.modelData.session.observable ? "foreground" : "muted")
            Rectangle {
                anchors.centerIn: parent
                width: view.desktop ? 6 : 8
                height: choice.partial ? 2 : width
                visible: choice.checked || choice.partial
                color: view.theme.accent
            }
        }
        Miilo.AvailabilityIcon {
            anchors.right: parent.right
            anchors.rightMargin: view.desktop ? 14 : 10
            anchors.verticalCenter: parent.verticalCenter
            size: view.desktop ? 12 : 16
            visible: !choice.selectable
            available: false
            ink: view.widget.ink("muted")
        }
        contentItem: RowLayout {
            spacing: view.desktop ? 6 : 8
            RobotPortrait {
                objectName: "groupRobot"
                widget: view.widget
                agentKey: "group-" + choice.modelData.name
                visible: choice.modelData.header
                Layout.preferredWidth: view.desktop ? 24 : 32; Layout.preferredHeight: view.desktop ? 24 : 32
                Layout.alignment: Qt.AlignVCenter
                ink: view.widget.ink("foreground")
                accent: view.widget.ink("accent")
                motion: "off"
            }
            ColumnLayout {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                Layout.alignment: Qt.AlignVCenter
                spacing: 2
                Miilo.TypeText {
                    objectName: "sessionTitle"
                    typography: view.theme.typography
                    Layout.fillWidth: true; Layout.minimumWidth: 0
                    text: choice.modelData.header ? (choice.modelData.label || choice.modelData.name) + " (" + choice.modelData.count + ")" : choice.modelData.session.name || "Unnamed session"
                    wrapMode: Text.Wrap
                    verticalAlignment: Text.AlignVCenter
                    color: !choice.selectable ? view.widget.ink("muted") : choice.cursor ? view.theme.focusText : view.theme.foreground
                    lineHeight: view.desktop ? 1.15 : view.theme.typography.leading("body")
                    role: view.desktop ? "small" : "body"
                    font.weight: choice.modelData.header ? Font.DemiBold : Font.Normal
                }
                Miilo.TypeText {
                    typography: view.theme.typography
                    objectName: "sessionContext"
                    visible: choice.sessionContext !== ""
                    Layout.fillWidth: true; Layout.minimumWidth: 0
                    text: choice.sessionContext
                    wrapMode: Text.WrapAnywhere
                    color: view.widget.ink("muted")
                    role: "small"
                }
            }
        }
    }
    ScrollBar.vertical: Controls.ThemeScrollBar { context: view;}
}
