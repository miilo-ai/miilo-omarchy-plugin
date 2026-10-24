pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../vendor/owl" as Owl
import "onboarding/controls" as Controls

FocusScope {
    id: root
    required property var surface
    required property var theme
    readonly property var widget: surface.widget
    property string section: "appearance"
    property bool configuring: false
    readonly property var sections: ["appearance", "filters", "systems", "chat", "pair", "about"]
    readonly property var labels: ["Appearance", "Systems", "Connections", "Chat model", "Pair computer", "About"]
    readonly property bool wide: width >= 440
    signal closed()
    function read(name) { var revision = widget.generation; return surface.viewValue(name) }
    function write(name, value) { surface.setViewState(name, value) }
    onSectionChanged: configuring = false
    onVisibleChanged: if (!visible) configuring = false
    Keys.onEscapePressed: closed()
    Rectangle { anchors.fill: parent; color: root.widget.ink("background") }
    ColumnLayout {
        anchors.fill: parent; anchors.margins: 10; spacing: 12
        RowLayout {
            Layout.fillWidth: true
            TypeText { typography: root.theme.typography; role: "body"; text: "Settings"; font.weight: Font.DemiBold; color: root.theme.foreground; Layout.fillWidth: true }
            Controls.Action { objectName: "settingsBack"; context: root; text: "Back"; onClicked: root.closed() }
        }
        Controls.Choice {
            objectName: "settingsNavigation"
            context: root; visible: !root.wide; Layout.fillWidth: true
            Accessible.name: "Settings section"
            model: root.labels; currentIndex: Math.max(0, root.sections.indexOf(root.section))
            onActivated: root.section = root.sections[currentIndex]
        }
        RowLayout {
            Layout.fillWidth: true; Layout.fillHeight: true; spacing: 18
            ColumnLayout {
                visible: root.wide; Layout.preferredWidth: 112; Layout.alignment: Qt.AlignTop
                spacing: 5
                Repeater {
                    model: root.sections
                    Controls.Action {
                        required property string modelData
                        required property int index
                        objectName: modelData + "Navigation"
                        context: root; text: root.labels[index]
                        primary: root.section === modelData; selected: root.section === modelData; Layout.fillWidth: true
                        onClicked: root.section = modelData
                    }
                }
            }
            ScrollView {
                id: scroll
                Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                contentWidth: availableWidth
                ColumnLayout {
                    width: scroll.availableWidth; spacing: 12
                    TypeText { typography: root.theme.typography; role: "body"; text: root.labels[root.sections.indexOf(root.section)]; color: root.theme.foreground; font.weight: Font.DemiBold; Layout.fillWidth: true }
                    AboutSettings { context: root; visible: root.section === "about"; Layout.fillWidth: true }
                    AppearanceSettings { context: root; visible: root.section === "appearance"; Layout.fillWidth: true }
                    ColumnLayout {
                        visible: root.section === "filters"; Layout.fillWidth: true; spacing: 8
                        TypeText { typography: root.theme.typography; role: "small"; text: "Choose which system to show."; color: root.theme.foreground }
                        Controls.Choice {
                            context: root; Layout.fillWidth: true; Accessible.name: "Visible system"
                            property var providers: root.read("selectableProviders") || []
                            model: ["All systems"].concat(providers.map(p => p.name))
                            currentIndex: Math.max(0, providers.findIndex(p => p.id === root.read("system")) + 1)
                            onActivated: { root.write("system", currentIndex ? providers[currentIndex - 1].id : ""); root.write("selectedWork", ""); root.write("selectedActor", ""); }
                        }
                    }
                    ConnectionsOverview { objectName: "connectionsOverview"; context: root; visible: root.section === "systems"; Layout.fillWidth: true }
                    ColumnLayout {
                        visible: root.section === "systems" || root.section === "chat" || root.section === "pair"
                        Layout.fillWidth: true; spacing: 8
                        TypeText { typography: root.theme.typography; role: "small"; Layout.fillWidth: true; text: root.section === "chat" ? "Configure your model endpoint and credential reference." : root.section === "pair" ? "Create an invitation on the sharing computer with miilo local pair invite. Compare both codes before host approval. Only selected observations are shared." : "Connect a remote system using its endpoint and an @credential-file reference."; color: root.theme.foreground }
                        Controls.Action { context: root; text: root.configuring ? "Close setup" : "Configure"; primary: true; onClicked: root.configuring = !root.configuring }
                        Loader {
                            objectName: "setupTerminalLoader"
                            Layout.fillWidth: true; Layout.preferredHeight: active ? Math.max(180, root.height * 0.6) : 0
                            active: root.visible && root.configuring
                            sourceComponent: Component {
                                Owl.OwlTerminal { widget: root.widget; sessionActive: root.visible; node: ({p:{command:root.section === "pair" ? "miilo-owl pair" : root.section === "chat" ? "miilo-owl chat-setup" : "miilo-owl setup"}}) }
                            }
                        }
                    }
                }
            }
        }
    }
}
