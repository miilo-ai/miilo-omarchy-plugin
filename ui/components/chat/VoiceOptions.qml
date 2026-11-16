import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".." as Miilo
import "../onboarding/controls" as Controls

Popup {
    id: root
    required property var context
    required property var voice
    property var playback: null
    property bool consent: false
    signal providerSettingsRequested()
    signal enableRequested()
    signal dictationRequested()
    signal previewRequested()
    width: Math.min(420,parent.width-32)
    x: Math.round((parent.width-width)/2)
    y: Math.max(8,Math.round((parent.height-height)/2))
    padding: context.theme.gap * 2
    modal: true; focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    onClosed: if(root.playback && root.playback.previewing)root.playback.cancel()
    background: Rectangle { color: root.context.theme.surface; border.color: root.context.theme.border; border.width: 1; radius: root.context.theme.radius }
    implicitHeight: Math.min(contentItem.implicitHeight+padding*2,parent.height-16)
    contentItem: ScrollView {
        id: scroll
        implicitHeight: form.implicitHeight
        contentWidth: availableWidth
        clip: true
        ColumnLayout {
        id: form
        width: scroll.availableWidth
        spacing: root.context.theme.gap
        Miilo.TypeText { typography: root.context.theme.typography; text:"Voice"; color:root.context.theme.foreground; font.weight:Font.DemiBold }
        Controls.Toggle {
            objectName:"hands-free-toggle"
            context:root.context; text:"Hands-free"; checked:root.voice.preferred
            enabled:root.voice.unlocked
            onToggled: { root.voice.setPreferred(checked); if (checked) root.enableRequested(); checked=Qt.binding(()=>root.voice.preferred); }
        }
        Miilo.TypeText {
            typography:root.context.theme.typography;role:"small";color:root.context.theme.foreground;Layout.fillWidth:true
            text:!root.voice.unlocked ? "Unlock your desktop to enable hands-free." : "Hands-free is remembered: clicking Miilo starts the next voice session. Start with your wake phrase, then speak naturally. Pauses send each turn; listening resumes after the reply finishes. Follow-ups need no wake phrase. While active, nearby speech can also be sent. Spoken turns and observed context go to your configured model; transcription uses Superwhisper’s selected local or cloud model. Spoken answers go to your configured speech provider. Mute stops capture and playback."
        }
        Miilo.TypeText {typography:root.context.theme.typography;role:"small";color:root.context.theme.foreground;text:"Wake phrase";Layout.topMargin:root.context.theme.gap}
        Controls.Field {
            id: phrase; objectName:"wake-phrase-input"; context:root.context; text:root.voice.wakePhrase
            Accessible.name:"Wake phrase"
            onEditingFinished: if (text.trim() !== root.voice.wakePhrase) root.voice.saveSettings(text.trim(),root.voice.silenceMs)
        }
        RowLayout {
            Layout.fillWidth:true;spacing:root.context.theme.gap
            Miilo.TypeText {typography:root.context.theme.typography;role:"small";color:root.context.theme.foreground;text:"Pause before sending";Layout.fillWidth:true}
            Controls.Choice {
                context:root.context;Layout.fillWidth:false;Layout.preferredWidth:100
                model:["0.7 s","1 s","1.5 s","2 s","2.5 s"]
                currentIndex:[700,1000,1500,2000,2500].indexOf(root.voice.silenceMs)
                onActivated: root.voice.saveSettings(root.voice.wakePhrase,[700,1000,1500,2000,2500][currentIndex])
                Accessible.name:"Pause before sending"
            }
        }
        Miilo.TypeText {typography:root.context.theme.typography;role:"small";color:root.context.theme.foreground;Layout.fillWidth:true;visible:!!root.voice.error;text:root.voice.error}
        Miilo.TypeText {typography:root.context.theme.typography;role:"small";color:root.context.theme.foreground;Layout.fillWidth:true;text:root.playback && root.playback.ready ? "Spoken replies ready. Listening pauses during playback." : "Spoken replies are not configured. Run miilo-voice-session configure-playback with your speech endpoint settings."}
        Controls.Action {context:root.context;text:"Recheck playback";onClicked:if(root.playback)root.playback.probe()}
        Controls.Action {context:root.context;text:"Test playback";enabled:root.playback&&root.playback.ready&&!root.playback.busy;onClicked:root.previewRequested()}
        Miilo.TypeText {typography:root.context.theme.typography;role:"small";color:root.context.theme.foreground;Layout.fillWidth:true;text:"Mute anywhere: Super+Ctrl+M (when configured)."}
        Controls.Action {context:root.context;text:"Dictate into draft";onClicked:{root.voice.disarm();root.dictationRequested();root.close();}}
        Controls.Action {context:root.context;text:"Superwhisper settings";onClicked:{root.voice.disarm();root.providerSettingsRequested();root.close();}}
        }
}
}
