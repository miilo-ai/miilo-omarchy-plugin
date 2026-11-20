import QtQuick
import QtQuick.Controls

ToolButton {
    id: control
    required property var theme
    required property string kind
    required property string label
    property bool circular: false
    property bool selected: false
    implicitWidth: theme.typography.profile==="phone"?48:theme.controlHeight
    implicitHeight: implicitWidth
    padding: 5
    focusPolicy: Qt.StrongFocus
    Accessible.name: label
    ToolTip {
        id: tip
        objectName: "toolbar-tooltip"
        parent: control
        visible: control.enabled && (control.hovered || control.activeFocus)
        text: control.label
        delay: 500
        timeout: 5000
        padding: control.theme.gap
        margins: control.theme.gap
        width: Math.min(implicitWidth, 280)
        contentItem: TypeText {
            typography: control.theme.typography
            role: "small"
            text: tip.text
            color: control.theme.tooltipText
        }
        background: Rectangle {
            color: control.theme.tooltipSurface
            radius: control.theme.radius
            border.width: 1
            border.color: control.theme.tooltipBorder
        }
    }
    background: Rectangle {
        radius: control.circular ? height / 2 : control.theme.radius
        color: control.selected ? control.theme.selectedFill : control.down ? control.theme.pressedFill : control.activeFocus ? control.theme.focusFill : control.hovered ? control.theme.hoverFill : "transparent"
        border.width: control.activeFocus || control.selected ? 1 : 0
        border.color: control.theme.accent
    }
    contentItem: Canvas {
        id: icon
        onPaint: {
            var c = getContext("2d"); c.reset();
            c.strokeStyle = control.enabled ? control.theme.foreground : control.theme.border;
            c.lineWidth = 1.4; c.lineCap = "round"; c.lineJoin = "round";
            c.save(); c.scale(width / 16, height / 16); c.beginPath();
            if (control.kind === "add") {
                c.moveTo(8, 3); c.lineTo(8, 13); c.moveTo(3, 8); c.lineTo(13, 8);
            } else if(control.kind==="search") {
                c.arc(6.5,6.5,4,0,Math.PI*2);c.moveTo(9.5,9.5);c.lineTo(13.5,13.5);
            } else if (control.kind === "voice" || control.kind === "muted") {
                c.moveTo(5, 5); c.arc(8, 5, 3, Math.PI, 0); c.lineTo(11, 8); c.arc(8, 8, 3, 0, Math.PI); c.closePath(); c.moveTo(3, 7); c.lineTo(3, 8); c.arc(8, 8, 5, Math.PI, 0, true); c.moveTo(8, 13); c.lineTo(8, 15);
                if(control.kind === "muted"){c.moveTo(2,2);c.lineTo(14,14);}
            } else if (control.kind === "stop") {
                c.rect(4, 4, 8, 8);
            } else if (control.kind === "back") {
                c.moveTo(8, 3); c.lineTo(3, 8); c.lineTo(8, 13); c.moveTo(3, 8); c.lineTo(13, 8);
            } else if (control.kind === "settings") {
                for (var tooth = 0; tooth < 32; tooth++) {
                    var angle = tooth * Math.PI / 16;
                    var radius = tooth % 4 < 2 ? 6 : 4.8;
                    var x = 8 + radius * Math.cos(angle), y = 8 + radius * Math.sin(angle);
                    if (tooth === 0) c.moveTo(x, y); else c.lineTo(x, y);
                }
                c.closePath(); c.moveTo(10, 8); c.arc(8, 8, 2, 0, Math.PI * 2);
            } else if (control.kind === "refresh") {
                c.arc(8, 8, 5, -0.6, 4.6); c.moveTo(13, 2); c.lineTo(13, 6); c.lineTo(9, 6);
            } else {
                c.moveTo(3, 4); c.lineTo(13, 4); c.moveTo(3, 8); c.lineTo(13, 8); c.moveTo(3, 12); c.lineTo(13, 12);
            }
            c.stroke(); c.restore();
        }
        Connections { target: control.theme; function onForegroundChanged() { icon.requestPaint() } }
        Connections { target: control; function onEnabledChanged() { icon.requestPaint() } }
    }
}
