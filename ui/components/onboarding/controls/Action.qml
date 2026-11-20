pragma ComponentBehavior: Bound
import QtQuick
import "../.." as Miilo
import QtQuick.Controls
import QtQuick.Layouts

Button {
    required property var context
    property bool primary: false
    property bool selected: false
    Accessible.description: selected ? "Current section" : ""
    Layout.minimumWidth: 0
    Layout.preferredWidth: context.theme.typography.profile === "phone" ? 180 : Math.max(72, contentItem.implicitWidth + 16)
    Layout.fillWidth: context.theme.typography.profile === "phone"
    id: control
    width: parent ? Math.min(implicitWidth, parent.width) : implicitWidth
    implicitWidth: Math.max(72, contentItem.implicitWidth + 2 * horizontalPadding)
    implicitHeight: Math.max(context.theme.controlHeight, context.theme.typography.controlHeight(contentItem.implicitHeight, context.theme.typography.profile === "phone" ? 4 : 8))
    padding: 0
    topInset: 0; bottomInset: 0; leftInset: 0; rightInset: 0
    horizontalPadding: 8
    flat: true
    verticalPadding: context.theme.typography.profile === "phone" ? 2 : 0
    focusPolicy: Qt.StrongFocus
    Keys.onReturnPressed: clicked()
    Keys.onEnterPressed: clicked()
    background: Rectangle {
        color: control.selected || control.primary ? context.theme.selectedFill : control.down ? context.theme.pressedFill : control.hovered && control.enabled ? context.theme.hoverFill : context.theme.inset
        border.color: context.theme.accent
        border.width: control.activeFocus && !control.selected ? 1 : 0
        radius: context.theme.radius
        opacity: control.enabled ? 1 : 0.5
    }
    contentItem: Miilo.TypeText { typography: context.theme.typography;
        text: control.text
        color: control.activeFocus ? context.theme.focusText : context.theme.foreground
        opacity: control.enabled ? 1 : 0.5
        role: "body"
        font.weight: control.selected ? Font.DemiBold : Font.Normal
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
}
