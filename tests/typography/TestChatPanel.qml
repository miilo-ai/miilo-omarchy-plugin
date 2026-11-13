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
    Chat.ChatPanel { id: panel; loadVoiceSettings: false; width: 600; height: 600; theme: theme; surface: surface; visible: false }
    TestCase {
        name: "MiiloChatPanel"
        when: true
        function init() {
            var peer = Quickshell.env("MIILO_CHAT_TEST_PEER");
            findChild(panel,"chat-session").program = peer;
            var handsFree=findChild(panel,"chat-hands-free");
            handsFree.program=peer;handsFree.prefix=[];
            var voice = findChild(panel,"native-dictation");
            voice.program = peer; voice.selector = peer; voice.prefix = [];
        }
        function cleanup() { panel.visible = false; tryCompare(findChild(panel,"chat-session"),"busy",false); }
        onCompletedChanged: if (completed) console.log(qtest_results.failCount === 0 ? "MIILO_CHAT_PANEL_OK" : "MIILO_CHAT_PANEL_FAILED",qtest_results.passCount,qtest_results.failCount)
        function test_chat_controls_follow_shared_alignment_and_input_tokens() {
            panel.visible = true; wait(40);
            var back = findChild(panel,"chat-back"), title = findChild(panel,"chat-title");
            var consent = findChild(panel,"chat-consent"), draft = findChild(panel,"chat-draft");
            var backCenter = back.mapToItem(panel,back.width/2,back.height/2);
            var titleCenter = title.mapToItem(panel,title.width/2,title.height/2);
            verify(Math.abs(backCenter.y-titleCenter.y)<=1,"header icon and title share a vertical center");
            verify(Math.abs(consent.indicator.y+consent.indicator.height/2-consent.height/2)<=1,"checkbox indicator is vertically centered");
            compare(consent.contentItem.verticalAlignment,Text.AlignVCenter);
            compare(draft.background.color,theme.inset);
            compare(draft.background.radius,theme.radius);
        }
        function test_empty_chat_is_compact_and_dictation_is_aligned() {
            findChild(panel,"chat-session").reset();
            panel.visible = true; wait(40);
            var row = findChild(panel,"chat-dictation-row");
            var microphone = findChild(panel,"chat-dictation-button");
            var status = findChild(panel,"chat-dictation-status");
            var settings = findChild(panel,"chat-dictation-settings");
            var draft = findChild(panel,"chat-draft"), consent = findChild(panel,"chat-consent");
            compare(findChild(panel,"chat-conversation").visible,false);
            compare(settings.kind,"settings");
            compare(status.verticalAlignment,Text.AlignVCenter);
            var iconCenter = microphone.mapToItem(panel,0,microphone.height/2);
            var textCenter = status.mapToItem(panel,0,status.height/2);
            verify(Math.abs(iconCenter.y-textCenter.y)<=1,"dictation icon and status share a vertical center");
            var draftBottom = draft.mapToItem(panel,0,draft.height).y;
            verify(row.mapToItem(panel,0,0).y-draftBottom<=theme.gap+1,"dictation follows the draft without a stretched gap");
            verify(draft.mapToItem(panel,0,0).y-consent.mapToItem(panel,0,consent.height).y<=theme.gap+1);
            var tip = findChild(settings,"toolbar-tooltip");
            verify(tip);
            compare(tip.contentItem.textFormat,Text.PlainText);
            compare(tip.contentItem.color,theme.tooltipText);
            compare(tip.background.radius,theme.radius);
            compare(tip.background.color,theme.tooltipSurface);
            theme.tooltipSurface = Qt.rgba(0.1,0.2,0.3,0.65);
            compare(tip.background.color,theme.tooltipSurface);
            theme.tooltipSurface = Qt.binding(()=>theme.surface);
        }
        function test_hands_free_respects_mute_consent_and_session_boundaries() {
            var handsFree=findChild(panel,"chat-hands-free"), session=findChild(panel,"chat-session");
            session.reset(); panel.sessionUnlocked=true; panel.visible=true;
            var consent=findChild(panel,"chat-consent"); consent.checked=true;
            handsFree.armed=true; handsFree.muted=true;
            handsFree.receive(JSON.stringify({type:"transcript",text:"Muted question"}));
            compare(session.busy,false);compare(session.value("history").length,0);
            handsFree.muted=false;
            handsFree.receive(JSON.stringify({type:"transcript",text:"Synthetic question"}));
            tryVerify(()=>session.value("phase")==="done");
            compare(session.value("history").length,2);
            consent.checked=false;
            compare(handsFree.armed,false);compare(handsFree.muted,true);
            handsFree.receive(JSON.stringify({type:"transcript",text:"Late question"}));
            compare(session.value("history").length,2);
            consent.checked=true;handsFree.armed=true;handsFree.muted=false;
            panel.sessionUnlocked=false;compare(handsFree.armed,false);compare(handsFree.muted,true);
            panel.sessionUnlocked=true;handsFree.armed=true;handsFree.muted=false;
            panel.visible=false;compare(handsFree.armed,false);compare(handsFree.muted,true);
        }
        function test_hands_free_toggle_can_enable_sharing_in_place() {
            panel.visible=true;panel.sessionUnlocked=true;
            var consent=findChild(panel,"chat-consent"), options=findChild(panel,"chat-voice-options");
            consent.checked=false;options.open();wait(50);
            var toggle=findChild(options,"hands-free-toggle"), handsFree=findChild(panel,"chat-hands-free");
            verify(toggle.enabled,"unlocked users can enable hands-free directly");
            compare(consent.checked,false);compare(handsFree.armed,false);
            mouseClick(toggle);
            tryCompare(consent,"checked",true);tryCompare(handsFree,"armed",true);
            tryCompare(handsFree,"phase","waiting");
            handsFree.mute();tryCompare(handsFree,"phase","muted");
            wait(350);compare(handsFree.muted,true);
            handsFree.disarm();options.close();
        }
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
