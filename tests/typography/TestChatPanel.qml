import QtQuick
import QtTest
import Quickshell
import "../../ui/components" as Miilo
import "../../ui/components/chat" as Chat
import "../../vendor/owl" as Owl

Item {
    width: 600; height: 600
    Owl.MiiloTypography { id: typeSystem }
    QtObject {
        id: palette
        property var typography: typeSystem
        function ink(name) { return name === "background" ? "#18202c" : "#b9d9ff"; }
    }
    QtObject {
        id: surface
        property var widget: palette
        function viewValue(name) { return false; }
    }
    Miilo.InteractionTheme { id: theme; widget: palette }
    Chat.ChatPanel { id: panel; width: 600; height: 600; theme: theme; surface: surface; visible: false }
    TestCase {
        name: "MiiloChatPanel"
        when: true
        function init() {
            var peer = Quickshell.env("MIILO_CHAT_TEST_PEER");
            findChild(panel,"chat-session").program = peer;
            var voice = findChild(panel,"native-dictation");
            voice.program = peer; voice.selector = peer; voice.prefix = [];
        }
        function cleanup() { panel.visible = false; tryCompare(findChild(panel,"chat-session"),"busy",false); }
        onCompletedChanged: if (completed) console.log(qtest_results.failCount === 0 ? "MIILO_CHAT_PANEL_OK" : "MIILO_CHAT_PANEL_FAILED",qtest_results.passCount,qtest_results.failCount)
        function test_draft_requires_consent_and_never_sends_on_open() {
            panel.visible = true; wait(40);
            var session = findChild(panel,"chat-session");
            var draft = findChild(panel,"chat-draft");
            var consent = findChild(panel,"chat-consent");
            var send = findChild(panel,"chat-send");
            verify(session); verify(draft); verify(consent); verify(send);
            compare(session.busy,false); compare(send.enabled,false);
            draft.text = "Synthetic question"; compare(send.enabled,false);
            consent.checked = true; compare(send.enabled,true);
            var voice = findChild(panel,"native-dictation");
            voice.owned = true; compare(send.enabled,false);
            voice.owned = false;
            panel.visible = false;
            compare(consent.checked,false); compare(session.busy,false);
        }
        function test_changing_work_clears_the_conversation() {
            var session = findChild(panel,"chat-session");
            session.state.history = [{role:"user",text:"Synthetic prior turn"}];
            panel.target = {workKey:"work-1",revisionKey:"revision-2"};
            compare(session.state.history.length,0);
            compare(session.state.focus.revisionKey,"revision-2");
        }
        function test_real_process_stream_requires_explicit_send() {
            panel.visible = true;
            var session = findChild(panel,"chat-session");
            var draft = findChild(panel,"chat-draft");
            findChild(panel,"chat-consent").checked = true;
            draft.text = "Synthetic question";
            mouseClick(findChild(panel,"chat-send"));
            tryVerify(() => session.value("phase") === "done");
            compare(session.value("answer"),"Synthetic answer");
            compare(session.value("history").length,2);
            compare(draft.text,"");
        }
        function test_cancel_then_retry_does_not_commit_partial_history() {
            panel.visible = true;
            var session = findChild(panel,"chat-session");
            verify(session.send("Slow fixture"));
            tryVerify(() => session.value("answer").length > 0);
            session.cancel(); tryCompare(session,"busy",false);
            compare(session.value("history").length,0);
            verify(session.send("Synthetic retry"));
            tryVerify(() => session.value("phase") === "done");
            compare(session.value("history").length,2);
        }
    }
}
