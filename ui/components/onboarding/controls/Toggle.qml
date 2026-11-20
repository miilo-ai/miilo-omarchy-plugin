pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import "../.." as Miilo

Switch {
    id: control
    required property var context
    implicitHeight: Math.max(context.theme.typography.profile==="phone"?48:context.theme.controlHeight,contentItem.implicitHeight+8)
    spacing: context.theme.gap
    padding: 0
    indicator: Rectangle {
        implicitWidth: 30;implicitHeight:16
        x:control.leftPadding;y:Math.round((control.height-height)/2)
        radius:8
        color:control.checked?control.context.theme.selectedFill:control.context.theme.inset
        border.width:1;border.color:control.activeFocus||control.checked?control.context.theme.accent:control.context.theme.line
        Rectangle {
            width:10;height:10;radius:5;y:3;x:control.checked?17:3
            color:control.enabled?control.context.theme.foreground:control.context.theme.border
            Behavior on x {NumberAnimation{duration:control.context.theme.duration(120)}}
        }
    }
    contentItem: Miilo.TypeText {
        typography:control.context.theme.typography;role:"body"
        text:control.text;color:control.context.theme.foreground
        leftPadding:control.indicator.width+control.spacing
        verticalAlignment:Text.AlignVCenter
        opacity:control.enabled?1:0.5
    }
}
