import QtQuick
import QtTest
import "../../ui/components" as Miilo
import "../../vendor/owl" as Owl
import "../../ui/components/onboarding" as Crew

Item {
    width: 900; height: 800
    Owl.MiiloTypography { id: typeSystem }
    QtObject {
        id: palette
        property real dp: 1
        property var typography: typeSystem
        property string sansFamily: "sans-serif"
        property string monoFamily: "monospace"
        function ink(name) { return name === "background" ? "#111111" : "#eeeeee" }
    }
    // Binding through a different id avoids a same-name property lookup.
    Miilo.InteractionTheme { id: theme; widget: palette; typography: typeSystem; accent: "#73b8ff" }
    Miilo.LocalImport { id: importer; width: 320; height: 480; widget: palette; theme: theme; active: false }
    Owl.OwlNode {
        id: rendered
        x: 400; width: 240
        widget: palette
        node: ({kind:"Text", p:{text:"A multiline answer with fallback glyphs: العربية 日本語. Text must wrap and remain readable.", style:"body"},h:{},a:{},c:[]})
    }
    Miilo.TypeText { id: plain; typography: typeSystem; width: 240; text: "<b>Evidence stays literal</b>" }
    Crew.RobotPortrait { id: portrait; width: 64; height: 64; motion: "reduced"; active: true }
    Owl.OwlNode {
        id: clickableTile
        x: 650; y: 400; width: 200; height: 160
        visible: false
        widget: palette
        property int tileClicks: 0
        property int taskClicks: 0
        node: ({kind:"Column",p:{width:200,height:160},a:{},
            h:{onTap:()=>{clickableTile.tileClicks++}},c:[
                {kind:"Row",p:{width:200,height:40},a:{},
                    h:{onTap:()=>{clickableTile.taskClicks++}},c:[]}
            ]})
    }
    TestCase {
        name: "MiiloTypography"
        when: true
        onCompletedChanged: if (completed) console.log(qtest_results.failCount === 0 ? "MIILO_TYPOGRAPHY_OK" : "MIILO_TYPOGRAPHY_FAILED", qtest_results.passCount, qtest_results.failCount)
        function init() {
            importer.width = 320;
            typeSystem.profile = "desktop"; typeSystem.textScale = 1;
            importer.controller.mode = "invite";
            importer.controller.agents = [{name:"Codex with a very long setup name", locations:["/tmp/long/path"], observationSupported:true}];
        }
        function cleanup() { console.log("TYPE_CASE", qtest_results.functionName, qtest_results.failed ? "FAILED" : "passed") }
        function test_nested_tile_and_task_clicks() {
            clickableTile.visible = true;
            wait(50);
            mouseClick(clickableTile,100,100);
            compare(clickableTile.tileClicks,1);
            mouseClick(clickableTile,100,20);
            compare(clickableTile.taskClicks,1);
            compare(clickableTile.tileClicks,1,"Task selection must not also navigate its parent tile");
            clickableTile.visible = false;
        }
        function test_desktop_and_phone_widths_data() {
            return [{tag:"desktop",profile:"desktop",scale:1,width:900},
                {tag:"narrow",profile:"desktop",scale:1,width:320},
                {tag:"phone",profile:"phone",scale:1,width:360},
                {tag:"large",profile:"phone",scale:2,width:320}];
        }
        function test_desktop_and_phone_widths(data) {
            importer.width = data.width;
            typeSystem.profile = data.profile; typeSystem.textScale = data.scale;
            var scroll = findChild(importer,"onboardingScroll");
            var review = findChild(importer,"reviewButton");
            tryVerify(() => review.width <= scroll.availableWidth - 32);
            verify(review.contentItem.paintedWidth <= review.contentItem.width + 1);
        }
        function test_crew_paths_expand_and_availability_is_explicit() {
            var path = findChild(importer,"setupPath"); verify(path);
            verify(!path.text.includes("/tmp/long/path"));
            var row = findChild(importer,"setupRow"); verify(row);
            row.expanded = true;
            tryVerify(() => path.text.includes("/tmp/long/path"));
            compare(path.color, theme.pathText);
            importer.width = 320; typeSystem.textScale = 2;
            tryVerify(() => path.paintedWidth <= path.width + 1);
            importer.controller.agents = [{name:"Unsupported agent",locations:["/tmp/config"],observationSupported:false}];
            var status = findChild(importer,"setupStatus"); verify(status);
            compare(status.available, false);
            compare(findChild(importer,"reviewButton").enabled, false);
        }
        function test_unavailable_session_is_disabled_for_mouse_and_keyboard() {
            importer.controller.selected = [];
            importer.controller.mode = "review";
            importer.controller.rows = [{header:false,group:0,session:{kind:"unsupported",id:"one",name:"Unavailable",observable:false}}];
            var list = findChild(importer,"sessionList");
            tryVerify(() => list.currentItem !== null);
            compare(list.currentItem.enabled, false);
            list.forceActiveFocus(); keyClick(Qt.Key_Space);
            compare(importer.controller.selected.length,0);
        }
        function test_portrait_reduced_off_and_hidden_stop_clock() {
            portrait.motion = "reduced";
            var initial = portrait.clock; wait(60); compare(portrait.clock, initial);
            portrait.motion = "full"; wait(80); verify(portrait.clock > initial);
            portrait.motion = "off";
            initial = portrait.clock; wait(60); compare(portrait.clock, initial);
            portrait.active = false; portrait.motion = "full";
            initial = portrait.clock; wait(60); compare(portrait.clock, initial);
            portrait.motion = "reduced"; portrait.active = true;
        }
        function test_roles_and_plain_text() {
            compare(typeSystem.size("title"),16); compare(typeSystem.size("body"),13);
            typeSystem.profile = "phone"; compare(typeSystem.size("body"),16);
            typeSystem.textScale = 2; compare(typeSystem.size("body"),32);
            compare(plain.textFormat, Text.PlainText);
        }
        function test_narrow_enlarged_onboarding_scrolls() {
            typeSystem.profile = "phone"; typeSystem.textScale = 2;
            var scroll = findChild(importer,"onboardingScroll"); verify(scroll);
            tryVerify(() => scroll.contentHeight > scroll.availableHeight);
            verify(scroll.contentWidth <= scroll.width);
            var review = findChild(importer,"reviewButton"); verify(review);
            tryVerify(() => review.width <= scroll.availableWidth - 32);
            verify(review.contentItem.paintedWidth <= review.contentItem.width + 1);
            verify(review.implicitHeight >= review.contentItem.implicitHeight);
            var page = scroll.contentItem;
            // The complete action region can be reached at the bottom.
            page.contentY = scroll.contentHeight - scroll.availableHeight;
            tryVerify(() => page.contentY > 0);
        }
        function test_renderer_text_scale_is_independent_of_geometry() {
            wait(50);
            var initial = rendered.implicitHeight;
            verify(initial > 0);
            palette.dp = 2; wait(30);
            compare(rendered.implicitHeight,initial);
            typeSystem.textScale = 2;
            tryVerify(() => rendered.implicitHeight > initial);
            palette.dp = 1;
        }
        function test_wrapped_session_rows_grow() {
            importer.controller.mode = "review";
            importer.controller.rows = [{header:false, group:0, session:{kind:"codex", id:"one", name:"A very long descriptive session name that should wrap rather than disappear", cwd:"/tmp/a/long/project/path/with/many/segments", observable:true}}];
            typeSystem.textScale = 2;
            var list = findChild(importer,"sessionList"); verify(list);
            tryVerify(() => list.currentItem !== null);
            tryVerify(() => list.currentItem.implicitHeight > 64);
            var content = list.currentItem.contentItem;
            for (var i = 0; i < content.children.length; i++) {
                var label = content.children[i];
                verify(label.x + label.width <= content.width + 1);
            }
        }
        function test_setup_labels_center_on_robot_and_status_icon() {
            importer.width = 900;
            var row = findChild(importer,"setupRow"); verify(row);
            row.expanded = false;
            var robot = findChild(row,"setupRobot"), name = findChild(row,"setupName");
            var status = findChild(row,"setupStatus"), label = findChild(row,"setupStatusLabel");
            tryVerify(() => Math.abs(robot.mapToItem(row,0,robot.height/2).y - name.mapToItem(row,0,name.height/2).y) < 1);
            verify(Math.abs(status.mapToItem(row,0,status.height/2).y - label.mapToItem(row,0,label.height/2).y) < 1);
            typeSystem.profile = "phone";
            tryVerify(() => row.implicitHeight >= typeSystem.touchTarget);
        }
        function test_group_rows_have_centered_robots_right_checks_and_indented_sessions() {
            importer.width = 900;
            importer.controller.mode = "review";
            importer.controller.selected = [];
            importer.controller.grouped = [{name:"Codex",sessions:[{kind:"codex",id:"one",name:"A session",cwd:"/tmp/project",observable:true}]}];
            importer.controller.collapsed = ({});
            importer.controller.rebuildRows();
            var list = findChild(importer,"sessionList"); list.currentIndex = 0;
            tryVerify(() => list.currentItem && list.currentItem.modelData.header && list.currentItem.width > 0);
            var header = list.currentItem, robot = findChild(header,"groupRobot");
            var title = findChild(header,"sessionTitle"), check = findChild(header,"sessionCheckbox");
            tryVerify(() => Math.abs(robot.mapToItem(header,0,robot.height/2).y - title.mapToItem(header,0,title.height/2).y) < 1);
            compare(check.width,16); compare(check.height,16);
            verify(check.x > header.width/2); verify(!title.text.includes("▾") && !title.text.includes("▸"));
            var headerTextX = title.mapToItem(list,0,0).x;
            mouseClick(header,header.width-18,header.height/2);
            compare(importer.controller.selected.length,1);
            list.currentIndex = 1;
            tryVerify(() => list.currentItem && !list.currentItem.modelData.header);
            verify(findChild(list.currentItem,"sessionTitle").mapToItem(list,0,0).x > headerTextX);
        }
    }
}
