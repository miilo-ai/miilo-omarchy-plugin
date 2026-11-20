pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import "../.." as Miilo

CheckBox {
    id: control
    required property var context
    property string textRole: "body"
    padding: 0
    spacing: context.theme.gap
    implicitHeight: Math.max(context.theme.controlHeight, contentItem.implicitHeight)
    indicator: Rectangle {
        implicitWidth: 14; implicitHeight: 14
        x: control.leftPadding; y: Math.round((control.height - height) / 2)
        radius: 2
        color: control.checked ? control.context.theme.selectedFill : control.context.theme.inset
        border.width: 1
        border.color: control.activeFocus || control.checked ? control.context.theme.accent : control.context.theme.line
        Miilo.TypeText {
            anchors.centerIn: parent
            typography: control.context.theme.typography
            text: control.checked ? "✓" : ""
            font.pixelSize: 12; lineHeight: 1
            color: control.context.theme.foreground
        }
    }
    contentItem: Miilo.TypeText {
        typography: control.context.theme.typography; role: control.textRole
        text: control.text; color: control.context.theme.foreground
        leftPadding: control.indicator.width + control.spacing
        verticalAlignment: Text.AlignVCenter
        opacity: control.enabled ? 1 : 0.5
    }
}
