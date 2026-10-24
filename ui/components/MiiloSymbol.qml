import QtQuick
import "MiiloBrand.js" as Brand

Item {
    id: root
    required property color ink
    implicitWidth: 24
    implicitHeight: 24
    Accessible.ignored: true
    Image {
        anchors.fill: parent
        source: Brand.source("symbol", root.ink)
        sourceSize: Qt.size(Math.max(1, Math.ceil(width * 2)), Math.max(1, Math.ceil(height * 2)))
        fillMode: Image.PreserveAspectFit
        smooth: true
        Accessible.ignored: true
    }
}
