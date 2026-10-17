pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import ".." as Miilo

ColumnLayout {
    id: view
    required property var controller
    required property var widget
    required property var theme
    Layout.fillWidth: true
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
    Miilo.TypeText {
        typography: view.theme.typography
        visible: view.controller.agents.length === 0
        Layout.fillWidth: true
        text: "No local setups detected. You can still choose a project directory."
        color: view.widget.ink("muted")
    }
}
