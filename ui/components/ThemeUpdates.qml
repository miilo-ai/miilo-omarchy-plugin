import QtQuick
import Quickshell.Io

QtObject {
    id: root
    property string directory: ""
    property string revision: ""
    signal committed()
    property Timer settle: Timer { interval: 80; onTriggered: root.committed() }
    property FileView marker: FileView {
        path: root.directory ? root.directory + ".generation" : ""
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            const next = text().trim();
            if (next && next !== root.revision) {
                root.revision = next;
                root.settle.restart();
            }
        }
    }
}
