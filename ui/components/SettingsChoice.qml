pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "onboarding/controls" as Controls

GridLayout {
    id: root
    required property var context
    required property string label
    required property string stateKey
    required property var options
    required property var values
    columns: width < 300 ? 1 : 2
    columnSpacing: 12; rowSpacing: 3
    Layout.fillWidth: true
    TypeText {
        typography: root.context.theme.typography
        text: root.label; color: root.context.theme.foreground; role: "small"
        Layout.preferredWidth: 100
    }
    Controls.Choice {
        context: root.context
        objectName: root.stateKey + "Setting"
        Accessible.name: root.label
        model: root.options
        currentIndex: Math.max(0, root.values.indexOf(root.context.read(root.stateKey)))
        onActivated: root.context.write(root.stateKey, root.values[currentIndex])
    }
}
