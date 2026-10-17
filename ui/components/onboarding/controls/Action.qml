pragma ComponentBehavior: Bound
import QtQuick
import "../.." as Miilo
import QtQuick.Controls
import QtQuick.Layouts

Button {
    required property var context
    Layout.minimumWidth: 0
    Layout.preferredWidth: 180
    Layout.fillWidth: true
    id: control
    implicitHeight: context.theme.typography.controlHeight(contentItem.implicitHeight, 8)
    horizontalPadding: 14
    flat: true
    verticalPadding: 4
    focusPolicy: Qt.StrongFocus
    Keys.onReturnPressed: clicked()
    Keys.onEnterPressed: clicked()
    background: Rectangle {
        color: control.down ? context.theme.pressedFill : control.activeFocus ? context.theme.focusFill : control.hovered && control.enabled ? context.theme.hoverFill : "transparent"
        border.color: context.theme.border
        border.width: 1
        radius: 0
        opacity: control.enabled ? 1 : 0.5
        Rectangle { anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter; width: parent.width - 16; height: 2; visible: control.activeFocus; color: context.theme.accent }
    }
    contentItem: Miilo.TypeText { typography: context.theme.typography;
        text: control.text
        color: control.activeFocus ? context.theme.focusText : context.theme.foreground
        opacity: control.enabled ? 1 : 0.5
        role: "label"
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
}
