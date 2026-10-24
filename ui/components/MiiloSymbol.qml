pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Shapes

Item {
    id: root
    required property color ink
    implicitWidth: 24
    implicitHeight: 24
    Accessible.ignored: true
    Item {
        id: glyph
        readonly property real factor: Math.min(root.width / 64, root.height / 64)
        x: (root.width - 64 * factor) / 2
        y: (root.height - 64 * factor) / 2
        width: 64; height: 64
        transform: Scale { xScale: glyph.factor; yScale: glyph.factor }
        Shape {
            x: -123.5; y: -8
            ShapePath {
                strokeWidth: -1; fillColor: root.ink; fillRule: ShapePath.OddEvenFill
                PathSvg { path: "M145 29H166Q178 29 178 41V52Q178 64 166 64H145Q133 64 133 52V41Q133 29 145 29Z M144 38Q140 38 140 42V51Q140 55 144 55H167Q171 55 171 51V42Q171 38 167 38Z" }
            }
            ShapePath {
                strokeColor: root.ink; strokeWidth: 2.5; capStyle: ShapePath.RoundCap; fillColor: "transparent"
                PathSvg { path: "M155.5 22V30" }
            }
        }
        Repeater {
            model: [{x: 32, y: 12, r: 4.5}, {x: 25.5, y: 38.5, r: 3}, {x: 38.5, y: 38.5, r: 3}]
            Rectangle {
                required property var modelData
                x: modelData.x - modelData.r; y: modelData.y - modelData.r
                width: modelData.r * 2; height: width; radius: width / 2; color: root.ink
            }
        }
    }
}
