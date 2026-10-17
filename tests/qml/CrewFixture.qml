import QtQuick
import "../../vendor/owl/Owl.js" as Owl
import QtQuick.Controls
import "../../ui/components/onboarding/controls" as Controls
import QtQuick.Layouts
import "../../ui/components/onboarding" as Crew
import "../../ui/components" as UI
Window {
 id: root; width: 680; height: 480; visible: true
 property bool light: false
 color: light ? "#faf5ee" : "#16151d"
 QtObject { id: fakeWidget; property int frame:0; property var instance: ({read:i => i === 0 ? Owl.fromJson([{key:"welcome",color:2}]) : "off"}); property var program: ({globals:[{name:"robotColors"},{name:"robotMotion"}]})
  property var palette: Owl.themeFromToml('background="' + root.color + '"\nforeground="' + (root.light?"#28232e":"#eeeaf4") + '"\naccent="#ac9cf5"\npurple="#ac9cf5"\nblue="#75abc9"\ngreen="#86b88c"\norange="#c8966a"\ncyan="#6dbab8"\nred="#d38896"')
  function ink(n) { return ({foreground:root.light?"#28232e":"#eeeaf4",muted:root.light?"#65586b":"#b4aabb",accent:root.light?"#5e469e":"#ac9cf5",red:"#e07785",background:root.color.toString(),selection:"#6e6099"})[n] || "#a69cbb" }
 }
 QtObject { id: fakeController; property var agents: [
  {name:"Codex",observationSupported:true,locations:["/example/.codex","/example/Work"]},
  {name:"Cursor",observationSupported:true,locations:["/example/.cursor"]},
  {name:"Devin",observationSupported:false,locations:[]} ] }
 QtObject { id:controlContext; property var widget:fakeWidget; property var theme:nativeTheme }
 UI.InteractionTheme { id: nativeTheme; widget: fakeWidget }
 ColumnLayout { anchors.fill: parent; anchors.margins:18; spacing:10
  Crew.CrewHeader { widget: fakeWidget }
  Crew.AgentInvitation { controller:fakeController; widget:fakeWidget; theme:nativeTheme }
  Text { Layout.fillWidth:true; text:"Only selected sessions are observed. Credentials stay in place."; color:fakeWidget.ink("muted"); font.pixelSize:12; wrapMode:Text.WordWrap }
  RowLayout {
   Controls.Action { context:controlContext; text:"Review sessions" }
   Controls.Action { context:controlContext; text:"Not now" }
  }
 }
}