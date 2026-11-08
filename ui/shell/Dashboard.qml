import QtQuick
import qs.Commons
import qs.Commons as Commons
import "../components" as Miilo

Item {
    id: root
    property bool opened: false
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
        textScale: Style.font.body / 12
        textFamily: Style.font.family
        liveController:root.liveController
        observationFeed:root.observationFeed
        surface.hostThemeRevision: String(Commons.Color.background)+String(Commons.Color.foreground)+String(Commons.Color.accent)
        interactionTheme: Miilo.InteractionTheme {
            widget: dashboard.surface.widget
            reduceMotion:Style.reduceMotion
            gap:Style.spacing.controlGap
            radius:Style.cornerRadius
            controlHeight:Style.spacing.controlHeight
            surface: Commons.Color.popups.background
            foreground: Commons.Color.popups.text
            accent: Commons.Color.accent
            border: Style.normalBorderColor
            hoverFill: Style.hoverFill
            focusFill: Commons.Color.menu.selectedBackground
            focusText: Commons.Color.menu.selectedText
            selectedFill: Style.selectedFill
            pressedFill: Style.pressedFill
            selectionFill: Style.selectionFillFor(Commons.Color.foreground, Commons.Color.accent)
        }
        visible: root.opened
        onVisibleChanged: if (!visible) root.opened = false
    }
}
