pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "controls" as Controls

ScrollView {
    id: view
    required property var controller
    required property var widget
    required property var theme
    readonly property var context: view
    Layout.fillWidth: true
    Layout.fillHeight: true
    clip: true
    contentWidth: availableWidth
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
    ColumnLayout {
        width: view.availableWidth
        spacing: 6
        Repeater {
            model: view.controller.agents
            delegate: AgentSetupRow {
                required property var modelData
                agent: modelData
                widget: view.widget
                theme: view.theme
            }
        }
        Text {
            visible: view.controller.agents.length === 0
            Layout.fillWidth: true
            text: "No local setups detected. You can still choose a project directory."
            color: view.widget.ink("muted")
            wrapMode: Text.WordWrap
        }
    }
}
