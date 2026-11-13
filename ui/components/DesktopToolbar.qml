import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

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
    signal chatRequested()
    spacing: 4
    MiiloWordmark {
        objectName: "titleWordmark"
        ink: root.theme.foreground
        Layout.preferredWidth: Layout.preferredHeight * 184 / 72
        Layout.preferredHeight: root.theme.typography.size("body") * 2
    }
    TypeText {
        objectName: "productNameLabel"
        typography: root.theme.typography
        role: "body"
        lineHeight: 1
        verticalAlignment: Text.AlignVCenter
        Layout.preferredHeight: 36
        Layout.leftMargin: 4
        text: "One"
        wrapMode: Text.NoWrap
        Layout.minimumWidth: implicitWidth
        color: root.theme.foreground
        Layout.alignment: Qt.AlignVCenter
    }
    Item { Layout.fillWidth: true }
    ToolbarButton {
        theme: root.theme; kind: "voice"; label: "Ask Miilo"
        contentItem: MiiloSymbol { ink: root.theme.foreground }
        onClicked: root.chatRequested()
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
        theme: root.theme; kind: "menu"; label: "Miilo One menu"
        enabled: !root.busy
        onClicked: settingsMenu.open()
        Menu {
            id: settingsMenu
            y: menuButton.height
            MenuItem { text: "Systems"; checkable: true; autoExclusive: true; checked: root.activeSection === "filters"; onTriggered: root.systemsRequested() }
            MenuItem { text: "Appearance"; checkable: true; autoExclusive: true; checked: root.activeSection === "appearance"; onTriggered: root.settingsRequested("appearance") }
            MenuItem { text: "Connections"; checkable: true; autoExclusive: true; checked: root.activeSection === "systems"; onTriggered: root.settingsRequested("systems") }
            MenuItem { text: "Pair computer"; checkable: true; autoExclusive: true; checked: root.activeSection === "pair"; onTriggered: root.settingsRequested("pair") }
            MenuItem { text: "Chat model"; checkable: true; autoExclusive: true; checked: root.activeSection === "chat"; onTriggered: root.settingsRequested("chat") }
            MenuItem { text: "About"; checkable: true; autoExclusive: true; checked: root.activeSection === "about"; onTriggered: root.settingsRequested("about") }
            MenuItem { text: "Notifications"; checkable: true; autoExclusive: true; checked: root.activeSection === "notifications"; onTriggered: root.settingsRequested("notifications") }
        }
    }
    function focusAdd() { addButton.forceActiveFocus() }
}
