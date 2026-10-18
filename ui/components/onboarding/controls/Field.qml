pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

TextField {
    required property var context
    id: field
    Layout.minimumWidth: 0
    Layout.preferredWidth: 180
    Layout.fillWidth: true
    color: context.widget.ink("foreground")
    placeholderTextColor: context.widget.ink("muted")
    selectionColor: context.theme.selectionFill
    selectedTextColor: context.widget.ink("foreground")
    font.family: context.theme.typography.family
    font.pixelSize: context.theme.typography.size("body")
    implicitHeight: context.theme.typography.controlHeight(contentHeight, topPadding + bottomPadding)
    topPadding: 2
    bottomPadding: 2
    selectByMouse: true
    background: Rectangle {
        color: field.activeFocus ? context.theme.focusFill : context.widget.ink("lighter_background")
        border.color: context.theme.border
        border.width: 1
        Rectangle { anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter; width: parent.width - 12; height: 2; visible: field.activeFocus; color: context.theme.accent }
    }
}
