import QtQuick
import QtTest
import Quickshell
import Quickshell.Io
import "../../ui/components" as Miilo

Item {
    id: root
    width: 400; height: 200
    FileView { id: fixture; path: Quickshell.env("MIILO_DICTATION_TEST_STATE"); printErrors: false }
    Miilo.NativeDictation {
        id: voice
        program: Quickshell.env("MIILO_DICTATION_TEST_PEER")
        selector: program
        prefix: []
        focusSafe: true
        onMessageChanged: console.log("DICTATION_STATE", phase, message)
    }
    TestCase {
        name: "NativeDictation"
        when: true
        onCompletedChanged: if (completed) console.log(qtest_results.failCount === 0 ? "MIILO_DICTATION_OK" : "MIILO_DICTATION_FAILED", qtest_results.passCount, qtest_results.failCount)
        function prepare(value) {
            voice.active = false;
            tryCompare(voice, "owned", false);
            tryCompare(voice, "busy", false);
            fixture.setText(JSON.stringify(value));
            wait(60);
            voice.focusSafe = true;
            voice.active = true;
            wait(100);
            tryCompare(voice, "busy", false);
        }
        function cleanup() { console.log("DICTATION_CASE",qtest_results.functionName,qtest_results.failed ? "FAILED" : "passed",voice.phase,voice.message); voice.active = false; tryCompare(voice,"owned",false); tryCompare(voice,"busy",false); }
        function test_start_stop_confirms_new_transcript() {
            prepare({phase:"idle",ready:true});
            verify(voice.available);
            voice.start();
            tryCompare(voice, "recording", true);
            tryCompare(voice, "busy", false);
            voice.stop();
            tryCompare(voice, "owned", false);
            verify(voice.message.includes("Review your draft"));
        }
        function test_focus_loss_cancels_owned_recording() {
            prepare({phase:"idle",ready:true});
            voice.start(); tryCompare(voice,"recording",true);
            voice.focusSafe = false;
            tryCompare(voice,"owned",false);
            verify(voice.message.includes("cancelled"));
        }
        function test_hiding_cancels_owned_recording() {
            prepare({phase:"idle",ready:true});
            voice.start(); tryCompare(voice,"recording",true);
            voice.active = false;
            tryCompare(voice,"owned",false);
            verify(voice.message.includes("cancelled"));
        }
        function test_foreign_recording_is_not_claimed() {
            prepare({phase:"recording",ready:true});
            voice.start(); tryCompare(voice,"busy",false);
            compare(voice.owned,false); compare(voice.recording,false);
            compare(voice.phase,"recording");
        }
        function test_warming_is_not_recording() {
            prepare({phase:"warming",ready:false});
            voice.start(); tryCompare(voice,"busy",false);
            compare(voice.owned,false);
        }
        function test_malformed_status_fails_closed() {
            prepare({invalid:true});
            compare(voice.available,false);
            verify(voice.message.includes("Cannot read"));
        }
        function test_unconfigured_backend_does_not_start() {
            prepare({unconfigured:true});
            compare(voice.available,false);
            voice.start(); wait(50); compare(voice.owned,false);
        }
        function test_failed_start_is_not_reported_as_listening() {
            prepare({phase:"idle",ready:true,fail_action:"start"});
            voice.start(); wait(100); tryCompare(voice,"owned",false);
            verify(voice.message.includes("command failed"));
            compare(voice.recording,false);
        }
        function test_status_timeout_fails_closed() {
            voice.commandTimeout = 150;
            prepare({hang:true});
            tryCompare(voice,"busy",false);
            compare(voice.available,false); compare(voice.owned,false);
            voice.commandTimeout = 8000;
        }
        function test_lost_focus_during_preflight_does_not_record() {
            prepare({phase:"idle",ready:true});
            voice.focusSafe = false;
            voice.start(); wait(100); tryCompare(voice,"busy",false);
            compare(voice.owned,false); compare(voice.recording,false);
        }
    }
}
