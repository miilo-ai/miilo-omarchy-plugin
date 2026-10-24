import QtQuick
import QtQuick.Layouts
import Quickshell.Io

ColumnLayout {
    id: root
    required property var context
    property string pluginVersion: "Unavailable"
    spacing: 10
    FileView {
        path: decodeURIComponent(String(Qt.resolvedUrl("../../manifest.json")).replace(/^file:\/\//, ""))
        printErrors: false
        onLoaded: {
            try {
                var version = JSON.parse(text()).version;
                root.pluginVersion = typeof version === "string" && /^\d+\.\d+\.\d+(?:-[A-Za-z0-9.-]+)?$/.test(version) ? version : "Unavailable";
            } catch (error) { root.pluginVersion = "Unavailable"; }
        }
        onLoadFailed: root.pluginVersion = "Unavailable"
    }
    TypeText {
        objectName: "pluginVersionLabel"
        typography: root.context.theme.typography; role: "small"
        text: "Omarchy plugin · " + root.pluginVersion
        color: root.context.theme.foreground; Layout.fillWidth: true
    }
    TypeText {
        typography: root.context.theme.typography; role: "small"
        text: "Personal by default. No Miilo account is required to observe your chosen sessions and connected systems."
        color: root.context.theme.foreground; Layout.fillWidth: true
    }
    TypeText {
        typography: root.context.theme.typography; role: "small"
        text: "You choose what to connect and import. Observation uses your configured endpoints; local preferences and connection settings stay on this computer. Keep credential files outside the plugin."
        color: root.context.theme.foreground; Layout.fillWidth: true
    }
    TypeText {
        typography: root.context.theme.typography; role: "small"
        text: "Model explanations are optional. Requests send selected work context to the model endpoint you configure, whose privacy policy applies. Observation does not grant permission to act on your systems."
        color: root.context.theme.foreground; Layout.fillWidth: true
    }
    TypeText {
        typography: root.context.theme.typography; role: "small"
        text: "Removing the plugin preserves your connections and observation data. Revoke remote access at its source when a device is no longer trusted."
        color: root.context.theme.foreground; Layout.fillWidth: true
    }
    TypeText {
        objectName: "aboutSupportCopy"
        typography: root.context.theme.typography; role: "small"
        text: "Help fund Miilo’s development."
        color: root.context.theme.foreground; Layout.fillWidth: true
    }
    GridLayout {
        objectName: "aboutLinks"
        columns: root.width >= website.implicitWidth + sponsor.implicitWidth + columnSpacing ? 2 : 1
        columnSpacing: 8; rowSpacing: 8
        Layout.alignment: root.context.read("leftHanded") === true ? Qt.AlignLeft : Qt.AlignRight
        AboutLink {
            id: website
            objectName: "aboutWebsite"
            context: root.context; text: "miilo.tech"
            onClicked: Qt.openUrlExternally("https://miilo.tech/")
        }
        AboutLink {
            id: sponsor
            objectName: "aboutSponsor"
            context: root.context; text: "Sponsor Miilo"
            onClicked: Qt.openUrlExternally("https://github.com/sponsors/miilo-ai")
        }
    }
}
