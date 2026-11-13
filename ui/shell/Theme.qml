import QtQuick
import qs.Commons
import qs.Commons as Commons
import "../components" as Miilo

Miilo.InteractionTheme {
    reduceMotion:Style.reduceMotion
    gap:Style.spacing.controlGap
    radius:Style.cornerRadius
    controlHeight:Style.spacing.controlHeight
    surface: Commons.Color.popups.background
    menuSurface: Commons.Color.menu.background
    tooltipSurface: Commons.Color.tooltip.background
    tooltipText: Commons.Color.tooltip.text
    tooltipBorder: Commons.Color.tooltip.border
    inset: Style.normalFill
    line: Style.normalBorderColor
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
