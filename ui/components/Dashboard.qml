import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

FloatingWindow {
    id: root
    title: "Miilo"
    property real textScale: 1
    property string textFamily: Qt.application.font.family
    readonly property bool compactFleet: surface.quietFleet && !importer.visible
    // Desired size follows navigation; the compositor owns the actual viewport.
    implicitWidth: compactFleet ? Math.min(420, screen ? screen.width - 32 : 420) : screen ? Math.min(960, Math.round(screen.width * 0.65)) : 640
    implicitHeight: compactFleet ? Math.min(320, screen ? screen.height - 32 : 320) : screen ? Math.min(720, Math.round(screen.height * 0.8)) : 520
    property alias surface: surface
    property alias importer: importer
    property int importedCount: 0
    property bool showingSettings: false
    function showSettings(section) { surface.closeSettings(); settingsPanel.section = section; showingSettings = true; settingsPanel.forceActiveFocus() }
    function showSessions() { surface.closeSettings(); showingSettings = false; importer.review() }
    function back() { if (showingSettings) showingSettings = false; else root.visible = false }
    property QtObject interactionTheme: InteractionTheme { widget: surface.widget }
    Shortcut { sequence: "Ctrl+L"; enabled: root.visible && !importer.busy; onActivated: root.showSessions() }
    Shortcut { sequence: "Escape"; enabled: root.visible && !importer.visible; onActivated: root.back() }
    Shortcut { sequence: "Ctrl+,"; enabled: root.visible && !importer.busy; onActivated: root.showSettings("appearance") }
    Item {
        anchors.fill: parent
        Rectangle {
            id: header
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }
            height: headerContent.implicitHeight + 12
            color: surface.widget.ink("background")
            DesktopToolbar {
                id: headerContent
                anchors { left: parent.left; right: parent.right; top: parent.top; leftMargin: 10; rightMargin: 10; topMargin: 6 }
                theme: root.interactionTheme
                activeSection: root.showingSettings ? settingsPanel.section : ""
                busy: importer.busy
                onLocalRequested: root.showSessions()
                onRemoteRequested: root.showSettings("systems")
                onRefreshRequested: surface.widget.refresh()
                onSettingsRequested: section => root.showSettings(section)
                onSystemsRequested: root.showSettings("filters")
            }
        }
        MiiloSurface {
            id: surface
            anchors {
                top: header.bottom
                bottom: parent.bottom
                left: parent.left
                right: parent.right
            }
            hostTextScale: root.textScale
            hostFontFamily: root.textFamily
            active: root.visible && !importer.visible && !root.showingSettings
            visible: !importer.visible && !root.showingSettings
            expanded: true
            interactionTheme: root.interactionTheme
            focus: true
            Keys.onEscapePressed: root.back()
        }
        DesktopSettings {
            id: settingsPanel
            anchors.fill: surface
            surface: root.surface
            theme: root.interactionTheme
            visible: root.showingSettings
            onClosed: root.showingSettings = false
        }
        LocalImport {
            id: importer
            leftHanded: { var revision = surface.widget.generation; return surface.viewValue("leftHanded") === true }
            anchors.fill: surface
            widget: surface.widget
            theme: root.interactionTheme
            active: root.visible
            suspended: root.showingSettings
            onVisibleChanged: if (!visible && root.visible) headerContent.focusAdd()
            onConnected: count => {
                root.importedCount = count;
                surface.widget.refresh();
            }
        }
    }
    onVisibleChanged: if (visible && surface.widget.program)
        surface.widget.openScreen()
}
