import QtQuick
import QtTest
import Quickshell.Io
import "../../vendor/owl" as Owl
Item {
 id: root; width: 760; height: 600
 property string source: ""
 FileView { path: Qt.resolvedUrl("../../assets/70-miilo-fleet.owl").toString().replace("file://", ""); onLoaded: root.source = text() }
 Item { id: start; activeFocusOnTab: true; width: 1; height: 1 }
 Owl.OwlWidget { id: subject; width: 760; height: 600; active: false; screenWidth: 760; screenHeight: 600; host: Owl.OwlHost {stateDir:"/tmp/miilo-keyboard-fixture-state"} }
 Owl.OwlNode { id: tree; anchors.fill: parent; widget: subject; node: subject.screenTree ? subject.screenTree.children[0] : null }
 function card(item) {
  if(item.node && item.kind === "Column" && item.handlers.onTap && (item.node.c || []).some(n => n.kind === "Row" && (n.c || []).some(c => c.p && c.p.text === "Keyboard factory"))) return item;
  for(var i=0;i<item.children.length;i++){var found=card(item.children[i]);if(found)return found;}
  return null;
 }
 function gridNode(item) {
  if(item.node && item.kind === "Grid") return item;
  for(var i=0;i<item.children.length;i++){var found=gridNode(item.children[i]);if(found)return found;}
  return null;
 }
 function value(name) {return subject.instance.read(subject.program.globals.findIndex(g=>g.name===name));}
 TestCase {
  name: "RobotKeyboard"; when: root.source !== ""
  onCompletedChanged: if(completed)console.log(qtest_results.failCount===0?"MIILO_ROBOT_KEYBOARD_OK":"MIILO_ROBOT_KEYBOARD_FAILED")
  function test_tab_reaches_robot_and_enter_opens_system() {
   var fixture={configured:true,errors:[],snapshot:{providers:[{id:"p1",name:"Keyboard factory",health:"healthy"}],actors:[{_key:"a1",id:"a1",providerId:"p1",name:"Builder",status:"resting",health:"healthy"}],workItems:[],attention:[]}};
   subject.stateRead=true;subject.persisted={observatoryView:"orbit"};
   subject.sourceText=root.source.replace(/source feed = cmd\([^\n]+/,"state feed = "+JSON.stringify({ok:true,out:JSON.stringify(fixture),code:0,err:""}));
   subject.load();subject.openScreen();wait(300);
   var robot=root.card(tree);verify(robot,"Actual generated Orbit card exists");
   verify(robot.activeFocusOnTab);start.forceActiveFocus();
   for(var i=0;i<40 && !robot.activeFocus;i++){keyClick(Qt.Key_Tab);wait(10);}
   verify(robot.activeFocus,"Tab must reach the actual robot card");
   verify(findChild(robot,"owlKeyboardFocus").visible,"The focused card must have a visible outline");
   keyClick(Qt.Key_Return);tryVerify(()=>root.value("expandedSystem")==="p1");
   subject.instance.setState(subject.program.globals.findIndex(g=>g.name==="expandedSystem"), "");wait(80);
   robot=root.card(tree);verify(robot);robot.forceActiveFocus();keyClick(Qt.Key_Space);
   tryVerify(()=>root.value("expandedSystem")==="p1");
   subject.instance.setState(subject.program.globals.findIndex(g=>g.name==="expandedSystem"), "");
   for(var mode of ["quiet","orbit"]) for(var width of [360,760]) {
    root.width=width;subject.width=width;subject.screenWidth=width;
    subject.instance.setState(subject.program.globals.findIndex(g=>g.name==="observatoryView"),mode);wait(100);
    var grid=root.gridNode(tree);verify(grid,"Grid remains rendered in "+mode);
    var container=grid.parent;
    while(container && !(container.node && container.kind==="Box" && container.p.align==="top")) container=container.parent;
    verify(container,"Grid has a centered content container");
    var left=grid.mapToItem(container,0,0).x;
    verify(Math.abs(left-(container.width-grid.width)/2)<1,"Native "+mode+" margins are equal");
   }
   compare(subject.problems.length,0);
  }
 }
}
