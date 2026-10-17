import QtQuick
import QtTest
import "../../ui/components" as Miilo
import "../../vendor/owl" as Owl

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
        function test_setup_paths_reflow_and_availability_is_explicit() {
            importer.width = 900;
            var path = findChild(importer,"setupPath"); verify(path);
            tryVerify(() => path.parent.inlinePath);
            compare(path.color, theme.pathText);
            importer.width = 320;
            tryVerify(() => !path.parent.inlinePath);
            importer.controller.agents = [{name:"Unsupported agent",locations:["/tmp/config"],observationSupported:false}];
            var status = findChild(importer,"setupStatus"); verify(status);
            compare(status.available, false);
            compare(findChild(importer,"reviewButton").enabled, false);
            path = findChild(importer,"setupPath");
            compare(path.color, palette.ink("muted"));
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
        }
    }
}
