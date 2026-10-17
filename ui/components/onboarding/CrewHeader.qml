import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root
    required property var widget
    property string title: "Your local crew"
    property string subtitle: "Choose which sessions Miilo observes."
    property bool active: true
    property bool failed: false
    property string motion: {
        var frame = widget ? widget.frame : 0;
        if (!widget || !widget.instance || !widget.program) return "reduced";
        var slot = widget.program.globals.findIndex(g => g.name === "robotMotion");
        return slot < 0 ? "reduced" : String(widget.instance.read(slot));
    }
    spacing: 10
    Layout.fillWidth: true
    RobotPortrait {
        Layout.preferredWidth: 64
        Layout.preferredHeight: 64
        ink: root.widget.ink("foreground")
        accent: root.widget.ink(root.failed ? "red" : "accent")
        motion: root.motion
        active: root.active
    }
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4
        Text {
            Layout.fillWidth: true
            text: root.title
            color: root.widget.ink("foreground")
            font.pixelSize: 20
            font.weight: Font.DemiBold
            wrapMode: Text.WordWrap
        }
        Text {
            Layout.fillWidth: true
            text: root.subtitle
            color: root.widget.ink("muted")
            font.pixelSize: 13
            wrapMode: Text.WordWrap
        }
    }
}
