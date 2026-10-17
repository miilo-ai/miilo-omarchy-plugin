import QtQuick
import qs.Commons
import qs.Commons as Commons
import ".." as Miilo

Item {
    id: root
    property bool opened: false
    function open() { opened = true }
    function close() { opened = false }
    function toggle() { opened = !opened }
    Miilo.Dashboard {
        id: dashboard
        interactionTheme: Miilo.InteractionTheme {
            widget: dashboard.surface.widget
            foreground: Commons.Color.foreground
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
