import QtQuick
import QtQuick.Layouts
import "onboarding" as Crew

ColumnLayout {
    id: root
    required property var widget
    property var theme: fallbackTheme
    property string message: "Checking in with your crew…"
    readonly property string motion: {
        var revision = widget ? widget.generation : 0;
        if (!widget || !widget.instance || !widget.program) return "reduced";
        var slot = widget.program.globals.findIndex(g => g.name === "robotMotion");
        return slot < 0 ? "reduced" : String(widget.instance.read(slot));
    }
    InteractionTheme { id: fallbackTheme; widget: root.widget }
    spacing: 6
    Crew.RobotPortrait {
        objectName: "loadingRobot"
        widget: root.widget
        ink: root.theme.foreground; accent: root.theme.accent
        accentOnly: true; motion: root.motion; active: root.visible
        Layout.preferredWidth: 56; Layout.preferredHeight: 56
        Layout.alignment: Qt.AlignHCenter
    }
    TypeText {
        typography: root.theme.typography; role: "small"
        text: root.message; color: root.theme.foreground
        horizontalAlignment: Text.AlignHCenter
        Layout.fillWidth: true
    }
}
