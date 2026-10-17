import QtQuick
import Quickshell

Item {
    id: root
    property bool active: true
    property string mode: ""
    property var agents: []
    property var sessions: []
    property var selected: []
    property var groups: []
    property var grouped: []
    property var rows: []
    property var collapsed: ({})
    property bool groupsLoaded: false
    property bool groupsDirty: false
    property int editIndex: -1
    property string fingerprint: ""
    property string project: Quickshell.env("HOME") || "/"
    property string error: ""
    property var reply: ({})
    readonly property bool busy: mode === "loading" || mode === "importing"
    signal connected(int count)
    function rebuildRows() {
        var result = [];
        grouped.forEach((g, index) => {
            result.push({header:true, group:index, name:g.name, label:g.rule ? g.name : g.name.replace(" / ", " · "), count:g.sessions.length});
            if (!collapsed[g.name]) g.sessions.forEach(s => result.push({header:false, group:index, session:s}));
        });
        rows = result;
    }
    function regroup() { commands.regroup(); }
    function collapseGroup(index, value) {
        var next = Object.assign({}, collapsed);
        var name = grouped[index].name;
        next[name] = value === undefined ? !next[name] : value;
        collapsed = next;
        rebuildRows();
    }
    function toggleGroup(index) {
        var items = grouped[index].sessions.filter(s => s.observable);
        var all = items.length && items.every(s => selected.indexOf(s.kind + ":" + s.id) >= 0);
        var next = selected.slice();
        items.forEach(s => { var key = s.kind + ":" + s.id; var at = next.indexOf(key);
            if (all && at >= 0) next.splice(at,1); else if (!all && at < 0) next.push(key);
        });
        selected = next;
    }
    function activateRow(index) {
        var row = rows[index];
        if (!row) return;
        if (row.header) toggleGroup(row.group);
        else if (row.session.observable) toggle(row.session);
    }
    function editGroup(index) {
        editIndex = index;
        var rule = index >= 0 ? groups[index] : {name:"",folder:project,pattern:"",kind:"all",future:false};
        draft = Object.assign({}, rule);
        error = ""; mode = "group";
    }
    function saveGroup(rule) {
        var next = groups.slice();
        if (editIndex >= 0) next[editIndex] = rule; else next.push(rule);
        pendingGroups = next;
        regroup();
    }
    property var draft: ({})
    property var pendingGroups: null

    function review() {
        error = "";
        mode = "loading";
        commands.discover();
    }
    function toggle(session) {
        var key = session.kind + ":" + session.id;
        selected = selected.indexOf(key) >= 0 ? selected.filter(k => k !== key) : selected.concat([key]);
    }
    function dismiss() {
        mode = "";
        groupsLoaded = false;
        groupsDirty = false;
        if (fingerprint) commands.dismiss();
    }
    function importSelected() {
        if ((!selected.length && !groupsDirty) || commands.importing)
            return;
        error = "";
        reply = ({});
        mode = "importing";
        commands.enroll();
    }
    onActiveChanged: if (active && !busy) commands.detect()
    OnboardingCommands { id: commands; controller: root }
}
