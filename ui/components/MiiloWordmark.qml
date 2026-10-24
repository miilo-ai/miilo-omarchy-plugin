import QtQuick
import "MiiloBrand.js" as Brand

Item {
    id: root
    required property color ink
    implicitWidth: 86
    implicitHeight: implicitWidth * 72 / 184
    Accessible.role: Accessible.StaticText
    Accessible.name: "Miilo"
    Image {
        anchors.fill: parent
        source: Brand.source("wordmark", root.ink)
        sourceSize: Qt.size(Math.max(1, Math.ceil(width * 2)), Math.max(1, Math.ceil(height * 2)))
        fillMode: Image.PreserveAspectFit
        smooth: true
        Accessible.ignored: true
    }
}
