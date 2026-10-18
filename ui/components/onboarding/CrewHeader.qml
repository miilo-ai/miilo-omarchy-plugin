import QtQuick
import ".." as Miilo
import QtQuick.Layouts

ColumnLayout {
    id: root
    required property var theme
    required property var widget
    property string title: "Your local crew"
    property string subtitle: "Choose which sessions Miilo observes."
    spacing: 2
    Layout.fillWidth: true
    Miilo.TypeText {
        typography: root.theme.typography
        Layout.fillWidth: true
        text: root.title
        color: root.widget.ink("foreground")
        role: root.theme.typography.profile === "phone" ? "title" : "body"
        font.weight: Font.DemiBold
        wrapMode: Text.WordWrap
    }
    Miilo.TypeText {
        typography: root.theme.typography
        Layout.fillWidth: true
        text: root.subtitle
        color: root.widget.ink("muted")
        role: root.theme.typography.profile === "phone" ? "body" : "small"
        wrapMode: Text.WordWrap
    }
}
