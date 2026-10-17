pragma ComponentBehavior: Bound
import QtQuick
import "../.." as Miilo
import QtQuick.Controls
import QtQuick.Layouts

ComboBox {
    required property var context
    id: control
    Layout.minimumWidth: 0
    Layout.preferredWidth: 180
    Layout.fillWidth: true
    implicitHeight: Math.max(context.theme.typography.touchTarget, contentItem.implicitHeight + 16)
    focusPolicy: Qt.StrongFocus
    leftPadding: 12
    rightPadding: 32
    background: Rectangle {
        color: control.down ? context.theme.pressedFill : control.activeFocus ? context.theme.focusFill : control.hovered ? context.theme.hoverFill : context.widget.ink("lighter_background")
        border.color: context.theme.border
        border.width: 1
        Rectangle { anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter; width: parent.width - 16; height: 2; visible: control.activeFocus; color: context.theme.accent }
    }
    contentItem: Miilo.TypeText { typography: context.theme.typography;
        text: control.count ? control.displayText : "No saved groups"
        color: !control.enabled ? context.widget.ink("muted") : control.activeFocus ? context.theme.focusText : context.theme.foreground
        role: "label"
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.Wrap
    }
    indicator: Miilo.TypeText { typography: context.theme.typography;
        x: control.width - width - 12
        anchors.verticalCenter: parent.verticalCenter
        text: control.popup.visible ? "▴" : "▾"
        color: context.widget.ink(control.enabled ? "foreground" : "muted")
    }
    delegate: ItemDelegate {
        id: option
        required property var modelData
        required property int index
        width: control.width
        implicitHeight: Math.max(context.theme.typography.touchTarget, contentItem.implicitHeight + 16)
        highlighted: control.highlightedIndex === index
        contentItem: Miilo.TypeText { typography: context.theme.typography;
            text: option.modelData
            color: option.highlighted ? context.theme.focusText : context.theme.foreground
            role: "label"
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.Wrap
        }
        background: Rectangle {
            color: option.down ? context.theme.pressedFill : option.highlighted ? context.theme.focusFill : "transparent"
        }
    }
    popup: Popup {
        y: control.height
        width: control.width
        implicitHeight: Math.min(contentItem.implicitHeight + 8, context.height * 0.45)
        padding: 4
        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: control.popup.visible ? control.delegateModel : null
            currentIndex: control.highlightedIndex
            ScrollBar.vertical: ThemeScrollBar { context: control.context }
        }
        background: Rectangle {
            color: context.widget.ink("background")
            border.color: context.widget.ink("accent")
            border.width: 1
        }
    }
}
