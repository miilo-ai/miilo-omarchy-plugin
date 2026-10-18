pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "onboarding" as Crew

ColumnLayout {
    id: root
    required property var context
    readonly property var providers: context.read("allProviders") || []
    readonly property var localIds: context.read("localSessionIds") || []
    readonly property var remote: providers.filter(p => root.localIds.indexOf(p.id) < 0)
    Layout.fillWidth: true
    spacing: 8
    TypeText {
        typography: root.context.theme.typography; role: "small"; Layout.fillWidth: true
        text: "Connect a Miilo-compatible service, such as a private automation factory. Local coding sessions are added separately."
        color: root.context.theme.foreground
    }
    Repeater {
        model: root.remote
        RowLayout {
            id: connectionRow
            required property var modelData
            Layout.fillWidth: true; spacing: 8
            Crew.RobotPortrait {
                Layout.preferredWidth: 24; Layout.preferredHeight: 24
                ink: root.context.theme.foreground; accent: root.context.theme.accent
                accentOnly: true; motion: "off"
            }
            ColumnLayout {
                Layout.fillWidth: true; spacing: 1
                TypeText { objectName: "connectionName"; typography: root.context.theme.typography; role: "small"; text: connectionRow.modelData.name; color: root.context.theme.foreground; font.weight: Font.DemiBold; Layout.fillWidth: true }
                TypeText { typography: root.context.theme.typography; role: "small"; text: (connectionRow.modelData.kind || "service").replace(/_/g," "); color: root.context.widget.ink("muted"); Layout.fillWidth: true }
            }
            TypeText { typography: root.context.theme.typography; role: "small"; text: connectionRow.modelData.health || connectionRow.modelData.status || "Unknown"; color: root.context.theme.foreground }
        }
    }
    TypeText {
        visible: root.remote.length === 0
        typography: root.context.theme.typography; role: "small"; Layout.fillWidth: true
        text: "No remote systems observed yet. Configure an endpoint to connect one."
        color: root.context.widget.ink("muted")
    }
}
