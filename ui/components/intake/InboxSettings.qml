pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import ".." as Miilo
import "../onboarding/controls" as Controls
ColumnLayout {
    id: root
    required property var context
    required property var controller
    spacing: context.theme.gap
    Controls.Choice { context: root.context; model: ["Private socket", "HTTP"]; currentIndex: root.controller.transport === "socket" ? 0 : 1; onActivated: root.controller.transport = currentIndex === 0 ? "socket" : "http" }
    Miilo.TypeText { typography: root.context.theme.typography; color: root.context.theme.foreground; text: "Socket path"; visible: root.controller.transport === "socket" }
    Controls.Field { context: root.context; text: root.controller.socketFile; placeholderText: "/path/to/private/intake.sock"; visible: root.controller.transport === "socket"; onEditingFinished: root.controller.socketFile = text.trim() }
    Miilo.TypeText { typography: root.context.theme.typography; color: root.context.theme.foreground; text: "Intake endpoint"; visible: root.controller.transport !== "socket" }
    Controls.Field { context: root.context; visible: root.controller.transport !== "socket"; text: root.controller.endpoint; placeholderText: "http://127.0.0.1:3710"; onEditingFinished: root.controller.endpoint = text.trim() }
    Miilo.TypeText { typography: root.context.theme.typography; color: root.context.theme.foreground; text: "Credential file"; visible: root.controller.transport !== "socket"; Layout.topMargin: root.context.theme.sectionGap }
    Controls.Field { context: root.context; visible: root.controller.transport !== "socket"; text: root.controller.tokenFile; placeholderText: "/path/to/private/token"; onEditingFinished: root.controller.tokenFile = text.trim() }
    Miilo.TypeText { typography: root.context.theme.typography; color: root.context.theme.foreground; Layout.fillWidth: true; wrapMode: Text.Wrap; text: "Use a Miilo-compatible intake or the CLI manual inbox. A private socket uses OS identity. HTTP stores a credential-file reference, not its contents." }
    Controls.Toggle { context: root.context; text: "Speak arrivals during a voice session"; checked: root.controller.speakArrivals; onToggled: root.controller.speakArrivals = checked; Layout.topMargin: root.context.theme.sectionGap }
    Controls.Action { context: root.context; text: "Test connection"; enabled: root.controller.configured && !root.controller.busy; onClicked: root.controller.refresh() }
    Miilo.TypeText { typography: root.context.theme.typography; color: root.context.theme.foreground; text: root.controller.error || (!root.controller.stale ? "Connected" : ""); Layout.fillWidth: true }
}
