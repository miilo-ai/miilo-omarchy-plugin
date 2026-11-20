import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root
    required property var theme
    property var voice: null
    property bool compact: false
    property bool configured: false
    property string outputPhase: ""
    readonly property string phase: !voice || !voice.armed ? "off" : voice.muted ? "muted" : outputPhase || voice.phase
    readonly property string label: phase==="off" ? (voice && voice.error ? "Voice unavailable" : "Voice off") : phase==="muted" ? "Muted" : phase==="waiting" ? "Wake listening" : phase==="listening" ? "Listening" : phase==="transcribing" ? "Transcribing" : phase==="speaking" ? "Speaking" : phase==="preparing_playback" ? "Preparing reply" : phase==="paused" ? "Replying" : "Starting voice"
    signal startRequested()
    spacing: theme.gap
    ToolbarButton {
        objectName: "mainVoiceStatus"
        theme: root.theme; circular:true
        kind: "voice"
        label: "Ask Miilo · " + root.label
        contentItem: MiiloSymbol { ink: root.configured ? root.theme.foreground : root.theme.widget.ink("muted") }
        onClicked: root.startRequested()
    }
    Row {
        spacing: 2
        visible: root.phase==="waiting" || root.phase==="listening"
        Repeater {
            model: 3
            Rectangle {
                required property int index
                width: 2; height: 3 + Math.min(13,Math.sqrt(root.voice ? root.voice.level : 0)*40)*(index===1 ? 1 : 0.65); radius:1
                color: root.theme.accent
                anchors.verticalCenter: parent.verticalCenter
            }
        }
        width: 10; height: 16
    }
    TypeText { visible:!root.compact && root.phase!=="off"; typography: root.theme.typography; role:"small"; text:root.label; color:root.theme.foreground; wrapMode:Text.NoWrap }
}
