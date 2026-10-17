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
        color: context.widget.ink(scroll.pressed ? "accent" : "muted")
        opacity: scroll.active ? 1 : 0.5
    }
    background: Rectangle { color: context.widget.ink("dark_background") }
}
