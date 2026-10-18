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
    implicitHeight: context.theme.typography.controlHeight(contentItem.implicitHeight, 4)
    verticalPadding: 2
    focusPolicy: Qt.StrongFocus
    leftPadding: 8
    rightPadding: indicator.visible ? 24 : 8
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
    indicator: Canvas {
        width: 12; height: 12
        x: control.width - width - 8
        y: (control.height - height) / 2
        visible: control.enabled && control.count > 0
        rotation: control.popup.visible ? 180 : 0
        property color ink: control.context.theme.foreground
        onInkChanged: requestPaint()
        onPaint: {
            var c = getContext("2d"); c.reset();
            c.strokeStyle = ink; c.lineWidth = 1.4;
            c.lineCap = "round"; c.lineJoin = "round";
            c.beginPath(); c.moveTo(3, 4.5); c.lineTo(6, 7.5); c.lineTo(9, 4.5); c.stroke();
        }
    }
    delegate: ItemDelegate {
        id: option
        required property var modelData
        required property int index
        width: control.width
        implicitHeight: context.theme.typography.controlHeight(contentItem.implicitHeight, 4)
        topPadding: 2; bottomPadding: 2
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
