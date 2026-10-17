pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "onboarding" as Onboarding
import "onboarding/controls" as Controls

FocusScope {
    id: root
    property var widget
    property InteractionTheme theme: InteractionTheme { widget: root.widget }
    property bool active: true
    readonly property alias controller: flow
    readonly property string mode: flow.mode
    readonly property bool busy: flow.busy
    signal connected(int count)
    visible: flow.mode !== ""
    function review() { flow.review() }
    Onboarding.OnboardingController { id: flow; active: root.active; onConnected: count => root.connected(count) }
    Connections {
        target: flow
        function onModeChanged() { Qt.callLater(() => {
            if (flow.mode === "review") sessionList.forceActiveFocus();
            else if (flow.mode === "group") groupEditor.focusEditor();
            else if (flow.mode === "invite") reviewButton.forceActiveFocus();
        }) }
    }
    Keys.onEscapePressed: event => {
        if (!flow.busy) { if (flow.mode === "group") flow.mode = "review"; else flow.dismiss(); }
        event.accepted = true;
    }
    Shortcut { sequence: "Ctrl+G"; enabled: root.visible && flow.mode === "review"; onActivated: flow.editGroup(-1) }
    Shortcut { sequence: "Ctrl+R"; enabled: root.visible && flow.mode === "review"; onActivated: flow.review() }
    Shortcut { sequence: "Ctrl+Return"; enabled: root.visible && flow.mode === "review" && (flow.selected.length > 0 || flow.groupsDirty); onActivated: flow.importSelected() }
    Rectangle { anchors.fill: parent; color: root.widget.ink("background") }
    ScrollView {
        id: pageScroll
        objectName: "onboardingScroll"
        anchors.fill: parent
        clip: true
        contentWidth: availableWidth
        contentHeight: page.implicitHeight + 32
        ColumnLayout {
            id: page
            x: 16; y: 16
            width: Math.max(0, pageScroll.availableWidth - 32)
            spacing: 12
            Onboarding.CrewHeader {
                widget: root.widget
                theme: root.theme
                active: root.active && root.visible
                failed: !!flow.error
                title: flow.mode === "invite" ? "Your local crew" : flow.mode === "importing" ? "Connecting your crew" : flow.mode === "group" ? "Define an agent group" : "Choose your sessions"
                subtitle: flow.mode === "invite" ? (flow.agents.some(a => a.observationSupported === true) ? "Choose which sessions Miilo observes." : "Setups detected. Observation is not available for these agents yet.") : flow.mode === "importing" ? "Saving your selection and starting local observation." : flow.mode === "group" ? "Match projects within a folder. * matches any text; ? matches one character." : "Space selects · Enter folds groups · Ctrl+G adds a group"
            }
            Onboarding.AgentInvitation { visible: flow.mode === "invite"; Layout.fillWidth: true; controller: flow; widget: root.widget; theme: root.theme }
            GridLayout {
                columns: Math.max(1, Math.min(3, Math.floor(width / (180 * root.theme.typography.effectiveScale))))
                columnSpacing: 8; rowSpacing: 8
                visible: flow.mode === "review"
                Layout.fillWidth: true
                Controls.Field { context: root;
                    text: flow.project
                    placeholderText: "Project directory"
                    onTextEdited: flow.project = text
                    onAccepted: flow.review()
                }
                Controls.Action { context: root;
                    text: "Rescan"
                    enabled: !flow.busy
                    onClicked: flow.review()
                }
            }
            GridLayout {
                columns: Math.max(1, Math.min(3, Math.floor(width / (180 * root.theme.typography.effectiveScale))))
                columnSpacing: 8; rowSpacing: 8
                visible: flow.mode === "review"
                Layout.fillWidth: true
                Controls.Action { context: root; text: "Add group"; onClicked: flow.editGroup(-1) }
                Controls.Choice { context: root;
                    id: existingGroup
                    Layout.fillWidth: true
                    model: flow.groups.map(g => g.name + (g.future ? " · future matches on" : ""))
                    enabled: flow.groups.length > 0
                    Accessible.name: "Saved group to edit"
                }
                Controls.Action { context: root; text: "Edit group"; enabled: flow.groups.length > 0; onClicked: flow.editGroup(existingGroup.currentIndex) }
            }
            Onboarding.GroupEditor { id: groupEditor; visible: flow.mode === "group"; Layout.fillWidth: true; Layout.preferredHeight: Math.max(180, root.height * 0.45); controller: flow; widget: root.widget; theme: root.theme }
            TypeText { typography: root.theme.typography;
                visible: flow.mode === "loading"
                Layout.fillWidth: true
                text: "Looking for existing sessions…"
                color: root.widget.ink("foreground")
            }
            Onboarding.SessionList { id: sessionList; visible: flow.mode === "review"; Layout.fillWidth: true; Layout.preferredHeight: Math.max(180, root.height * 0.45); controller: flow; widget: root.widget; theme: root.theme }
            TypeText { typography: root.theme.typography;
                visible: flow.mode === "review" && !flow.sessions.length
                Layout.fillWidth: true
                text: flow.error ? "" : "No supported sessions were found here. Choose a project directory and rescan."
                color: root.widget.ink("foreground")
                wrapMode: Text.WordWrap
            }
            TypeText { typography: root.theme.typography;
                visible: !!flow.error
                Layout.fillWidth: true
                text: flow.error
                color: root.widget.ink("red")
                wrapMode: Text.WordWrap
            }
            TypeText { typography: root.theme.typography;
                Layout.fillWidth: true
                text: flow.groupsDirty ? "Group changes are saved when you confirm below. Future enrollment requires its own opt-in. Ctrl+Enter confirms; Escape goes back." : "Only selected sessions are imported, plus future matches of opted-in groups. Tab moves focus; Ctrl+Enter confirms. Agent credentials stay in place."
                color: root.widget.ink("muted")
                role: "small"
                wrapMode: Text.WordWrap
            }
            GridLayout {
                columns: Math.max(1, Math.min(3, Math.floor(width / (180 * root.theme.typography.effectiveScale))))
                columnSpacing: 8; rowSpacing: 8
                Layout.fillWidth: true
                Controls.Action { context: root;
                    id: reviewButton
                    objectName: "reviewButton"
                    visible: flow.mode === "invite"
                    text: "Review sessions"
                    enabled: flow.agents.some(a => a.observationSupported === true) && !flow.busy
                    onClicked: flow.review()
                }
                Controls.Action { context: root; visible: flow.mode === "group"; text: "Save group"; onClicked: flow.saveGroup(groupEditor.rule()) }
                Controls.Action { context: root;
                    visible: flow.mode === "group" && flow.editIndex >= 0
                    text: "Remove group"
                    onClicked: { var next = flow.groups.slice(); next.splice(flow.editIndex,1); flow.pendingGroups = next; flow.regroup(); }
                }
                Controls.Action { context: root;
                    visible: flow.mode === "review"
                    text: (flow.groupsDirty ? "Apply groups & import (" : "Import selected (") + flow.selected.length + ")"
                    enabled: (flow.selected.length > 0 || flow.groupsDirty) && !flow.busy
                    onClicked: flow.importSelected()
                }
                Controls.Action { context: root;
                    visible: !flow.busy
                    text: flow.mode === "invite" ? "Not now" : "Cancel"
                    onClicked: { if (flow.mode === "group") flow.mode = "review"; else flow.dismiss(); }
                }
            }
        }
    }
}
