import QtQuick
import "onboarding/controls" as Controls

Controls.Action {
    id: control
    Accessible.role: Accessible.Link
    Accessible.name: text
    Accessible.description: "Opens in your browser"
    contentItem: Row {
        spacing: 7
        TypeText {
            typography: control.context.theme.typography
            role: "label"
            text: control.text
            color: control.context.theme.foreground
            anchors.verticalCenter: parent.verticalCenter
        }
        Canvas {
            id: symbol
            objectName: "linkIcon"
            property color ink: control.context.theme.foreground
            width: Math.max(18, control.context.theme.typography.size("body") * 1.5)
            height: width
            anchors.verticalCenter: parent.verticalCenter
            Accessible.ignored: true
            onInkChanged: requestPaint()
            onPaint: {
                var c = getContext("2d"); c.reset();
                c.scale(width / 20, height / 20);
                c.translate(10, 10); c.rotate(-Math.PI / 4);
                c.strokeStyle = ink; c.lineWidth = 1.7;
                for (var center of [-4, 4]) {
                    c.beginPath();
                    c.moveTo(center - 2, -3);
                    c.lineTo(center + 2, -3);
                    c.arc(center + 2, 0, 3, -Math.PI / 2, Math.PI / 2);
                    c.lineTo(center - 2, 3);
                    c.arc(center - 2, 0, 3, Math.PI / 2, Math.PI * 1.5);
                    c.closePath(); c.stroke();
                }
            }
        }
    }
}
