import QtQuick
import QtTest
import Quickshell
import "../../ui/components" as Miilo

Item {
    width: 400; height: 500
    Miilo.MiiloSurface {
        id: surface
        anchors.fill: parent
        active: false
        widgetPath: Quickshell.env("MIILO_CONFIG_TEST_WIDGET")
    }
    TestCase {
        name: "MiiloConfiguration"
        when: true
        onCompletedChanged: if (completed) console.log(qtest_results.failCount === 0 ? "MIILO_CONFIG_OK" : "MIILO_CONFIG_FAILED")
        function test_store_selection_and_persistence() {
            tryCompare(surface, "configurationReady", true)
            var mode = Quickshell.env("MIILO_CONFIG_TEST_MODE")
            if (mode === "invalid") {
                verify(surface.configurationError.length > 0)
                compare(surface.widget.path, "")
                return
            }
            compare(surface.sharedConfiguration, mode === "shared")
            tryVerify(() => !!surface.widget.instance)
            compare(surface.widget.error, "")
            var globals = surface.widget.program.globals
            var slot = globals.findIndex(g => g.name === "observatoryView")
            compare(surface.widget.instance.read(slot), mode === "shared" ? "orbit" : "quiet")
            verify(surface.widget.stateDir.endsWith(mode === "shared" ? "/preferences" : "/miilo/widgets"))
        }
    }
}
