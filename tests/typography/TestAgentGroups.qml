import QtQuick
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
    }
}
