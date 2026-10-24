pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Shapes

Item {
    id: root
    required property color ink
    implicitWidth: 86
    implicitHeight: implicitWidth * 72 / 184
    Accessible.role: Accessible.StaticText
    Accessible.name: "Miilo"
    Item {
        id: glyph
        readonly property real factor: Math.min(root.width / 184, root.height / 72)
        x: (root.width - 184 * factor) / 2
        y: (root.height - 72 * factor) / 2
        width: 184; height: 72
        transform: Scale { xScale: glyph.factor; yScale: glyph.factor }
        Shape {
            ShapePath {
                strokeColor: root.ink; strokeWidth: 9; capStyle: ShapePath.RoundCap
                joinStyle: ShapePath.RoundJoin; fillColor: "transparent"
                PathSvg { path: "M6 60V31 M6 41C6 27 30 27 30 41V60 M30 41C30 27 54 27 54 41V60 M74 35V60 M94 35V60 M115 12V60" }
            }
        }
        Repeater {
            model: [74, 94]
            Rectangle {
                required property int modelData
                x: modelData - 4.5; y: 15.5; width: 9; height: 9; radius: 4.5; color: root.ink
            }
        }
        MiiloSymbol { x: 123.5; y: 8; width: 64; height: 64; ink: root.ink }
    }
}
