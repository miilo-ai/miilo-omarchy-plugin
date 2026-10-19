import QtQuick
import QtTest
import "../../vendor/owl" as Owl
Item {
    id: root
    width: 360; height: 240
    property string scratchPath: ""
    Owl.OwlWidget {
        id: subject
        width: 360; height: 240; active: true
        host: Owl.OwlHost { stateDir: root.scratchPath + "/state" }
        errorDir: root.scratchPath + "/errors"
        Component.onCompleted: {
            stateRead=true;
            sourceText='widget "clock-check" { size: 2x2 component Orbit() { let clock = time Canvas { width: 180; height: 120 circle(10 + clock * 15, 20, 4, fill: "#ffffff") } } Orbit {} }';
            load();
        }
    }
    Owl.OwlNode {
        anchors.fill: parent
        widget: subject
        node: subject.tree ? subject.tree.children[0] : null
    }
    function phaseX() {
        var canvas=subject.tree.children[0];
        return canvas.draw(180,120)[0].args[0];
    }
    TestCase {
        name: "CanvasClock"
        when: true
        onCompletedChanged: if(completed) console.log(qtest_results.failCount===0 ? "MIILO_CANVAS_CLOCK_OK" : "MIILO_CANVAS_CLOCK_FAILED")
        function test_component_clock_advances_without_source_refresh() {
            tryVerify(()=>subject.instance!==null && subject.tree!==null);
            console.log("CLOCK_READY",subject.error,subject.problems,subject.tree.readsTime);
            verify(subject.program.animated);
            verify(!subject.tree.readsTime,"Fixture must read its clock only during deferred draw");
            wait(200);
            var previous=root.phaseX();
            for(var i=0;i<5;i++) {
                wait(100);
                var next=root.phaseX();
                console.log("CLOCK_SAMPLE",previous,next,subject.frame);
                verify(next>previous+0.2,"Canvas clock froze between source refreshes: "+previous+" -> "+next);
                verify(next-previous<6,"Unexpected jump between consecutive frames");
                previous=next;
            }
            compare(subject.problems.length,0);
        }
    }
}
