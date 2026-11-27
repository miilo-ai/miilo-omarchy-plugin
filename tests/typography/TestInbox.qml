import QtQuick
import QtTest
import Quickshell
import "../../ui/components" as Miilo
import "../../ui/components/intake" as Intake
import "../../vendor/owl" as Owl
Item {
    width: 650; height: 600
    Owl.MiiloTypography { id: typography }
    QtObject {id: palette; function ink(name) { return name === "background" ? "#18202c" : "#b9d9ff" }}
    Miilo.InteractionTheme {id:theme;widget:palette;typography:typography}
    QtObject {
        id: controller
        property bool configured: true
        property bool stale: false
        property bool busy: false
        property string error: ""
        property string message: ""
        property var retryArguments: []
        property string endpoint: ""
        property string tokenFile: ""
        property var items: [{providerId:"custom",id:"task",title:"<img src='http://127.0.0.1:9/no'>",summary:"Synthetic task",revision:"r1",extensions:{"io.miilo.intake":{version:1,decision:"pending",execution:"not_started"}},actions:[{id:"intake.accept",available:true},{id:"intake.defer",available:true},{id:"intake.dismiss",available:true}]}]
        property string chosen: ""
        function refresh() {}
        function retry() {}
        function decide(item,action) { chosen=action }
    }
    Intake.InboxController { id: actualController; active: false }
    Intake.InboxPanel {id:panel;anchors.fill:parent;theme:theme;controller:controller}
    TestCase {
        name: "MiiloInbox"
        when: true
        onCompletedChanged: if (completed) console.log(qtest_results.failCount === 0 ? "MIILO_INBOX_OK" : "MIILO_INBOX_FAILED")
        function test_actions_and_stale_state() {
            const accept=findChild(panel,"intakeAccept");verify(accept!==null);verify(accept.enabled);
            mouseClick(accept);compare(controller.chosen,"accept");
            controller.stale=true;verify(!accept.enabled);controller.stale=false;
            verify(panel.height>0);compare(panel.theme.surface,theme.surface);
        }
        function test_controller_configuration_loads_without_starting_capture() {
            if (Quickshell.env("MIILO_INTAKE_PERSIST_CHECK") === "1") compare(actualController.socketFile,"/example/intake.sock");
            actualController.transport="socket";actualController.socketFile="/example/intake.sock";
            compare(actualController.configured,true);compare(actualController.busy,false);
        }
        function test_literal_source_text() {
            const title=findChild(panel,"intakeTitle");verify(title!==null);
            compare(title.text,controller.items[0].title);compare(title.textFormat,Text.PlainText);
        }
    }
}
