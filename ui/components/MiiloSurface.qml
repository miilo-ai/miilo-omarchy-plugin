import QtQuick
import Quickshell
import Quickshell.Io
import "../../vendor/owl" as Owl
import "../../vendor/owl/Owl.js" as OwlJs

Item {
    id: root
    property real hostTextScale: 1
    property string hostFontFamily: Qt.application.font.family
    property bool active: visible
    property bool expanded: false
    property var configureLocal: null
    property var interactionTheme: null
    readonly property string miiloHome: Quickshell.env("MIILO_HOME") || Quickshell.env("HOME") + "/.miilo"
    property bool configurationReady: false
    property bool sharedConfiguration: false
    property string configurationError: ""
    property string widgetPath: Quickshell.env("MIILO_WIDGET_PATH") || decodeURIComponent(String(Qt.resolvedUrl("../../assets/70-miilo-fleet.owl")).replace(/^file:\/\//, ""))
    readonly property alias widget: widget
    readonly property bool quietFleet: {
        var generation = widget.generation;
        if (!widget.instance || !widget.program) return true;
        function value(name) {
            var slot = widget.program.globals.findIndex(g => g.name === name);
            return slot < 0 ? "" : widget.instance.read(slot);
        }
        return String(value("observatoryView")) !== "orbit" && !value("selectedWork") && !value("selectedActor") && !value("expandedSystem") && !value("setupOpen") && !value("query");
    }
    // Theme muted colors often target borders; lift text to readable contrast.
    function readablePalette(toml) {
        var p = OwlJs.themeFromToml(toml)
        function luminance(c) {
            var q = Qt.color(OwlJs.hex8(c))
            function linear(v) { return v <= 0.04045 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4) }
            return 0.2126 * linear(q.r) + 0.7152 * linear(q.g) + 0.0722 * linear(q.b)
        }
        var bg = luminance(p.background), original = Qt.color(OwlJs.hex8(p.muted)), fg = Qt.color(OwlJs.hex8(p.foreground))
        for (var step = 0; step <= 20; step++) {
            var t = step / 20
            var c = Qt.rgba(original.r * (1-t) + fg.r*t, original.g * (1-t) + fg.g*t, original.b * (1-t) + fg.b*t, 1)
            var l = luminance(c)
            if ((Math.max(l,bg)+0.05)/(Math.min(l,bg)+0.05) >= 4.5 || step === 20) {
                p.muted = OwlJs.argb(c.toString())
                break
            }
        }
        return p
    }
    property var owlPalette: readablePalette("")
    onActiveChanged: if (active && widget.instance && widget.program) {
        var slot = widget.program.globals.findIndex(g => g.name === "systemsOpen");
        if (slot >= 0) widget.instance.setState(slot, false);
    }
    function closeDetails() { widget.closeScreen() }
    FileView {
        path: root.miiloHome + "/config.json"
        printErrors: false
        onLoaded: {
            try {
                if (!root.miiloHome.startsWith("/")) throw new Error("MIILO_HOME must be absolute")
                var config = JSON.parse(text())
                if (config.schemaVersion !== 1) throw new Error("Unsupported Miilo configuration")
                root.sharedConfiguration = true
            } catch (error) {
                root.configurationError = "Invalid Miilo configuration. Run miilo config check."
            }
            root.configurationReady = true
        }
        onLoadFailed: function(error) {
            if (!root.miiloHome.startsWith("/") || error !== FileViewError.FileNotFound)
                root.configurationError = "Cannot read Miilo configuration. Run miilo config check."
            root.configurationReady = true
        }
    }
    FileView {
        path: Quickshell.env("MIILO_THEME_FILE") || (Quickshell.env("HOME") + "/.local/state/omarchy/current/theme/colors.toml")
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.owlPalette = root.readablePalette(text())
    }
    Owl.OwlHost {
        id: host
        typographyProfile: Quickshell.env("MIILO_TEXT_PROFILE") === "phone" ? "phone" : "desktop"
        textScale: {
            var requested = Number(Quickshell.env("MIILO_TEXT_SCALE") || "1");
            return root.hostTextScale * (isFinite(requested) && requested > 0 ? requested : 1);
        }
        sansFamily: root.hostFontFamily
        monoFamily: "monospace"
        stateDir: root.sharedConfiguration ? root.miiloHome + "/preferences"
            : (Quickshell.env("XDG_STATE_HOME") || home + "/.local/state") + "/miilo/widgets"
    }
    Rectangle { anchors.fill: parent; color: widget.ink("background") }
    Owl.OwlWidget {
        id: widget
        anchors.fill: parent
        anchors.margins: 12
        path: root.configurationReady && !root.configurationError ? root.widgetPath : ""
        errorDir: (Quickshell.env("XDG_STATE_HOME") || host.home + "/.local/state") + "/miilo/widgets/errors"
        host: host
        typography.family: root.hostFontFamily
        palette: root.owlPalette
        active: root.active
        configureLocal: root.configureLocal
        interactionTheme: root.interactionTheme
        cols: 3
        rows: 2
        dp: 1
        screenWidth: Math.max(1, width)
        screenHeight: Math.max(1, height)
        onScreenRequested: root.expanded = true
        onScreenClosed: root.expanded = false
        onProgramChanged: if (program && root.expanded) Qt.callLater(openScreen)
    }
    TapHandler {
        enabled: !root.expanded && !!(widget.tree && widget.tree.onTap)
        onTapped: (event) => widget.tree.onTap(event.position.x, event.position.y)
    }
    Owl.OwlNode {
        anchors.fill: widget
        widget: widget
        visible: !widget.error
        node: {
            var tree = root.expanded ? widget.screenTree : widget.tree
            if (!tree) return null
            return tree.children.length === 1 ? tree.children[0]
                : { kind: "Column", p: { gap: 0 }, h: {}, a: {}, c: tree.children }
        }
    }
    TypeText {
        typography: widget.typography
        anchors.fill: widget
        visible: !!root.configurationError || !!widget.error
        text: root.configurationError || widget.error
        color: widget.ink("red")
        wrapMode: Text.Wrap
    }
}
