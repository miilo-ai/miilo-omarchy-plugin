import QtQuick
import QtQuick.Layouts
import "onboarding/controls" as Controls

ColumnLayout {
    id: root
    required property var theme
    required property var surface
    readonly property var widget: surface.widget
    property bool searchOpen:false
    readonly property bool atOverview:!read("focused")&&!read("actor")&&!read("setupOpen")
    readonly property bool needsOnly:read("needsOnly")===true
    readonly property bool detail:read("observatoryView")==="orbit"
    readonly property string query:read("query")||""
    readonly property int needsCount: {
        const works=read("works")||[],attention=read("attention")||[];
        return works.filter(w=>w.attention!=="none"||attention.some(a=>a._workKey===w._key)).length;
    }
    readonly property bool searchable:(read("provs")||[]).length>0
    spacing:theme.gap
    function read(name){const revision=widget.generation;return surface.viewValue(name);}
    function write(name,value){surface.setViewState(name,value);}
    function filter(value){write("needsOnly",value);write("workflowActor","");write("pageSize",5);}
    function mode(value){
        write("observatoryView",value);write("expandedSystem","");write("workflowActor","");
        if(value==="quiet")write("query","");else{write("inspectionView","");write("orbitPage",0);}
    }
    RowLayout {
        Layout.fillWidth:true;spacing:root.theme.gap/2
        Controls.Action {objectName:"overview-all";context:root;text:"All work";selected:!root.needsOnly;onClicked:root.filter(false)}
        Controls.Action {objectName:"overview-needs";context:root;text:"Needs you ("+root.needsCount+")";selected:root.needsOnly;onClicked:root.filter(true)}
        Item {Layout.fillWidth:true}
        Controls.Action {objectName:"overview-compact";context:root;text:"Compact";selected:!root.detail;onClicked:root.mode("quiet")}
        Controls.Action {objectName:"overview-detail";context:root;text:"Detail";selected:root.detail;onClicked:root.mode("orbit")}
        ToolbarButton {
            objectName:"overview-search";theme:root.theme;kind:"search";label:"Search work";visible:root.searchable
            selected:root.searchOpen||root.query.length>0
            onClicked:{root.searchOpen=!selected;if(root.searchOpen)Qt.callLater(()=>search.forceActiveFocus());else root.write("query","");}
        }
    }
    Controls.Field {
        id:search;objectName:"overview-search-input";context:root
        visible:root.searchable&&(root.searchOpen||root.query.length>0)
        Layout.fillWidth:true
        text:root.query;placeholderText:"Search systems, agents or work"
        Accessible.name:placeholderText
        onTextEdited:root.write("query",text)
        Keys.onEscapePressed:{root.write("query","");root.searchOpen=false;}
    }
}
