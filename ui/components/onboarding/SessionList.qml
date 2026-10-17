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
        implicitHeight: Math.max(view.theme.typography.touchTarget, contentItem.implicitHeight + 16)
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
            contentItem: Miilo.TypeText { typography: view.theme.typography; text: foldButton.text; color: view.widget.ink("foreground"); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
            background: Rectangle { color: view.widget.ink(foldButton.hovered ? "selection" : "lighter_background") }
            onClicked: controller.collapseGroup(choice.modelData.group)
        }
        Rectangle {
            x: 10
            anchors.verticalCenter: parent.verticalCenter
            width: 20
            height: 20
            visible: choice.selectable
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
        Miilo.AvailabilityIcon {
            x: 8
            anchors.verticalCenter: parent.verticalCenter
            visible: !choice.selectable
            available: false
            ink: view.widget.ink("muted")
        }
        contentItem: Column {
            leftPadding: 42
            spacing: 3
            Miilo.TypeText { typography: view.theme.typography;
                width: parent.width - (choice.modelData.header ? 76 : 32)
                text: choice.modelData.header ? (controller.collapsed[choice.modelData.name] ? "▸ " : "▾ ") + choice.modelData.name + " (" + choice.modelData.count + ")" : choice.modelData.session.name || "Unnamed session"
                wrapMode: Text.Wrap
                color: !choice.selectable ? view.widget.ink("muted") : choice.cursor ? view.theme.focusText : view.theme.foreground
                role: "body"
            }
            Miilo.TypeText { typography: view.theme.typography;
                visible: !choice.modelData.header
                width: parent.width - 32
                text: choice.modelData.header ? "" : choice.modelData.session.kind + " · " + (choice.modelData.session.cwd || choice.modelData.session.id) + (choice.modelData.session.observable ? "" : " · import not available yet")
                wrapMode: Text.WrapAnywhere
                color: view.widget.ink("muted")
                role: "small"
            }
        }
    }
    ScrollBar.vertical: Controls.ThemeScrollBar { context: view;}
}
