pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import ".." as Miilo
import "../onboarding/controls" as Controls
import "IntakeState.js" as Intake

ColumnLayout {
    id: root
    required property var theme
    required property var controller
    readonly property var widget: ({ink: function(name) { return name === "muted" ? root.theme.foreground : root.theme.foreground; }})
    signal settingsRequested()
    spacing: theme.sectionGap
    RowLayout {
        Layout.fillWidth: true
        Miilo.TypeText { typography: root.theme.typography; text: "Inbox"; color: root.theme.foreground; font.weight: Font.DemiBold; Layout.fillWidth: true }
        Controls.Action { context: root; text: "Refresh"; enabled: root.controller.configured && !root.controller.busy; onClicked: root.controller.refresh() }
        Miilo.ToolbarButton { theme: root.theme; kind: "settings"; label: "Intake settings"; onClicked: root.settingsRequested() }
    }
    Miilo.TypeText { typography: root.theme.typography; color: root.theme.foreground; Layout.fillWidth: true; visible: !root.controller.configured; text: "Connect an intake to receive tasks. You can use your own service or a manual inbox." }
    Miilo.TypeText { typography: root.theme.typography; color: root.theme.foreground; Layout.fillWidth: true; visible: !!text; text: root.controller.error || root.controller.message }
    Controls.Action { context: root; visible: root.controller.retryArguments.length > 0; enabled: !root.controller.busy; text: "Retry same request"; onClicked: root.controller.retry() }
    ScrollView {
        id: scroll
        Layout.fillWidth: true; Layout.fillHeight: true; contentWidth: availableWidth; clip: true; background: null
        ColumnLayout {
            width: scroll.availableWidth; spacing: root.theme.sectionGap
            Miilo.TypeText { typography: root.theme.typography; color: root.theme.foreground; visible: root.controller.configured && !root.controller.stale && root.controller.items.length === 0; text: "No incoming tasks" }
            Repeater {
                model: root.controller.items
                delegate: ColumnLayout {
                    required property var modelData
                    Layout.fillWidth: true; spacing: root.theme.gap
                    RowLayout {
                        Layout.fillWidth: true
                        Miilo.TypeText { typography: root.theme.typography; color: root.theme.foreground; objectName: "intakeTitle"; text: modelData.title; font.weight: Font.DemiBold; Layout.fillWidth: true }
                        Miilo.TypeText { typography: root.theme.typography; role: "small"; color: root.theme.accent; text: Intake.label(modelData) }
                    }
                    Miilo.TypeText { typography: root.theme.typography; role: "small"; color: root.theme.foreground; text: Intake.reference(modelData); Layout.fillWidth: true }
                    Miilo.TypeText { typography: root.theme.typography; color: root.theme.foreground; text: modelData.summary; Layout.fillWidth: true; wrapMode: Text.Wrap; maximumLineCount: 3; elide: Text.ElideRight }
                    RowLayout {
                        Controls.Action { context: root; text: "Open"; visible: Intake.safeLink(modelData.nativeUrl); onClicked: if (!Qt.openUrlExternally(modelData.nativeUrl)) root.controller.error = "Could not open the link." }
                        Controls.Action { objectName: "intakeAccept"; context: root; text: "Accept"; visible: Intake.available(modelData, "accept"); enabled: !root.controller.busy && !root.controller.stale; onClicked: root.controller.decide(modelData, "accept") }
                        Controls.Action { objectName: "intakeDefer"; context: root; text: "Later (4h)"; visible: Intake.available(modelData, "defer"); enabled: !root.controller.busy && !root.controller.stale; onClicked: root.controller.decide(modelData, "defer") }
                        Controls.Action { objectName: "intakeDismiss"; context: root; text: "Dismiss"; visible: Intake.available(modelData, "dismiss"); enabled: !root.controller.busy && !root.controller.stale; onClicked: root.controller.decide(modelData, "dismiss") }
                    }
                }
            }
        }
    }
}
