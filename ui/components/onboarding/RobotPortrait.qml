import QtQuick

// Original decorative Miilo character. Never represents an enrolled agent.
Canvas {
    id: root
    property color ink: "white"
    property color accent: ink
    property string expression: "curious"
    property string motion: "reduced"
    property bool active: true
    property real clock: 0
    implicitWidth: 56
    implicitHeight: 56
    Accessible.ignored: true
    FrameAnimation {
        running: root.active && root.visible && root.motion === "full"
        onTriggered: root.clock = elapsedTime
    }
    onClockChanged: requestPaint()
    onInkChanged: requestPaint()
    onAccentChanged: requestPaint()
    onExpressionChanged: requestPaint()
    onMotionChanged: { clock = 0; requestPaint() }
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onPaint: {
        var c = getContext("2d"); c.reset();
        var s = Math.min(width,height), x = width/2, y = height*0.44;
        var t = motion === "full" ? clock : 0;
        var r = s*.28, blink = t > 0 && t%6.3 < .14;
        var gaze = expression === "curious" ? Math.sin(t*.55)*r*.09 : 0;
        function tint(color,a) { return Qt.rgba(color.r,color.g,color.b,a); }
        c.fillStyle=tint(accent,.07); c.beginPath(); c.arc(x,y,r*1.55,0,Math.PI*2); c.fill();
        c.strokeStyle=ink; c.lineWidth=1.8; c.lineCap="round";
        c.beginPath(); c.roundedRect(x-r,y-r*.7,r*2,r*1.55,r*.24,r*.24); c.stroke();
        c.beginPath(); c.moveTo(x,y-r*.7); c.lineTo(x,y-r*1.03); c.stroke();
        c.fillStyle=accent; c.beginPath(); c.arc(x,y-r*1.12,r*.1,0,Math.PI*2); c.fill();
        for (var side=-1;side<=1;side+=2) {
            var ex=x+side*r*.36+gaze;
            if (blink || expression === "resting") {
                c.strokeStyle=accent; c.beginPath(); c.moveTo(ex-r*.12,y); c.lineTo(ex+r*.12,y); c.stroke();
            } else {
                c.fillStyle=accent; c.beginPath(); c.arc(ex,y,r*.13,0,Math.PI*2); c.fill();
            }
        }
        c.strokeStyle=tint(ink,.7); c.beginPath(); c.moveTo(x-r*.2,y+r*.45); c.lineTo(x+r*.2,y+r*.45); c.stroke();
        c.fillStyle=tint(ink,.28); c.fillRect(x-r*.43,y+r*.91,r*.86,r*.18);
    }
}
