import QtQuick
import QtTest
import "../../ui/components" as Miilo
import "../../vendor/owl" as Owl
import "../../ui/components/onboarding/controls" as Controls
import "../../ui/components/onboarding" as Crew

Item {
    width: 480; height: 200
    Owl.MiiloTypography { id: typeSystem }
    QtObject {
        id: palette
        property var typography: typeSystem
        property int generation:0
        property color backgroundColor:"#18202c"
        function ink(name) { return name === "background" ? backgroundColor : "#b9d9ff" }
    }
    Miilo.InteractionTheme { id: theme; widget: palette; typography: typeSystem }
    Miilo.DesktopToolbar { id: toolbar; width: 400; theme: theme }
    Miilo.Dashboard {id:themedWindow;visible:false;interactionTheme:theme}
    QtObject {
        id:overviewState
        property var widget:palette
        property var values:({needsOnly:false,observatoryView:"quiet",query:"",works:[{_key:"w",attention:"approval"}],attention:[],provs:[{id:"p"}]})
        function viewValue(name){return values[name]??null;}
        function setViewState(name,value){var next=Object.assign({},values);next[name]=value;values=next;palette.generation++;}
    }
    Miilo.OverviewControls {id:overview;y:250;width:460;theme:theme;surface:overviewState;visible:false}
    QtObject { id: controlContext; property var theme: toolbar.theme; property var widget: palette; property real height: 200 }
    Controls.Choice { id: groups; context: controlContext; y: 50; width: 180; model: []; enabled: count > 0 }
    Controls.Action { id: action; context: controlContext; y: 90; text: "Rescan" }
    QtObject {
        id: sessions
        property var grouped: []
        property var rows: []
        property var selected: []
    }
    Crew.SessionList { id: sessionList; y: 120; width: 400; height: 100; controller: sessions; widget: palette; theme: toolbar.theme }
    SignalSpy { id: localSpy; target: toolbar; signalName: "localRequested" }
    SignalSpy { id: remoteSpy; target: toolbar; signalName: "remoteRequested" }
    SignalSpy { id: settingsSpy; target: toolbar; signalName: "settingsRequested" }
    SignalSpy { id: refreshSpy; target: toolbar; signalName: "refreshRequested" }
    TestCase {
        name: "MiiloDesktopToolbar"
        when: true
        onCompletedChanged: if (completed) console.log(qtest_results.failCount === 0 ? "MIILO_TOOLBAR_OK" : "MIILO_TOOLBAR_FAILED", qtest_results.passCount, qtest_results.failCount)
        function init() { wait(50); toolbar.busy = false; localSpy.clear(); remoteSpy.clear(); refreshSpy.clear() }
        function cleanup(){overview.visible=false;}
        function test_window_background_covers_native_controls_in_both_modes() {
            const background=findChild(themedWindow,"dashboardBackground");verify(background);
            compare(background.anchors.fill,background.parent);
            compare(background.color,palette.backgroundColor);
            palette.backgroundColor="#f8f9fa";wait(20);
            compare(background.color,palette.backgroundColor);
            palette.backgroundColor="#18202c";
            palette.backgroundColor="#8018202c";wait(20);
            compare(themedWindow.color,Qt.color("transparent"));
            compare(background.color.a,palette.backgroundColor.a);
            compare(themedWindow.surface.paintBackground,false,"the embedded surface must not double-paint theme opacity");
            palette.backgroundColor="#18202c";
        }
        function test_native_overview_navigation_and_compact_search() {
            overview.visible=true;wait(50);
            compare(overview.needsCount,1);
            mouseClick(findChild(overview,"overview-needs"));compare(overviewState.values.needsOnly,true);
            mouseClick(findChild(overview,"overview-detail"));compare(overviewState.values.observatoryView,"orbit");
            const input=findChild(overview,"overview-search-input");verify(!input.visible);
            mouseClick(findChild(overview,"overview-search"));tryVerify(()=>input.activeFocus);
            for(const key of [Qt.Key_R,Qt.Key_E,Qt.Key_V,Qt.Key_I,Qt.Key_E,Qt.Key_W])keyClick(key);
            compare(overviewState.values.query,"review");
            keyClick(Qt.Key_Escape);compare(overviewState.values.query,"");verify(!input.visible);
            overviewState.values={needsOnly:false,observatoryView:"quiet",query:"",works:[],attention:[],provs:[]};palette.generation++;
            verify(!findChild(overview,"overview-search").visible);
        }
        function test_density_and_empty_groups() {
            compare(groups.indicator.visible, false);
            groups.model = ["Project"]; wait(10); compare(groups.indicator.visible, true);
            compare(groups.indicator.y, (groups.height - groups.indicator.height) / 2);
            verify(action.implicitHeight >= theme.controlHeight && action.implicitHeight <= 32);
            typeSystem.profile = "phone"; wait(10); verify(action.implicitHeight >= 48);
            typeSystem.profile = "desktop"; groups.model = [];
            var wordmark = findChild(toolbar, "titleWordmark"); verify(wordmark); compare(wordmark.ink, theme.foreground); compare(findChild(toolbar, "titleRobot"), null);
            var product = findChild(toolbar, "productNameLabel"); verify(product); compare(product.text,"One");verify(product.visible&&product.width>0);
            compare(product.height,36);compare(product.verticalAlignment,Text.AlignVCenter);
            compare(product.y+product.height/2,wordmark.y+wordmark.height/2);
        }
        function test_session_context_only_when_needed() {
            sessions.grouped = [{name:"codex / /example", rule:null, sessions:[]}];
            sessions.rows = [{header:false, group:0, session:{kind:"codex",id:"one",name:"Review changes",cwd:"/example",observable:true}}];
            tryVerify(() => sessionList.currentItem !== null);
            var label = findChild(sessionList.currentItem, "sessionContext"); verify(label);
            compare(label.visible, false);
            sessions.rows = [{header:false, group:0, session:{kind:"codex",id:"one",name:"Review changes",cwd:"/different",observable:true}}];
            tryVerify(() => sessionList.currentItem !== null && findChild(sessionList.currentItem, "sessionContext").text.includes("/different"));
            sessions.rows = [{header:false, group:0, session:{kind:"codex",id:"one",name:"Review changes",cwd:"/example",observable:false}}];
            tryVerify(() => sessionList.currentItem !== null && findChild(sessionList.currentItem, "sessionContext").text === "Import not available yet");
            sessions.rows = [];
        }
        function test_compact_and_busy() {
            var add = findChild(toolbar, "addSystemButton");
            var refresh = findChild(toolbar, "refreshSystemsButton");
            var menu = findChild(toolbar, "systemMenuButton");
            compare(add.height, theme.controlHeight); compare(refresh.height, add.height); compare(menu.height, add.height);
            mouseClick(refresh); compare(refreshSpy.count, 1);
            toolbar.busy = true; mouseClick(refresh); compare(refreshSpy.count, 1);
            verify(!add.enabled); verify(!menu.enabled);
        }
        function test_settings_menu_keyboard_navigation() {
            settingsSpy.clear();
            var menu = findChild(toolbar, "systemMenuButton");
            menu.forceActiveFocus(); keyClick(Qt.Key_Space);
            wait(30); keyClick(Qt.Key_Down); keyClick(Qt.Key_Down); keyClick(Qt.Key_Return);
            tryCompare(settingsSpy, "count", 1); compare(settingsSpy.signalArguments[0][0], "appearance");
        }
        function test_connections_menu_keyboard_navigation() {
            settingsSpy.clear();
            var menu = findChild(toolbar, "systemMenuButton");
            menu.forceActiveFocus(); keyClick(Qt.Key_Space);
            wait(30); keyClick(Qt.Key_Down); keyClick(Qt.Key_Down); keyClick(Qt.Key_Down); keyClick(Qt.Key_Return);
            tryCompare(settingsSpy, "count", 1); compare(settingsSpy.signalArguments[0][0], "systems");
        }
        function test_about_menu_keyboard_navigation() {
            settingsSpy.clear();
            var menu = findChild(toolbar, "systemMenuButton");
            menu.forceActiveFocus(); keyClick(Qt.Key_Space); wait(30);
            for (var i = 0; i < 6; i++) keyClick(Qt.Key_Down);
            keyClick(Qt.Key_Return);
            tryCompare(settingsSpy, "count", 1); compare(settingsSpy.signalArguments[0][0], "about");
        }
        function test_add_menu_keyboard_navigation() {
            var add = findChild(toolbar, "addSystemButton");
            add.forceActiveFocus(); keyClick(Qt.Key_Space);
            wait(30); keyClick(Qt.Key_Down); keyClick(Qt.Key_Return);
            tryCompare(localSpy, "count", 1); compare(remoteSpy.count, 0);
            add.forceActiveFocus(); keyClick(Qt.Key_Space);
            wait(30); keyClick(Qt.Key_Down); keyClick(Qt.Key_Down); keyClick(Qt.Key_Return);
            tryCompare(remoteSpy, "count", 1); compare(localSpy.count, 1);
        }
    }
}
