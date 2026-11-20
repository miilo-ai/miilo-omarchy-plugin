import QtQuick
import QtTest
import Quickshell
import "../../ui/components" as Miilo
import "../../ui/components/chat" as Chat
import "../../vendor/owl" as Owl

Item {
    width:600; height:500
    Owl.MiiloTypography { id:typeSystem }
    QtObject { id:palette; property var typography:typeSystem; function ink(name){return name==="background"?"#18202c":"#b9d9ff";} }
    QtObject { id:surface; property var widget:palette; function viewValue(name){return false;} }
    Miilo.InteractionTheme { id:theme; widget:palette }
    Chat.ChatPanel { id:panel; loadVoiceSettings:false; width:600; height:implicitHeight; theme:theme; surface:surface; visible:false }
    TestCase {
        name:"MiiloChatPanel"; when:true
        onCompletedChanged:if(completed)console.log(qtest_results.failCount===0?"MIILO_CHAT_PANEL_OK":"MIILO_CHAT_PANEL_FAILED",qtest_results.passCount,qtest_results.failCount)
        function init(){
            const peer=Quickshell.env("MIILO_CHAT_TEST_PEER");
            findChild(panel,"chat-session").program=peer;
            const voice=panel.handsFree;voice.program=peer;voice.prefix=[];voice.preferred=true;
            panel.playback.program=peer;panel.playback.prefix=[];panel.playback.ready=true;
            panel.sessionUnlocked=true;panel.visible=true;panel.captions=false;
            findChild(panel,"chat-session").reset();
        }
        function cleanup(){console.log("CHAT_CASE",qtest_results.functionName,qtest_results.failed?"FAILED":"passed");panel.visible=false;tryCompare(panel.playback,"busy",false);tryCompare(findChild(panel,"chat-session"),"busy",false);}
        function test_face_arms_without_a_secondary_screen_or_transcript(){
            panel.openConversation();tryCompare(panel.handsFree,"armed",true);
            compare(panel.composing,false);compare(panel.sharing,true);compare(panel.height,0);
            compare(findChild(panel,"chat-caption").visible,false);
            panel.openConversation();compare(panel.handsFree.armed,false);
        }
        function test_mute_lock_and_close_revoke_capture(){
            panel.openConversation();tryCompare(panel.handsFree,"armed",true);
            panel.handsFree.mute();compare(panel.handsFree.muted,true);
            panel.sessionUnlocked=false;compare(panel.handsFree.armed,false);
            panel.sessionUnlocked=true;panel.openConversation();tryCompare(panel.handsFree,"armed",true);
            panel.visible=false;compare(panel.handsFree.armed,false);compare(panel.sharing,false);
        }
        function test_optional_caption_is_a_compact_plain_text_overlay(){
            panel.captions=true;wait(40);
            verify(panel.height>0&&panel.height<250);
            compare(findChild(panel,"chat-caption").textFormat,Text.PlainText);
        }
        function test_text_composer_is_optional_and_requires_sharing(){
            panel.handsFree.preferred=false;panel.openConversation();wait(40);
            compare(panel.composing,true);compare(panel.handsFree.armed,false);
            const draft=findChild(panel,"chat-draft"),send=findChild(panel,"chat-send");
            draft.text="Synthetic question";compare(send.enabled,false);
            panel.sharing=true;mouseClick(send);
            const session=findChild(panel,"chat-session");tryVerify(()=>session.value("phase")==="done");
            compare(session.value("history").length,2);compare(draft.text,"");
        }
        function test_cancel_and_retry_discard_partial_history(){
            panel.sharing=true;const session=findChild(panel,"chat-session");
            verify(session.send("Slow fixture"));tryVerify(()=>session.value("answer").length>0);
            session.cancel();tryCompare(session,"busy",false);compare(session.value("history").length,0);
            verify(session.send("Retry"));tryVerify(()=>session.value("phase")==="done");compare(session.value("history").length,2);
        }
        function test_changing_context_stops_the_session(){
            panel.openConversation();tryCompare(panel.handsFree,"armed",true);
            panel.target={workKey:"work-1",revisionKey:"revision-2"};
            compare(panel.handsFree.armed,false);compare(panel.sharing,false);
            compare(findChild(panel,"chat-session").value("history").length,0);
        }
    }
}
