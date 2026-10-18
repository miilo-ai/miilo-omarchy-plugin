import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "onboarding" as Crew

RowLayout {
    id: root
    required property var theme
    property bool busy: false
    property string activeSection: ""
    signal localRequested()
    signal remoteRequested()
    signal refreshRequested()
    signal settingsRequested(string section)
    signal systemsRequested()
    spacing: 4
    Crew.RobotPortrait {
        objectName: "titleRobot"
        ink: root.theme.foreground
        accent: root.theme.foreground
        highContrast: true
        accentOnly: true
        Layout.preferredWidth: 28
        Layout.preferredHeight: 28
        motion: "reduced"
    }
    TypeText {
        typography: root.theme.typography
        role: "title"
        text: "Miilo"
        color: root.theme.foreground
        Layout.fillWidth: true
    }
    ToolbarButton {
        id: addButton
        objectName: "addSystemButton"
        theme: root.theme; kind: "add"; label: "Add system"
        enabled: !root.busy
        onClicked: addMenu.open()
        Menu {
            id: addMenu
            y: addButton.height
            MenuItem { text: "Local sessions"; onTriggered: root.localRequested() }
            MenuItem { text: "Remote system"; onTriggered: root.remoteRequested() }
        }
    }
    ToolbarButton {
        objectName: "refreshSystemsButton"
        theme: root.theme; kind: "refresh"; label: "Refresh systems"
        enabled: !root.busy
        onClicked: root.refreshRequested()
    }
    ToolbarButton {
        id: menuButton
        objectName: "systemMenuButton"
        theme: root.theme; kind: "menu"; label: "Miilo menu"
        enabled: !root.busy
        onClicked: settingsMenu.open()
        Menu {
            id: settingsMenu
            y: menuButton.height
            MenuItem { text: "Systems"; checkable: true; autoExclusive: true; checked: root.activeSection === "filters"; onTriggered: root.systemsRequested() }
            MenuItem { text: "Appearance"; checkable: true; autoExclusive: true; checked: root.activeSection === "appearance"; onTriggered: root.settingsRequested("appearance") }
            MenuItem { text: "Connections"; checkable: true; autoExclusive: true; checked: root.activeSection === "systems"; onTriggered: root.settingsRequested("systems") }
            MenuItem { text: "Chat model"; checkable: true; autoExclusive: true; checked: root.activeSection === "chat"; onTriggered: root.settingsRequested("chat") }
        }
    }
    function focusAdd() { addButton.forceActiveFocus() }
}
