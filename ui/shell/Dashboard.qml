import QtQuick
import qs.Commons
import qs.Commons as Commons
import "../components" as Miilo

Item {
    id: root
    property bool opened: false
    property bool sessionUnlocked: false
    readonly property var voiceSession: dashboard.voiceSession
    property var liveController: null
    property var observationFeed: null
    readonly property bool focused: dashboard.applicationFocused
    function open() { opened = true }
    function close() { opened = false }
    function toggle() { opened = !opened }
    property string pendingWork: ""
    function inspect(work) {pendingWork=work;locateWork();}
    function locateWork() {
        const items=dashboard.surface.viewValue("allWorks")||[];
        if(pendingWork&&items.some(item=>item._key===pendingWork)){dashboard.surface.setViewState("selectedWork",pendingWork);pendingWork="";}
    }
    Connections {target:dashboard.surface.widget;function onGenerationChanged(){Qt.callLater(root.locateWork);}}
    Miilo.Dashboard {
        id: dashboard
        sessionUnlocked: root.sessionUnlocked
        textScale: Style.font.body / 12
        textFamily: Style.font.family
        liveController:root.liveController
        observationFeed:root.observationFeed
        surface.hostThemeRevision: JSON.stringify(Commons.Color.shellValues)+String(Commons.Color.background)+String(Commons.Color.foreground)+String(Commons.Color.accent)+String(Commons.Color.muted)
        interactionTheme: Theme { widget: dashboard.surface.widget }
        visible: root.opened
        onVisibleChanged: if (!visible) root.opened = false
    }
}
