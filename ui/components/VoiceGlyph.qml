import QtQuick

Canvas {
    id: root
    property color ink: "white"
    property bool muted: false
    onInkChanged: requestPaint()
    onMutedChanged: requestPaint()
    onPaint: {
        const c=getContext("2d");c.reset();c.strokeStyle=ink;c.lineWidth=1.4;c.lineCap="round";c.lineJoin="round";
        c.save();c.scale(width/16,height/16);c.beginPath();
        c.moveTo(5,5);c.arc(8,5,3,Math.PI,0);c.lineTo(11,8);c.arc(8,8,3,0,Math.PI);c.closePath();
        c.moveTo(3,7);c.lineTo(3,8);c.arc(8,8,5,Math.PI,0,true);c.moveTo(8,13);c.lineTo(8,15);
        if(muted){c.moveTo(2,2);c.lineTo(14,14);}
        c.stroke();c.restore();
    }
}
