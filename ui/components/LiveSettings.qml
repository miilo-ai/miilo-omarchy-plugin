import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "onboarding/controls" as Controls

ColumnLayout {
    id: root
    required property var context
    required property var live
    spacing: 12
    TypeText {typography:root.context.theme.typography;role:"small";color:root.context.theme.foreground;Layout.fillWidth:true;text:"Monitor only your selected observations. Background monitoring continues after closing the dashboard. Notification text excludes work titles, paths and transcripts."}
    Controls.Action {context:root.context;text:"Observe chosen sessions";enabled:!root.live.busy;onClicked:root.live.add("one",Quickshell.env("HOME")+"/.local/bin/miilo-owl","")}
    Controls.Toggle {context:root.context;text:"Background monitoring";checked:root.live.config.enabled;enabled:!root.live.busy&&root.live.config.sources.length>0;onClicked:root.live.enable(checked)}
    Controls.Toggle {context:root.context;text:"Completion notifications";checked:root.live.config.completions;enabled:!root.live.busy;onClicked:root.live.preferences(checked,root.live.config.quiet)}
    Controls.Toggle {context:root.context;text:"Quiet mode";checked:root.live.config.quiet;enabled:!root.live.busy;onClicked:root.live.preferences(root.live.config.completions,checked)}
    TypeText {typography:root.context.theme.typography;role:"small";color:root.context.theme.foreground;text:root.live.error;Layout.fillWidth:true;visible:text.length>0}
    TypeText {typography:root.context.theme.typography;role:"small";color:root.context.theme.foreground;Layout.fillWidth:true;visible:root.live.monitorStale||root.live.deliveryFailed;text:root.live.monitorStale?"Monitoring is not responding. Restart it to reconnect.":"Desktop delivery failed. Activity remains available here."}
    Controls.Action {context:root.context;text:"Restart monitoring";visible:root.live.monitorStale;enabled:!root.live.busy;onClicked:root.live.enable(true)}
    TypeText {Layout.topMargin:12;typography:root.context.theme.typography;color:root.context.theme.foreground;font.weight:Font.DemiBold;text:"Sources"}
    Repeater {
        model:root.live.config.sources
        RowLayout {
            required property var modelData
            Layout.fillWidth:true
            TypeText {typography:root.context.theme.typography;role:"small";color:root.context.theme.foreground;Layout.fillWidth:true;text:"Chosen local and paired observations"}
            Controls.Action {context:root.context;text:"Remove";enabled:!root.live.busy;onClicked:root.live.invoke(["remove",parent.modelData.id])}
        }
    }
    RowLayout {
        Layout.fillWidth:true;Layout.topMargin:12
        TypeText {typography:root.context.theme.typography;color:root.context.theme.foreground;font.weight:Font.DemiBold;Layout.fillWidth:true;text:"Activity"}
        Controls.Action {context:root.context;text:"Mark read";enabled:!root.live.busy;onClicked:root.live.ack()}
    }
    Repeater {
        model:(root.live.state.events||[]).slice(-20).reverse()
        TypeText {
            required property var modelData
            typography:root.context.theme.typography;role:"small";color:root.context.theme.foreground;Layout.fillWidth:true
            text:Qt.formatDateTime(new Date(modelData.at),"hh:mm")+" · "+({failed:"Work failed",attention:"Work needs you",completed:"Work completed",connection_lost:"Observation unavailable",recovered:"Observation recovered"}[modelData.kind]||"Observation updated")
        }
    }
}
