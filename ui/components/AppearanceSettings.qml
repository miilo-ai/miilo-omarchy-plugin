pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "onboarding/controls" as Controls

ColumnLayout {
    id: root
    required property var context
    property int agentIndex: 0
    readonly property var agents: context.read("actors") || []
    readonly property string agentKey: agents[agentIndex] ? agents[agentIndex]._key : ""
    readonly property var overrides: context.read("robotColors") || []
    spacing: 10
    SettingsChoice { context: root.context; label: "Tasks per card"; stateKey: "detailTaskLimit"; options: ["3", "5 (default)", "8", "10"]; values: [3, 5, 8, 10] }
    SettingsChoice { context: root.context; label: "Personality"; stateKey: "robotPersonality"; options: ["Calm", "Expressive"]; values: ["calm", "expressive"] }
    SettingsChoice { context: root.context; label: "Motion"; stateKey: "robotMotion"; options: ["Full", "Reduced", "Off"]; values: ["full", "reduced", "off"] }
    SettingsChoice { context: root.context; visible: root.context.read("robotMotion") !== "off"; label: "Pace"; stateKey: "robotPace"; options: ["Slow", "Normal", "Lively"]; values: ["slow", "normal", "lively"] }
    SettingsChoice { context: root.context; label: "Controls"; stateKey: "leftHanded"; options: ["Right handed", "Left handed"]; values: [false, true] }
    SettingsChoice { context: root.context; label: "Preview robots"; stateKey: "previewRobots"; options: ["Hidden", "Shown"]; values: [false, true] }
    TypeText {
        typography: root.context.theme.typography; role: "body"
        text: "Robot colors"; color: root.context.theme.foreground
        font.weight: Font.DemiBold
        Layout.topMargin: 6
    }
    Controls.Choice {
        context: root.context; Layout.fillWidth: true
        Accessible.name: "Robot"
        model: root.agents.map(a => a.name)
        enabled: root.agents.length > 0
        onActivated: root.agentIndex = currentIndex
    }
    Controls.Choice {
        context: root.context; Layout.fillWidth: true
        Accessible.name: "Robot color"
        model: ["Automatic", "Blue", "Green", "Purple", "Orange", "Cyan", "Red"]
        enabled: root.agentKey !== ""
        currentIndex: {
            var choice = root.overrides.find(p => p.key === root.agentKey);
            return choice ? choice.color + 1 : 0;
        }
        onActivated: {
            var next = root.overrides.filter(p => p.key !== root.agentKey);
            if (currentIndex > 0) next.push({key: root.agentKey, color: currentIndex - 1});
            root.context.write("robotColors", next);
        }
    }
}
