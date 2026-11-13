import QtQuick
import QtTest
import Quickshell
import Quickshell.Io
import qs.Commons as Commons
import "../../ui/shell" as Host
import "../../ui/components" as Miilo

Item {
    id: root
    width: 500; height: 300
    QtObject { id: palette; function ink(role) {return role === "background" ? "#18202c" : "#e0e8f0";} }
    property int commits: 0
    Miilo.ThemeUpdates {
        id: updates
        directory: Quickshell.env("MIILO_THEME_FIXTURE")
        onCommitted: root.commits++
    }
    FileView {id:writer;path:Quickshell.env("MIILO_THEME_FIXTURE")+".generation";atomicWrites:true;printErrors:false}
    Host.Theme { id: theme; widget: palette }
    Miilo.ToolbarButton {id: button;theme:theme;kind:"settings";label:"Voice settings"}
    TestCase {
        name:"MiiloLiveTheme"
        when:true
        onCompletedChanged: if(completed) console.log(qtest_results.failCount===0?"MIILO_HOST_THEME_OK":"MIILO_HOST_THEME_FAILED",qtest_results.passCount,qtest_results.failCount)
        function test_completed_theme_flips_are_observed_after_atomic_replacement() {
            tryVerify(()=>commits>0);
            var before=commits;
            writer.setText("theme-one");tryVerify(()=>commits>before);compare(updates.revision,"theme-one");
            before=commits;
            writer.setText("theme-two");tryVerify(()=>commits>before);compare(updates.revision,"theme-two");
        }
        function test_surface_opacity_changes_without_palette_changes() {
            var initial=Commons.Color.shellValues;
            Commons.Color.shellValues=Object.assign({},initial,{"popups.background":"#102030","popups.background-alpha":"0.42","menu.background":"#203040","menu.background-alpha":"0.63","tooltip.background":"#304050","tooltip.background-alpha":"0.75","tooltip.text":"#fedcba"});
            verify(Math.abs(theme.surface.a-0.42)<0.01);
            verify(Math.abs(theme.menuSurface.a-0.63)<0.01);
            var tip=findChild(button,"toolbar-tooltip");
            verify(tip);compare(tip.background.color,Commons.Color.tooltip.background);compare(tip.contentItem.color,Commons.Color.tooltip.text);
            Commons.Color.shellValues=Object.assign({},Commons.Color.shellValues,{"popups.background-alpha":"0.9","tooltip.background-alpha":"0.3"});
            verify(Math.abs(theme.surface.a-0.9)<0.01);
            verify(Math.abs(tip.background.color.a-0.3)<0.01);
            Commons.Color.shellValues=initial;
        }
    }
}
