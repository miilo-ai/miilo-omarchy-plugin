import QtQuick
import QtTest
import "../../ui/components" as Miilo
import "../../vendor/owl" as Owl

Item {
    width: 650; height: 650
    Owl.MiiloTypography { id: typeSystem }
    QtObject {
        id: palette
        property var typography: typeSystem
        property int generation: 0
        function ink(name) { return name === "background" ? "#18202c" : "#b9d9ff" }
    }
    QtObject {
        id: state
        property var widget: palette
        property var values: ({robotMotion:"full",robotPace:"normal",robotPersonality:"expressive",leftHanded:false,previewRobots:false,robotColors:[],actors:[],selectableProviders:[],system:""})
        function viewValue(name) { return values[name] }
        function setViewState(name, value) { var next = Object.assign({}, values); next[name] = value; values = next; palette.generation++ }
    }
    Miilo.InteractionTheme { id: theme; widget: palette; typography: typeSystem }
    Miilo.DesktopSettings { id: panel; visible: false; width: 600; height: 600; surface: state; theme: theme }
    Miilo.LoadingCrew { id: loading; visible: false; widget: palette; theme: theme }
    SignalSpy { id: closeSpy; target: panel; signalName: "closed" }
    TestCase {
        name: "MiiloDesktopSettings"
        when: true
        onCompletedChanged: if (completed) console.log(qtest_results.failCount === 0 ? "MIILO_SETTINGS_OK" : "MIILO_SETTINGS_FAILED", qtest_results.passCount, qtest_results.failCount)
        function init() { panel.visible = true; panel.width = 600; panel.section = "appearance"; closeSpy.clear(); wait(50) }
        function cleanup() { console.log("SETTINGS_CASE",qtest_results.functionName,qtest_results.failed ? "FAILED" : "passed"); panel.visible = false }
        function test_loading_respects_reduced_motion_and_visibility() {
            var robot = findChild(loading,"loadingRobot"); verify(robot);
            compare(robot.active,false); loading.visible = true;
            compare(robot.motion,"reduced");
            var clock = robot.clock; wait(60); compare(robot.clock,clock);
            loading.visible = false; compare(robot.active,false);
        }
        function test_preferences_write_existing_state() {
            var motion = findChild(panel,"robotMotionSetting"); verify(motion);
            motion.currentIndex = 2; motion.activated(2);
            compare(state.values.robotMotion,"off");
            motion.currentIndex = 0; motion.activated(0);
            compare(state.values.robotMotion,"full");
        }
        function test_registered_remote_systems() {
            state.setViewState("allProviders",[{id:"local",name:"Coding session"},{id:"remote",name:"Workshop factory",kind:"automation_factory",health:"healthy"}]);
            state.setViewState("localSessionIds",["local"]);
            panel.section = "systems";
            var overview = findChild(panel,"connectionsOverview"); verify(overview);
            tryVerify(() => overview.remote.length === 1);
            compare(overview.remote[0].name,"Workshop factory");
            tryVerify(() => findChild(overview,"connectionName") !== null);
            compare(findChild(overview,"connectionName").text,"Workshop factory");
        }
        function test_sections_and_narrow_navigation() {
            panel.section = "chat";
            tryCompare(findChild(panel,"chatNavigation"),"selected",true);
            compare(findChild(panel,"appearanceNavigation").selected,false);
            verify(!findChild(panel,"setupTerminalLoader").active,"Selecting a section must not start a command");
            panel.width = 320;
            var navigation = findChild(panel,"settingsNavigation");
            tryCompare(navigation,"visible",true);
            navigation.currentIndex = 1; navigation.activated(1);
            compare(panel.section,"filters");
            wait(50); mouseClick(findChild(panel,"settingsBack")); tryCompare(closeSpy,"count",1);
        }
    }
}
