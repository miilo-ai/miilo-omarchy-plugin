pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "controls" as Controls

ColumnLayout {
    id: view
    required property var controller
    required property var widget
    required property var theme
    readonly property var context: view
    Layout.fillWidth: true
    spacing: 14
    Repeater {
        model: controller.agents
        delegate: ColumnLayout {
            required property var modelData
            Layout.fillWidth: true
            spacing: 4
            Text {
                text: modelData.name + (modelData.observationSupported ? "" : " · import not available yet")
                color: view.widget.ink("foreground")
                font.pixelSize: 14
            }
            Text {
                Layout.fillWidth: true
                text: (modelData.locations || []).map(p => p.replace(Quickshell.env("HOME"), "~")).join(" · ") || "Installed command found"
                color: view.widget.ink("muted")
                font.pixelSize: 12
                wrapMode: Text.WrapAnywhere
            }
        }
    }
}
