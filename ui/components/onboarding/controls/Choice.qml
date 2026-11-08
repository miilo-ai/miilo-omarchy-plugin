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
    implicitHeight: Math.max(context.theme.controlHeight,context.theme.typography.controlHeight(contentItem.implicitHeight, 8))
    verticalPadding: 2
    focusPolicy: Qt.StrongFocus
    leftPadding: 8
    rightPadding: indicator.visible ? 24 : 8
    background: Rectangle {
        color: context.theme.inset
        radius: context.theme.radius
        border.color: control.activeFocus ? context.theme.accent : context.theme.line
        border.width: 1
    }
    contentItem: Miilo.TypeText { typography: context.theme.typography;
        text: control.count ? control.displayText : "No saved groups"
        color: !control.enabled ? context.widget.ink("muted") : control.activeFocus ? context.theme.focusText : context.theme.foreground
        role: "body"
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
        implicitHeight: Math.max(context.theme.controlHeight,context.theme.typography.controlHeight(contentItem.implicitHeight, 8))
        topPadding: 2; bottomPadding: 2
        highlighted: control.highlightedIndex === index
        contentItem: Miilo.TypeText { typography: context.theme.typography;
            text: option.modelData
            color: option.highlighted ? context.theme.focusText : context.theme.foreground
            role: "body"
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
            radius: context.theme.radius
            border.color: context.theme.line
            border.width: 1
        }
    }
}
