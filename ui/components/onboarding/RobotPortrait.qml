import QtQuick
import "../../../assets/RobotProgram.js" as RobotProgram
import "../../../vendor/owl/Owl.js" as Owl
import "../../../vendor/owl/OwlLayout.js" as Layout

// Draw the original shared Bot program. No independent character geometry here.
Canvas {
    id: root
    property var widget: null
    property color ink: "white"
    property color accent: ink
    property string agentKey: "welcome"
    property string expression: "ready"
    property string motion: "reduced"
    property bool active: true
    property real clock: 0.6
    readonly property var fallbackPalette: Owl.themeFromToml('foreground="' + ink + '"\naccent="' + accent + '"\nbackground="' + (widget ? widget.ink("background") : "#16151d") + '"')
    readonly property var colors: widget && widget.palette ? widget.palette : fallbackPalette
    readonly property var program: Owl.compile(RobotProgram.source)
    readonly property var slots: program.globals.reduce((result, g, i) => { result[g.name] = i; return result }, {})
    readonly property var instance: new Owl.Instance(program, {
        theme: name => root.colors[name] === undefined ? null : root.colors[name],
        tile: name => null,
        report: message => console.warn("Miilo shared portrait: " + message),
        changed: () => {}, act: () => {},
        runInto: () => { throw new Error("A decorative portrait must not run commands") }
    }, {})
    implicitWidth: 56
    implicitHeight: 56
    Accessible.ignored: true
    FrameAnimation {
        running: root.active && root.visible && root.motion !== "off"
        onTriggered: root.clock = elapsedTime + 0.6
    }
    onClockChanged: requestPaint()
    onColorsChanged: requestPaint()
    onExpressionChanged: requestPaint()
    onMotionChanged: { clock = 0.6; requestPaint() }
    onAgentKeyChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    function setValue(name, value) { instance.values[slots[name]] = Owl.fromJson(value) }
    onPaint: {
        var s = Math.min(width, height);
        if (s <= 0) return;
        var c = getContext("2d"); c.reset();
        setValue("portraitAgent", {_key: agentKey, name: "Miilo", status: expression === "failed" ? "failed" : expression === "resting" ? "resting" : "ready", health: "healthy"});
        setValue("portraitSize", s);
        setValue("robotMotion", motion);
        if (widget && widget.instance && widget.program) {
            var i = widget.program.globals.findIndex(g => g.name === "robotColors");
            if (i >= 0) setValue("robotColors", Owl.toJson(widget.instance.read(i)));
        }
        instance.invalidate();
        instance.frame(clock);
        var canvas = instance.render(false).children.find(node => node.kind === "Canvas");
        if (!canvas) return;
        c.translate((width-s)/2, (height-s)/2);
        Layout.paint(c, canvas.draw(s,s), {foreground: ink}, "sans-serif", null);
    }
}
