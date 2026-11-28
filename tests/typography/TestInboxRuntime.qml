import QtQuick
import QtTest
import Quickshell
import "../../ui/components/intake" as Intake
Item {
    Intake.InboxController { id: controller; program: Quickshell.env("MIILO_INTAKE_TEST_CLI") }
    TestCase {
        name: "MiiloInboxRuntime"
        when: true
        onCompletedChanged: if (completed) console.log(qtest_results.failCount === 0 ? "MIILO_INBOX_RUNTIME_OK" : "MIILO_INBOX_RUNTIME_FAILED")
        function test_real_socket_read_decision_and_refresh() {
            controller.transport = "socket";
            controller.socketFile = Quickshell.env("MIILO_INTAKE_TEST_SOCKET");
            controller.active = true;
            tryVerify(() => !controller.stale && controller.items.length === 1, 15000);
            const item = controller.items[0];
            compare(item.title, "Synthetic incoming task");
            compare(item.extensions["io.miilo.intake"].decision, "pending");
            verify(controller.receiveText("accept synthetic-task", "voice"));
            tryVerify(() => !controller.stale && controller.items[0].extensions["io.miilo.intake"].decision === "accepted", 15000);
            compare(controller.items[0].extensions["io.miilo.intake"].execution, "queued");
            compare(controller.items[0].providerState, "queued_awaiting_executor");
            compare(controller.retryArguments.length, 0);
            compare(controller.error, "");
            controller.active = false;
        }
    }
}
