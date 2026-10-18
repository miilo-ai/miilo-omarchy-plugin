import QtQuick
import QtQuick.Controls

ToolButton {
    id: control
    required property var theme
    required property string kind
    required property string label
    implicitWidth: 26
    implicitHeight: 26
    padding: 5
    focusPolicy: Qt.StrongFocus
    Accessible.name: label
    ToolTip.visible: hovered || activeFocus
    ToolTip.text: label
    ToolTip.delay: 500
    background: Rectangle {
        radius: 4
        color: control.down ? control.theme.pressedFill : control.activeFocus ? control.theme.focusFill : control.hovered ? control.theme.hoverFill : "transparent"
        border.width: control.activeFocus ? 1 : 0
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
