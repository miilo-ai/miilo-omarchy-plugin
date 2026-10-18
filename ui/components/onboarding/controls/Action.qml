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
    implicitHeight: context.theme.typography.controlHeight(contentItem.implicitHeight, context.theme.typography.profile === "phone" ? 4 : 0)
    padding: 0
    topInset: 0; bottomInset: 0; leftInset: 0; rightInset: 0
    horizontalPadding: 8
    flat: true
    verticalPadding: context.theme.typography.profile === "phone" ? 2 : 0
    focusPolicy: Qt.StrongFocus
    Keys.onReturnPressed: clicked()
    Keys.onEnterPressed: clicked()
    background: Rectangle {
        color: control.selected ? context.theme.tint("accent", 0.32) : control.down ? context.theme.pressedFill : control.hovered && control.enabled ? context.theme.tint("accent", 0.22) : control.primary ? context.theme.tint("accent", 0.24) : context.theme.secondaryFill
        border.color: context.theme.accent
        border.width: control.activeFocus && !control.selected ? 1 : 0
        radius: 3
        opacity: control.enabled ? 1 : 0.5
        Rectangle { anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; width: 3; height: Math.max(8, parent.height - 6); visible: control.selected; color: context.theme.accent }
    }
    contentItem: Miilo.TypeText { typography: context.theme.typography;
        text: control.text
        color: control.activeFocus ? context.theme.focusText : context.theme.foreground
        opacity: control.enabled ? 1 : 0.5
        role: "label"
        font.weight: control.selected ? Font.DemiBold : Font.Normal
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
}
