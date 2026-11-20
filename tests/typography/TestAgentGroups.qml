import QtQuick
import QtQuick.Controls
import QtTest
import "../../ui/components" as Miilo
import "../../vendor/owl" as Owl
import "../../ui/components/onboarding" as Crew

Item {
    width: 500; height: 500
    Owl.MiiloTypography { id: typeSystem }
    QtObject {
        id: palette
        property real dp: 1
        property var typography: typeSystem
        function ink(name) { return name === "background" ? "#111111" : "#eeeeee" }
    }
    Miilo.InteractionTheme { id: theme; widget: palette; typography: typeSystem }
    QtObject { id: controller; property var draft: ({kind:"all"}) }
    Crew.GroupEditor { id: editor; width: 500; height: 500; widget: palette; theme: theme; controller: controller }
    TestCase {
        name: "AgentGroups"
        when: true
        onCompletedChanged: if (completed) console.log(qtest_results.failCount === 0 ? "MIILO_GROUPS_OK" : "MIILO_GROUPS_FAILED")
        function test_kind_roundtrip() {
            var choice = findChild(editor, "groupKind"); verify(choice);
            var kinds = ["all", "codex", "cursor", "opencode", "devin", "claude", "grok", "hermes"];
            for (var i = 0; i < kinds.length; i++) {
                controller.draft = ({kind:kinds[i]});
                compare(choice.currentIndex, i);
                compare(editor.rule().kind, kinds[i]);
            }
            controller.draft = ({kind:"unknown"});
            compare(editor.rule().kind, "all");
        }
        function test_group_form_uses_translucent_theme_controls() {
            var future=findChild(editor,"futureMatches");verify(future);
            var originalInset=theme.inset, originalSelected=theme.selectedFill;
            try {
                theme.inset=Qt.rgba(0.2,0.3,0.4,0.08);
                theme.selectedFill=Qt.rgba(0.3,0.5,0.6,0.18);
                compare(editor.background,null);
                future.checked=false;compare(future.indicator.color,theme.inset);
                future.checked=true;compare(future.indicator.color,theme.selectedFill);
                theme.selectedFill=Qt.rgba(0.6,0.4,0.2,0.12);
                compare(future.indicator.color,theme.selectedFill);
            } finally { future.checked=false;theme.inset=originalInset;theme.selectedFill=originalSelected; }
        }
        function test_scrollbar_is_hidden_without_overflow_and_tracks_the_right_edge() {
            var bar=editor.ScrollBar.vertical;
            try {
                editor.height=1000;
                tryCompare(bar,"size",1);
                compare(bar.visible,false);
                editor.height=100;
                tryVerify(()=>bar.size<1);
                compare(bar.visible,true);
                compare(bar.parent,editor);
                compare(bar.x+bar.width,editor.width);
                compare(bar.height,editor.availableHeight);
            } finally { editor.height=500; }
        }
    }
}
