import QtQuick
import "../../vendor/owl" as Owl

// Portable defaults; the Omarchy host supplies its live shell tokens.
QtObject {
    id: root
    property QtObject fallbackTypography: Owl.MiiloTypography {}
    property var typography: widget && widget.typography ? widget.typography : fallbackTypography
    property var widget
    function tint(name, opacity) {
        return wash(widget.ink(name), opacity);
    }
    function wash(value, opacity) {
        var color = Qt.color(value);
        return Qt.rgba(color.r, color.g, color.b, opacity);
    }
    property color foreground: widget.ink("foreground")
    property color accent: widget.ink("accent")
    property color secondary: widget && widget.palette && widget.palette.secondary !== undefined ? widget.ink("secondary") : widget.ink("cyan")
    property color secondaryFill: wash(secondary, 0.14)
    property color pathText: accent
    property color border: tint("foreground", 0.22)
    property color hoverFill: tint("foreground", 0.06)
    property color focusFill: tint("foreground", 0.1)
    property color focusText: accent
    property color selectedFill: tint("accent", 0.12)
    property color pressedFill: tint("accent", 0.2)
    property color selectionFill: widget.ink("selection")
}
