import QtQuick
import QtQuick.Layouts
import ".." as Miilo
import "../onboarding/controls" as Controls

ColumnLayout {
    id: root
    required property var context
    required property var controller
    readonly property var voice: controller.handsFree
    spacing: context.theme.gap
    Controls.Toggle {
        objectName: "hands-free-toggle"; context: root.context
        text: "Hands-free"; checked: root.voice.preferred
        onToggled: { root.voice.setPreferred(checked); checked = Qt.binding(() => root.voice.preferred); }
    }
    Miilo.TypeText {
        typography: root.context.theme.typography; role: "small"; color: root.context.theme.foreground; Layout.fillWidth: true
        text: "Click Miilo to start or stop on your current screen. Start with your wake phrase; pauses send each question and listening resumes after spoken replies. While active, nearby speech can also be sent. Messages and observed context go to your configured model. Transcription uses Superwhisper’s selected local or cloud model; spoken replies go to your speech provider."
    }
    Controls.Toggle {
        context: root.context; text: "Captions"; checked: root.controller.captions
        onToggled: root.controller.captions = checked
    }
    Miilo.TypeText { typography: root.context.theme.typography; color: root.context.theme.foreground; text: "Wake phrase"; Layout.topMargin: root.context.theme.gap }
    Controls.Field {
        context: root.context; text: root.voice.wakePhrase; Accessible.name: "Wake phrase"
        onEditingFinished: if (text.trim() !== root.voice.wakePhrase) root.voice.saveSettings(text.trim(), root.voice.silenceMs)
    }
    RowLayout {
        Layout.fillWidth: true
        Miilo.TypeText { typography: root.context.theme.typography; color: root.context.theme.foreground; text: "Pause before sending"; Layout.fillWidth: true }
        Controls.Choice {
            context: root.context; Layout.preferredWidth: 100
            model: ["0.7 s", "1 s", "1.5 s", "2 s", "2.5 s"]
            currentIndex: [700,1000,1500,2000,2500].indexOf(root.voice.silenceMs)
            onActivated: root.voice.saveSettings(root.voice.wakePhrase, [700,1000,1500,2000,2500][currentIndex])
            Accessible.name: "Pause before sending"
        }
    }
    Miilo.TypeText {
        typography: root.context.theme.typography; role: "small"; color: root.context.theme.foreground; Layout.fillWidth: true
        text: root.controller.playback.ready ? "Spoken replies ready." : "Configure your speech endpoint with miilo-voice-session configure-playback."
    }
    RowLayout {
        spacing: root.context.theme.gap
        Controls.Action { context: root.context; text: "Recheck"; onClicked: root.controller.playback.probe() }
        Controls.Action { context: root.context; text: "Test playback"; enabled: root.controller.playback.ready && !root.controller.playback.busy; onClicked: root.controller.playback.preview() }
    }
    Miilo.TypeText { typography: root.context.theme.typography; role: "small"; color: root.context.theme.foreground; text: "Mute anywhere: Super+Ctrl+M (when configured)."; Layout.fillWidth: true }
    Controls.Action { context: root.context; text: "Superwhisper settings"; onClicked: { root.controller.stop(); provider.settings(); } }
    Miilo.NativeDictation { id: provider; active: root.visible }
    onVisibleChanged: if (!visible && root.controller.playback.previewing) root.controller.playback.cancel()
    Component.onDestruction: if (root.controller.playback.previewing) root.controller.playback.cancel()
}
