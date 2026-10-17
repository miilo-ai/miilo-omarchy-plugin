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
    objectName: "sessionList"
    Layout.fillWidth: true
    Layout.fillHeight: true
    clip: true
    spacing: 4
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
        readonly property bool selectable: modelData.header ? groupSessions.length > 0 : modelData.session.observable === true
        readonly property int selectedCount: groupSessions.filter(s => controller.selected.indexOf(s.kind + ":" + s.id) >= 0).length
        readonly property bool partial: modelData.header && selectedCount > 0 && selectedCount < groupSessions.length
        readonly property bool cursor: view.activeFocus && view.currentIndex === index
        checked: modelData.header ? groupSessions.length > 0 && groupSessions.every(s => controller.selected.indexOf(s.kind + ":" + s.id) >= 0) : controller.selected.indexOf(modelData.session.kind + ":" + modelData.session.id) >= 0
        onClicked: { view.currentIndex = index; view.forceActiveFocus(); controller.activateRow(view.currentIndex); }
        leftPadding: modelData.header ? 8 : 64
        rightPadding: 36
        topPadding: 3.2; bottomPadding: 3.2
        implicitHeight: view.theme.typography.controlHeight(contentItem.implicitHeight, topPadding + bottomPadding)
        background: Rectangle {
            color: choice.down ? view.theme.pressedFill : choice.cursor ? view.theme.focusFill : choice.checked || choice.partial ? view.theme.selectedFill : choice.hovered ? view.theme.hoverFill : choice.modelData.header ? view.widget.ink("lighter_background") : "transparent"
            Rectangle { anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; width: 3; height: 24; visible: choice.cursor; color: view.theme.accent }
        }
        Rectangle {
            objectName: "sessionCheckbox"
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            width: 16
            height: 16
            visible: choice.selectable
            radius: 0
            color: "transparent"
            border.width: 1
            border.color: view.widget.ink(choice.modelData.header || choice.modelData.session.observable ? "foreground" : "muted")
            Rectangle {
                anchors.centerIn: parent
                width: 8
                height: choice.partial ? 2 : 8
                visible: choice.checked || choice.partial
                color: view.theme.accent
            }
        }
        Miilo.AvailabilityIcon {
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            size: 16
            visible: !choice.selectable
            available: false
            ink: view.widget.ink("muted")
        }
        contentItem: RowLayout {
            spacing: 8
            RobotPortrait {
                objectName: "groupRobot"
                widget: view.widget
                agentKey: "group-" + choice.modelData.name
                visible: choice.modelData.header
                Layout.preferredWidth: 32; Layout.preferredHeight: 32
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
                    text: choice.modelData.header ? choice.modelData.name + " (" + choice.modelData.count + ")" : choice.modelData.session.name || "Unnamed session"
                    wrapMode: Text.Wrap
                    verticalAlignment: Text.AlignVCenter
                    color: !choice.selectable ? view.widget.ink("muted") : choice.cursor ? view.theme.focusText : view.theme.foreground
                    role: "body"
                }
                Miilo.TypeText {
                    typography: view.theme.typography
                    visible: !choice.modelData.header
                    Layout.fillWidth: true; Layout.minimumWidth: 0
                    text: choice.modelData.header ? "" : choice.modelData.session.kind + " · " + (choice.modelData.session.cwd || choice.modelData.session.id) + (choice.modelData.session.observable ? "" : " · import not available yet")
                    wrapMode: Text.WrapAnywhere
                    color: view.widget.ink("muted")
                    role: "small"
                }
            }
        }
    }
    ScrollBar.vertical: Controls.ThemeScrollBar { context: view;}
}
