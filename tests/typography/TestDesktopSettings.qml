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
        property bool active: false
        property real dp: 1
        property string monoFamily: "monospace"
        property var host: ({fieldFocused: function(focused) {}})
        function alpha(color, opacity) { return "transparent" }
        function ink(name) { return name === "background" ? "#18202c" : "#b9d9ff" }
    }
    QtObject {
        id: state
        property var widget: palette
        property var values: ({detailTaskLimit:5,robotMotion:"full",robotPace:"normal",robotPersonality:"expressive",leftHanded:false,previewRobots:false,robotColors:[],actors:[],selectableProviders:[],system:""})
        function viewValue(name) { return values[name] }
        function setViewState(name, value) { var next = Object.assign({}, values); next[name] = value; values = next; palette.generation++ }
    }
    Miilo.InteractionTheme { id: theme; widget: palette; typography: typeSystem }
    Miilo.DesktopSettings { id: panel; visible: false; width: 600; height: 600; surface: state; theme: theme }
    Miilo.LoadingCrew { id: loading; visible: false; widget: palette; theme: theme }
    Owl.OwlTerminal { id: terminal; width: 500; height: 180; visible: false; widget: palette; sessionActive: visible; node: ({p:{command:"printf terminal-ready"}}) }
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
        function test_detail_task_limit() {
            var limit = findChild(panel,"detailTaskLimitSetting"); verify(limit);
            compare(limit.currentIndex,1);
            limit.currentIndex = 3; limit.activated(3);
            compare(state.values.detailTaskLimit,10);
            limit.currentIndex = 1; limit.activated(1);
            compare(state.values.detailTaskLimit,5);
        }
        function test_preferences_write_existing_state() {
            var motion = findChild(panel,"robotMotionSetting"); verify(motion);
            motion.currentIndex = 2; motion.activated(2);
            compare(state.values.robotMotion,"off");
            motion.currentIndex = 0; motion.activated(0);
            compare(state.values.robotMotion,"full");
        }
        function test_settings_terminal_runs_with_paused_feed() {
            compare(palette.active,false);
            terminal.visible = true;
            tryVerify(() => terminal.lines.join(" ").indexOf("terminal-ready") >= 0,3000);
            compare(findChild(terminal,"terminalInput").activeFocusOnTab,true);
            terminal.visible = false;
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
        function test_pairing_is_explicit_and_isolated() {
            panel.section = "pair";
            tryCompare(findChild(panel,"pairNavigation"),"selected",true);
            verify(!findChild(panel,"setupTerminalLoader").active);
            panel.width = 320;
            var navigation = findChild(panel,"settingsNavigation");
            navigation.currentIndex = 4; navigation.activated(4);
            compare(panel.section,"pair");
        }
        function test_about_navigation_and_version() {
            panel.section = "about";
            tryCompare(findChild(panel,"aboutNavigation"),"selected",true);
            var version = findChild(panel,"pluginVersionLabel"); verify(version);
            tryVerify(() => /^Omarchy plugin · \d+\.\d+\.\d+$/.test(version.text));
            verify(findChild(panel,"aboutWebsite").visible);
            verify(findChild(panel,"aboutSponsor").visible);
            for (var name of ["aboutWebsite", "aboutSponsor"]) {
                var link = findChild(panel, name);
                compare(link.text.indexOf("↗"), -1);
                verify(findChild(link, "linkIcon").width >= 18);
            }
            verify(!findChild(panel,"setupTerminalLoader").active);
            var links = findChild(panel, "aboutLinks");
            compare(links.columns, 2);
            compare(findChild(panel, "aboutWebsite").y, findChild(panel, "aboutSponsor").y);
            verify(findChild(panel, "aboutSupportCopy").y < links.y);
            panel.width = 320;
            var navigation = findChild(panel,"settingsNavigation");
            navigation.currentIndex = panel.sections.indexOf("about"); navigation.activated(navigation.currentIndex);
            compare(panel.section,"about");
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
