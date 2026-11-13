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
    implicitHeight: Math.max(context.theme.controlHeight, context.theme.typography.controlHeight(contentHeight, topPadding + bottomPadding))
    leftPadding: context.theme.gap
    rightPadding: context.theme.gap
    topPadding: 2
    bottomPadding: 2
    selectByMouse: true
    background: Rectangle {
        color: context.theme.inset
        radius: context.theme.radius
        border.color: field.activeFocus ? context.theme.accent : context.theme.line
        border.width: 1
    }
}
