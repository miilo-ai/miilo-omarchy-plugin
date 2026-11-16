import QtQuick
import QtTest
import Quickshell
import "../../ui/components" as Miilo
import "../../ui/components/chat" as Chat
import "../../vendor/owl" as Owl

Item {
    width:600;height:500
    Owl.MiiloTypography {id:typeSystem}
    QtObject {id:palette;property var typography:typeSystem;function ink(name){return name==="background"?"#18202c":"#b9d9ff"}}
    QtObject {id:surface;property var widget:palette;function viewValue(name){return false}}
    Miilo.InteractionTheme {id:theme;widget:palette}
    Chat.ChatPanel {id:panel;loadVoiceSettings:false;width:600;height:500;theme:theme;surface:surface;visible:false}
    QtObject {id:fakeVoice;property bool armed:false;property bool muted:true;property string phase:"off";property real level:0;property string error:"";function toggleMute(){muted=!muted}}
    Miilo.VoiceStatus {id:status;theme:theme;voice:fakeVoice}
    SignalSpy {id:faceSpy;target:status;signalName:"startRequested"}
    TestCase {
        name:"MiiloVoicePlayback";when:true
        onCompletedChanged:if(completed)console.log(qtest_results.failCount===0?"MIILO_PLAYBACK_OK":"MIILO_PLAYBACK_FAILED",qtest_results.passCount,qtest_results.failCount)
        function init(){
            var peer=Quickshell.env("MIILO_CHAT_TEST_PEER");
            findChild(panel,"chat-session").program=peer;
            var playback=findChild(panel,"chat-playback");playback.program=peer;playback.prefix=[];playback.ready=true;playback.error="";
            var handsFree=findChild(panel,"chat-hands-free");handsFree.program=peer;handsFree.prefix=[];
            panel.sessionUnlocked=true;panel.visible=true;
            findChild(panel,"chat-session").reset();panel.sharing=true;
            handsFree.armed=true;handsFree.muted=false;
        }
        function cleanup(){panel.visible=false;tryCompare(findChild(panel,"chat-playback"),"busy",false);tryCompare(findChild(panel,"chat-session"),"busy",false)}
        function test_reply_plays_before_listening_resumes_and_mute_cancels(){
            var voice=findChild(panel,"chat-hands-free"),playback=findChild(panel,"chat-playback"),session=findChild(panel,"chat-session");
            voice.receive(JSON.stringify({type:"transcript",text:"Synthetic question"}));
            tryVerify(()=>playback.busy&&playback.phase==="speaking");compare(voice.paused,true);
            tryCompare(playback,"busy",false);compare(voice.paused,false);compare(session.value("history").length,2);
            voice.receive(JSON.stringify({type:"transcript",text:"Follow up"}));
            tryVerify(()=>playback.busy&&playback.phase==="speaking");
            voice.mute();tryCompare(playback,"busy",false);compare(voice.muted,true);
        }
        function test_first_audio_starts_before_the_answer_finishes(){
            const voice=panel.handsFree,playback=panel.playback,session=findChild(panel,"chat-session");
            voice.receive(JSON.stringify({type:"transcript",text:"Slow fixture"}));
            tryVerify(()=>playback.phase==="speaking");
            compare(session.busy,true);compare(session.value("phase"),"streaming");
            voice.mute();tryCompare(playback,"busy",false);tryCompare(session,"busy",false);
            compare(session.value("history").length,0);
        }
        function test_status_distinguishes_wake_input_and_output(){
            compare(status.label,"Voice off");fakeVoice.armed=true;fakeVoice.muted=false;fakeVoice.phase="waiting";compare(status.label,"Wake listening");
            fakeVoice.phase="listening";compare(status.label,"Listening");fakeVoice.level=0.3;compare(status.voice.level,0.3);
            status.outputPhase="speaking";compare(status.label,"Speaking");fakeVoice.muted=true;compare(status.label,"Muted");
            status.outputPhase="";fakeVoice.armed=false;fakeVoice.phase="off";
        }
        function test_face_is_the_only_entry_and_config_readiness_changes_ink(){
            var face=findChild(status,"mainVoiceStatus");verify(face);status.configured=true;
            compare(face.contentItem.ink,theme.foreground);faceSpy.clear();mouseClick(face);compare(faceSpy.count,1);
            status.configured=false;compare(face.contentItem.ink,palette.ink("muted"));
        }
        function test_saved_hands_free_starts_from_the_shared_face_entry(){
            var voice=findChild(panel,"chat-hands-free");voice.disarm();
            panel.sharing=false;voice.preferred=true;
            panel.openConversation();tryCompare(voice,"armed",true);tryCompare(voice,"phase","waiting");
            compare(panel.sharing,true);voice.preferred=false;
        }
        function test_preview_requires_an_explicit_config_action(){
            var voice=findChild(panel,"chat-hands-free"),playback=findChild(panel,"chat-playback");
            voice.disarm();wait(50);compare(playback.busy,false);
            verify(playback.preview());tryVerify(()=>playback.busy&&playback.phase==="speaking");
            panel.visible=false;tryCompare(playback,"busy",false);
        }
    }
}
