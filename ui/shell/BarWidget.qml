import QtQuick
import Quickshell
import Quickshell.Io
import qs.Ui as Ui
import qs.Commons as Commons
import "../components" as Miilo

Ui.BarWidget {
    id: root
    moduleName: "io.miilo.bar"
    readonly property bool opened: dashboard.opened
    readonly property bool popoutSwitchClosing: false
    readonly property var observation: feed.snapshot
    readonly property int attentionCount: observation.snapshot && observation.snapshot.attention ? observation.snapshot.attention.length : 0
    readonly property bool unavailable: feed.stale || observation.status === "partial" || observation.status === "failed"
    function open() { dashboard.open() }
    function close() { dashboard.close() }
    function toggle() { dashboard.toggle() }
    function closeForPopoutSwitch() { close() }
    implicitWidth: button.implicitWidth
    implicitHeight: button.implicitHeight
    Miilo.ObservationFeed {id:feed;active:root.visible;expanded:dashboard.opened}
    Miilo.LiveController {
        id:live;appName:"Miilo One";statePath:Quickshell.env("HOME")+"/.local/state/miilo-one/live";focused:dashboard.opened&&dashboard.focused
        onOpenRequested:(source,target)=>{dashboard.open();if(target)dashboard.inspect(target);}
    }
    Dashboard { id: dashboard;liveController:live;observationFeed:feed }
    Ui.BarIconButton {
        id: button
        anchors.fill: parent
        bar: root.bar
        tooltipText: root.unavailable ? "Miilo One: check connection" : root.attentionCount ? "Miilo One: " + root.attentionCount + " need attention" : "Open Miilo One"
        Accessible.role: Accessible.Button
        Accessible.name: tooltipText
        Accessible.onPressAction: root.toggle()
        iconComponent: Component {
            Item {
                Miilo.MiiloSymbol {
                    anchors.fill: parent
                    ink: button.foreground
                }
                Rectangle {
                    anchors.top: parent.top; anchors.right: parent.right
                    width: 4; height: 4; radius: 2
                    visible: root.unavailable || root.attentionCount > 0 || live.unread > 0
                    color: root.unavailable ? Commons.Color.urgent : Commons.Color.accent
                }
            }
        }
        onPressed: (code) => { if (code === Qt.LeftButton) root.toggle() }
    }
}
