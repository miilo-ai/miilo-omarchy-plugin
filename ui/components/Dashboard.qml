import "intake" as Intake
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "chat" as Chat

FloatingWindow {
    id: root
    title: "Miilo One"
    color: "transparent"
    property real textScale: 1
    property string textFamily: Qt.application.font.family
    readonly property bool compactFleet: surface.quietFleet && !importer.visible && !showingSettings && !showingInbox
    // Desired size follows navigation; the compositor owns the actual viewport.
    implicitWidth: compactFleet ? Math.min(420, screen ? screen.width - 32 : 420) : screen ? Math.min(960, Math.round(screen.width * 0.65)) : 640
    implicitHeight: compactFleet ? Math.min(320, screen ? screen.height - 32 : 320) : screen ? Math.min(720, Math.round(screen.height * 0.8)) : 520
    property alias surface: surface
    property alias importer: importer
    property int importedCount: 0
    property bool showingSettings: false
    property bool showingInbox: false
    Intake.InboxController {
        id: intake; active: root.sessionUnlocked && configured
        onDecisionCompleted: message => chatPanel.speakStatus(message)
        onTasksArrived: count => { if (speakArrivals) chatPanel.speakStatus(count === 1 ? "A new task arrived." : count + " new tasks arrived."); }
    }
    property bool sessionUnlocked: false
    readonly property var voiceSession: chatPanel.handsFree
    property var liveController: null
    property var observationFeed: null
    readonly property bool applicationFocused: body.Window.active
    function showSettings(section) { showingInbox = false; surface.closeSettings(); settingsPanel.section = section; showingSettings = true; settingsPanel.forceActiveFocus() }
    function showSessions() { showingInbox = false; surface.closeSettings(); showingSettings = false; importer.review() }
    function back() { if (showingSettings) showingSettings = false; else if (showingInbox) showingInbox = false; else root.visible = false }
    property QtObject interactionTheme: InteractionTheme { widget: surface.widget }
    Shortcut { sequence: "Ctrl+L"; enabled: root.visible && !importer.busy; onActivated: root.showSessions() }
    Shortcut { sequence: "Escape"; enabled: root.visible && !importer.visible; onActivated: root.back() }
    Shortcut { sequence: "Ctrl+,"; enabled: root.visible && !importer.busy; onActivated: root.showSettings("appearance") }
    Item {
        id: body
        anchors.fill: parent
        Rectangle {objectName:"dashboardBackground";anchors.fill:parent;color:root.interactionTheme.surface}
        Rectangle {
            id: header
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }
            height: headerContent.implicitHeight + root.interactionTheme.gap * 2 + (root.observationFeed&&root.observationFeed.stale?20:0)
            color: "transparent"
            DesktopToolbar {
                id: headerContent
                anchors { left: parent.left; right: parent.right; top: parent.top; leftMargin: root.interactionTheme.gap * 2; rightMargin: root.interactionTheme.gap * 2; topMargin: root.interactionTheme.gap }
                theme: root.interactionTheme
                activeSection: root.showingSettings ? settingsPanel.section : ""
                busy: importer.busy
                voiceSession: chatPanel.handsFree
                voiceOutputPhase: chatPanel.playbackPhase
                voiceReady: chatPanel.ready
                onInboxRequested: { root.showingSettings = false; root.showingInbox = !root.showingInbox }
                onLocalRequested: root.showSessions()
                onRemoteRequested: root.showSettings("systems")
                onRefreshRequested: root.observationFeed?root.observationFeed.refresh():surface.widget.refresh()
                onSettingsRequested: section => root.showSettings(section)
                onSystemsRequested: root.showSettings("filters")
                onChatRequested: {
                    if (!chatPanel.handsFree.armed) {
                        const work = surface.viewValue("focused");
                        chatPanel.target = work ? {workKey: work._key, revisionKey: work._revisionKey} : null;
                    }
                    chatPanel.openConversation();
                }
            }
            TypeText {anchors.right:parent.right;anchors.bottom:parent.bottom;anchors.rightMargin:10;typography:root.interactionTheme.typography;role:"small";color:root.interactionTheme.foreground;visible:!!root.observationFeed&&root.observationFeed.stale;text:"Observation unavailable · previous snapshot"}
        }
        OverviewControls {
            id:overviewControls;theme:root.interactionTheme;surface:surface
            anchors {left:parent.left;right:parent.right;top:header.bottom;leftMargin:root.interactionTheme.gap*2;rightMargin:root.interactionTheme.gap*2}
            visible:atOverview&&!root.showingSettings&&!root.showingInbox&&!importer.visible
            height:visible?implicitHeight+root.interactionTheme.gap:0
        }
        MiiloSurface {
            id: surface
            paintBackground: false
            nativeControls:true
            anchors {
                top: overviewControls.bottom
                bottom: parent.bottom
                left: parent.left
                right: parent.right
            }
            hostTextScale: root.textScale
            hostFontFamily: root.textFamily
            active: root.visible && !importer.visible && !root.showingSettings && !root.showingInbox
            observationFeed:root.observationFeed
            visible: !importer.visible && !root.showingSettings && !root.showingInbox
            expanded: true
            interactionTheme: root.interactionTheme
            focus: true
            Keys.onEscapePressed: root.back()
        }
        Intake.InboxPanel {
            anchors.fill: surface; anchors.margins: root.interactionTheme.gap * 2
            theme: root.interactionTheme; controller: intake
            visible: root.showingInbox && !root.showingSettings && !importer.visible
            onSettingsRequested: root.showSettings("intake")
        }
        DesktopSettings {
            id: settingsPanel
            intakeController: intake
            anchors.fill: surface
            surface: root.surface
            theme: root.interactionTheme
            voiceController: chatPanel
            liveController:root.liveController
            visible: root.showingSettings
            onClosed: root.showingSettings = false
        }
        Chat.ChatPanel {
            id: chatPanel; inputHandler: intake.configured ? (text, method) => intake.receiveText(text, method) : null; externalBusy: intake.busy && intake.mutating; sessionUnlocked: root.sessionUnlocked; theme: root.interactionTheme; surface: root.surface
            overlayVisible: !root.showingSettings
            anchors { left: surface.left; right: surface.right; bottom: surface.bottom; margins: root.interactionTheme.gap * 2 }
            height: implicitHeight; z: 10
            visible: root.visible && !importer.visible
            onSettingsRequested: root.showSettings("voice")
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
