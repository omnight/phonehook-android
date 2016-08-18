import QtQuick 2.6
import QtQuick.XmlListModel 2.0
import QtQuick.Window 2.1
import QtQuick.Controls 2.0
import QtQuick.Controls.Material 2.0

PageBase {
    title: qsTr("Available Sources")
    pageName: "botlist"
    isLoading: true

    property bool isReady: false
    property bool isError: false


    Text {
        anchors.centerIn: parent
        text: qsTr("Failed to load")
        visible: isError
    }

    Component.onCompleted: {
        serverBots.clear()

        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {

            console.log('readystate', xhr.readyState)

            if(xhr.readyState == 1 || xhr.readyState == 2 || xhr.readyState == 3) {
                isLoading = true;
            }

            if(xhr.readyState == 4) {
                isLoading = false;
                var serverData =JSON.parse(xhr.responseText);

                var myCountry = _native.getCountry();
                var prioSort = [];
                for(var n = 0; n < serverData.length; n++) {
                    if(serverData[n].country == myCountry.toUpperCase()) {
                        console.log(n);
                        prioSort = prioSort.concat(serverData.splice(n, 1));
                        n--;
                    }
                }

                var sb = prioSort.concat(serverData);
                isReady = true;

                var sc = {};

                for(var n in sb) {
                    var t2 = [];
                    for(var nn in sb[n].tags) {
                        t2.push({ "cap": sb[n].tags[nn] })
                    }
                    sb[n].tags = t2;
                    sc[sb[n].sort_key] = (sc[sb[n].sort_key] || 0) + 1
                    serverBots.append(sb[n])
                }

                // auto-expand first selection
                expandMap = [sb[0].sort_key];

                console.log(JSON.stringify(sc))
                sectionCount = sc;
            }
        };

        xhr.open('GET', _setting.get("sources_index_url", 'https://raw.githubusercontent.com/omnight/phonehook-sources/master/files/index.js'), true);
        xhr.send();
    }

    ListModel {
        id: serverBots
        ListElement {
            name: ""
            country: ""
            revision: 0
            description: ""
            icon: ""
            link: ""
            tags: []
            file: ""
            minversion: 0
            sort_key: ""
        }
    }

    property variant expandMap: [ ]
    property variant sectionCount: { 0 : 0 }

    function isExpanded(section) {
        return expandMap.indexOf(section) != -1;
    }

    function expand(section) {
        if(expandMap.indexOf(section) == -1) {
            var e = expandMap;
            e.push(section);
            expandMap = e;
        }
    }

    function contract(section) {
        var i = expandMap.indexOf(section);
        if(i != -1) {
            var e = expandMap;
            e.splice(i,1);
            expandMap = e;
        }
    }

    function toggle(section) {
        if(isExpanded(section)) contract(section)
        else                    expand(section)
    }

    ListView {
        id: botListView
        model: serverBots
        width: pageWidth
        height: model.count > 0 ? contentHeight: 0

        //clip: true
        section.property: "sort_key"

        footer: Item {
            anchors.left: parent.left
            anchors.right: parent.right

            height: 150
            Item {
                height: 20
                width: parent.width
            }

            Text {
                //anchors.margins: Theme.paddingLarge
                anchors.left: parent.left
                anchors.right: parent.right
                font.pixelSize: 10 * ps
                //color: Theme.secondaryColor
                visible: isReady
                wrapMode: Text.Wrap
                text: qsTr("All names and logos listed here are properties of respective rights holders. Phonehook is not endorsed by any of these services. ")
            }
        }

        section.delegate: Item {

            property string sectionCountry: /\|(.*)/.exec(section)[1]
            property bool expanded

            anchors.left: parent.left
            anchors.right: parent.right

            height: 30*ps

            Row {
                id: countryNameLine
                anchors.top: parent.top
                anchors.left: parent.left
                //anchors.leftMargin: Theme.paddingLarge
                anchors.verticalCenter: parent.verticalCenter
                Image {
                    id: flag
                    anchors.verticalCenter: parent.verticalCenter
                    source: "https://omnight.github.io/phonehook-sources/flags/" + sectionCountry.toLowerCase() + ".png"

                    width: 20*ps
                    height: 20*ps

                    Rectangle {
                        anchors.left: parent.right
                        anchors.top: parent.bottom
                        anchors.leftMargin: -width
                        anchors.topMargin: -height
                        radius: 5
                        color: "#222255"
                        height: cLabel.height
                        width: cLabel.width+10
                        opacity: .8

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            id: cLabel
                            //font.pixelSize: Theme.fontSizeExtraSmall
                            font.pixelSize: 8*ps
                            font.weight: Font.Bold
                            text: sectionCount[section]
                            color: "white"
                            //color: Theme.primaryColor
                        }
                    }

                }

                Item {
                    height: parent.height
                    width: 10*ps
                }

                Text {
                    //color: Theme.primaryColor
                    //font.pixelSize: Theme.fontSizeMedium
                    font.pixelSize: 14 * ps
                    text: _bots.getCountryName(sectionCountry)
                    anchors.verticalCenter: parent.verticalCenter
                }

            }

            Image {
                source: "../images/expand.png"
                height: 10*ps
                width: 10*ps
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                ///anchors.rightMargin: Theme.paddingLarge
                rotation: isExpanded(section) ? 180 : 0
                Behavior on rotation { NumberAnimation { duration: 200 } }
            }

            Rectangle {
                anchors.top: countryNameLine.bottom
                anchors.left: parent.left
                //anchors.topMargin: -2 * ps
                height: Math.ceil(1 * ps)
                color: theme.mid
                width: parent.width
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    toggle(section)
                }
            }

        }

        delegate:
            Item {
                id: delegate
                anchors.left: parent.left
                anchors.right: parent.right

                height: isExpanded(model.sort_key) ? 30*ps : 0
                visible: isExpanded(model.sort_key) ? true : false

                Item {
                    height: 20*ps
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: 10*ps
                    //anchors.rightMargin: Theme.paddingLarge
                    //anchors.leftMargin: Theme.paddingLarge
                    anchors.verticalCenter: parent.verticalCenter

                    Image {
                        id: icon
                        height: 20*ps
                        width: 20*ps
                        fillMode: Image.PreserveAspectFit

                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left

                        //visible: typeof model.icon !== 'undefined'
                        source: model.icon || ''
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: icon.right
                        anchors.leftMargin: 5*ps
                        text: model.name
                        font.pixelSize: 14 * ps
                        //color: delegate.highlighted ? Theme.highlightColor : Theme.primaryColor
                    }

                    Component.onCompleted: {
                        var bstatus = _bots.botStatusCompare(model.name, model.revision)
                        checkedUpdated.visible = (bstatus == 2)
                        checkedInstalled.visible = (bstatus >= 1)
                    }

                    Connections {
                        target: _bots
                        onBotList_changed: {
                            var bstatus = _bots.botStatusCompare(model.name, model.revision)
                            checkedUpdated.visible = (bstatus == 2)
                            checkedInstalled.visible = (bstatus >= 1)
                        }
                    }

                    Image {
                        id: checkedUpdated
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: checkedInstalled.left
                        source: "../images/new-48.png"
                        height: parent.height*0.8
                        width: height
                        visible: false
                    }

                    Image {
                        id: checkedInstalled
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        source: "../images/approval-48.png"
                        height: parent.height*0.8
                        width: height
                        visible: false
                    }

                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        pageStack.push(Qt.resolvedUrl("PageBotDownload.qml"), { botData: model } )
                    }
                }
            }
    }

}

