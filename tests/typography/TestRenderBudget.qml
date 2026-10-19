import QtQuick
import QtTest
import Quickshell.Io
import "../../vendor/owl/Owl.js" as Owl
import "../../vendor/owl" as Runtime
Item {
    id: root
    width: 580; height: 620
    property string scratchPath: ""
    property var intervals: []
    property bool recording: false
    property real previous: 0
    property string source: ""
    property bool forceLayout: false
    property var errors: []
    FileView {
        path: Qt.resolvedUrl("../../assets/70-miilo-fleet.owl").toString().replace("file://", "")
        onLoaded: root.source = text()
    }
    Runtime.OwlWidget {
        id: painted
        width: 580; height: 620; active: false
        host: Runtime.OwlHost { stateDir: root.scratchPath + "/state" }
        errorDir: root.scratchPath + "/errors"
    }
    Runtime.OwlNode {
        anchors.fill: parent; widget: painted
        node: painted.screenTree ? painted.screenTree.children[0] : null
    }
    FrameAnimation {
        running: painted.active
        onTriggered: {
            if (root.recording && root.previous > 0) root.intervals.push((elapsedTime-root.previous)*1000)
            root.previous=elapsedTime
        }
    }
    function fixture() {
        var actors=Array.from({length:4},(_,i)=>({_key:"a"+i,id:"a"+i,providerId:"p"+i,name:"Sample "+i,status:"working",health:"healthy"}));
        return {configured:true,errors:[],snapshot:{providers:actors.map(a=>({id:a.providerId,name:a.name,health:"healthy"})),actors:actors,workItems:actors.map(a=>({_key:a.id+"w",id:a.id+"w",title:"Inspect sample",providerId:a.providerId,_actorKeys:[a._key],lifecycle:"active",phase:"implementing",attention:"none"})),attention:[]}};
    }
    TestCase {
        name: "RenderBudget"
        onCompletedChanged: if(completed) console.log(qtest_results.failCount===0 ? "MIILO_RENDER_BUDGET_OK" : "MIILO_RENDER_BUDGET_FAILED")
        when: root.source !== ""
        function test_frame_pacing() {
            painted.stateRead=true;painted.persisted={observatoryView:"orbit"};
            painted.sourceText=root.source.replace(/source feed = cmd\([^\n]+/,"state feed = "+JSON.stringify({ok:true,out:JSON.stringify(root.fixture()),code:0,err:""}));
            painted.load();painted.openScreen();painted.active=true;
            wait(500);root.intervals=[];root.recording=true;
            wait(3000);root.recording=false;painted.active=false;
            var times=root.intervals.slice().sort((a,b)=>a-b);
            verify(times.length>10);compare(painted.problems.length,0);
            console.log("MIILO_OFFSCREEN_FRAME_PACING",JSON.stringify({frames:times.length,p50Ms:times[Math.floor(times.length*.5)],p95Ms:times[Math.floor(times.length*.95)],over33Ms:times.filter(t=>t>33.4).length}));
        }
        function test_retained_native_evaluation() {
            var palette=Owl.themeFromToml("");
            var program=Owl.compile(root.source);
            var host={theme:k=>palette[k] || null,tile:k=>({linux:true,tileWidth:580,tileHeight:620,screenWidth:580,screenHeight:620})[k] || null,report:e=>root.errors.push(e),changed:()=>{},act:()=>{throw Error("Unexpected action")},runInto:()=>{throw Error("Unexpected process")}};
            var instance=new Owl.Instance(program,host,{observatoryView:"orbit"});
            var feed=root.fixture();
            instance.setSource(program.globals.findIndex(g=>g.name==="feed"),Owl.fromJson({ok:true,out:JSON.stringify(feed),code:0,err:""}));
            var tree=instance.render(true),canvases=[];
            function collect(n){if(n.kind==="Canvas")canvases.push(n);(n.c || n.children || []).forEach(collect)}
            collect(tree);
            if (!root.forceLayout) verify(!tree.readsTime);
            verify(canvases.length>=8);
            var costs=canvases.map(()=>0);
            var start=Date.now();
            for(var i=0;i<60;i++){
                instance.frame(i/60);
                if(root.forceLayout){tree=instance.render(true);canvases=[];collect(tree)}
                canvases.forEach((c,j)=>{var t=Date.now();c.draw(c.p.width || 260,c.p.height || 164);costs[j]+=Date.now()-t});
            }
            console.log("MIILO_CANVAS_COSTS",JSON.stringify(canvases.map((c,j)=>({fill:c.p.fill,width:c.p.width,height:c.p.height,ms:costs[j]/60}))));
            console.log("MIILO_NATIVE_EVALUATOR_MS",(Date.now()-start)/60,"CANVASES",canvases.length);
            compare(root.errors.length,0);
        }
    }
}
