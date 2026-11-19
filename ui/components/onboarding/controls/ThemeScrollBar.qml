pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ScrollBar {
    required property var context
    id: scroll
    contentItem: Rectangle {
        implicitWidth: 6
        implicitHeight: 6
        color: scroll.pressed ? context.theme.accent : context.theme.border
        opacity: scroll.active ? 1 : 0.5
    }
    background: Rectangle { color: context.theme.inset }
}
