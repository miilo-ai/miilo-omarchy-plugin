pragma ComponentBehavior: Bound
import QtQuick
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
        width: ListView.view.width
        focusPolicy: Qt.NoFocus
        readonly property var groupSessions: controller.grouped[modelData.group] ? controller.grouped[modelData.group].sessions.filter(s => s.observable) : []
        readonly property int selectedCount: groupSessions.filter(s => controller.selected.indexOf(s.kind + ":" + s.id) >= 0).length
        readonly property bool partial: modelData.header && selectedCount > 0 && selectedCount < groupSessions.length
        readonly property bool cursor: view.activeFocus && view.currentIndex === index
        checked: modelData.header ? groupSessions.length > 0 && groupSessions.every(s => controller.selected.indexOf(s.kind + ":" + s.id) >= 0) : controller.selected.indexOf(modelData.session.kind + ":" + modelData.session.id) >= 0
        onClicked: { view.currentIndex = index; view.forceActiveFocus(); controller.activateRow(view.currentIndex); }
        implicitHeight: modelData.header ? 52 : 60
        background: Rectangle {
            color: choice.down ? view.theme.pressedFill : choice.cursor ? view.theme.focusFill : choice.checked || choice.partial ? view.theme.selectedFill : choice.hovered ? view.theme.hoverFill : choice.modelData.header ? view.widget.ink("lighter_background") : "transparent"
            Rectangle { anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; width: 3; height: 24; visible: choice.cursor; color: view.theme.accent }
        }
        ToolButton {
            id: foldButton
            visible: choice.modelData.header
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: controller.collapsed[choice.modelData.name] ? "+" : "−"
            Accessible.name: "Expand or collapse " + choice.modelData.name
            focusPolicy: Qt.NoFocus
            contentItem: Text { text: foldButton.text; color: view.widget.ink("foreground"); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
            background: Rectangle { color: view.widget.ink(foldButton.hovered ? "selection" : "lighter_background") }
            onClicked: controller.collapseGroup(choice.modelData.group)
        }
        Rectangle {
            x: 10
            anchors.verticalCenter: parent.verticalCenter
            width: 20
            height: 20
            radius: 0
            color: "transparent"
            border.width: 1
            border.color: view.widget.ink(choice.modelData.header || choice.modelData.session.observable ? "foreground" : "muted")
            Rectangle {
                anchors.centerIn: parent
                width: 10
                height: choice.partial ? 2 : 10
                visible: choice.checked || choice.partial
                color: view.theme.accent
            }
        }
        RobotPortrait {
            visible: choice.modelData.header
            anchors.left: parent.left
            anchors.leftMargin: 38
            anchors.verticalCenter: parent.verticalCenter
            width: 32
            height: 32
            ink: view.widget.ink("foreground")
            accent: view.widget.ink("accent")
            motion: "off"
        }
        contentItem: Column {
            leftPadding: choice.modelData.header ? 82 : 42
            spacing: 3
            Text {
                width: parent.width - (choice.modelData.header ? 76 : 32)
                text: choice.modelData.header ? choice.modelData.name + " (" + choice.modelData.count + ")" : choice.modelData.session.name || "Unnamed session"
                elide: Text.ElideRight
                color: choice.cursor ? view.theme.focusText : view.theme.foreground
                font.pixelSize: 14
            }
            Text {
                visible: !choice.modelData.header
                width: parent.width - 32
                text: choice.modelData.header ? "" : choice.modelData.session.kind + " · " + (choice.modelData.session.cwd || choice.modelData.session.id) + (choice.modelData.session.observable ? "" : " · import not available yet")
                elide: Text.ElideMiddle
                color: view.widget.ink("muted")
                font.pixelSize: 11
            }
        }
    }
    ScrollBar.vertical: Controls.ThemeScrollBar { context: view;}
}
