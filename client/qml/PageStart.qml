import QtQuick 2.6
import QtQuick.Controls 2.1
import "control"
import QtQuick.Controls.Styles 1.4
import QtQuick.Controls.Material 2.1

PageBase {
    title: qsTr("Phonehook")

    width: 400
    height: 400

    pageName: "home"

    contextMenu: Menu {
        x: parent.width - width

        MenuItem {
            enabled: !_native.daemonRunning
            text: qsTr("Start Service")
            onTriggered: {
                _native.daemonRunning = true
            }
        }

        MenuItem {
            enabled: _native.daemonRunning
            text: qsTr("Stop Service")
            onTriggered: {
                _native.daemonRunning = false
            }
        }

/*
        MenuItem {
            text: qsTr("Notify")
            onTriggered: {
                _native.createNotification(1319, "TITLE", "HELLO", "SUPER\nLONG\nTITLE...", 'blocks');
            }
        }
*/

    }

    Connections {
        target: _native
        onDaemonRunningChanged: {
            console.log('DR', daemonRunning);
        }
    }
/*
    Button {
        text: "quick test"
        onClicked: {
            if(!_native.isServiceRunning())
                _native.daemonRunning = true
            _native.testNumber(0, "+46735267979");
        }
    }
*/

    Item {
        height: 10*ps
        width: pageWidth
    }

    Grid {
        columns: pageStack.width > pageStack.height ? 4 : 2
        rows: pageStack.width > pageStack.height ? 1 : 2

        id: g

        columnSpacing: 10*ps
        rowSpacing: 10*ps

        BigButton {
            text: qsTr("Data Sources")
            image: "../images/website-optimization-128.png"
            width: (pageWidth - g.columnSpacing * (g.columns -1)) / g.columns
            height: width
            onClicked: pageStack.push( Qt.resolvedUrl('PageServerBotList.qml') )
        }

        BigButton {
            text: qsTr("Search")
            image: "../images/search-2-128.png"
            width: (pageWidth - g.columnSpacing * (g.columns -1)) / g.columns
            height: width
            onClicked: pageStack.push( Qt.resolvedUrl('PageSearchStart.qml') )
        }

        BigButton {
            text: qsTr("Blocks")
            image: "../images/restriction-shield-128.png"
            width: (pageWidth - g.columnSpacing * (g.columns -1)) / g.columns
            height: width
            onClicked: pageStack.push( Qt.resolvedUrl('PageBlockStart.qml') )
        }

        BigButton {
            text: qsTr("Call Log")
            image: "../images/time-12-128.png"
            width: (pageWidth - g.columnSpacing * (g.columns -1)) / g.columns
            height: width
            onClicked: pageStack.push( Qt.resolvedUrl('PageCallLogStart.qml') )
        }

    }

    Item {
        height: 10*ps
        width: pageWidth
    }

    Header {
        text: qsTr("Installed Sources")
    }


    Label {
        font.pixelSize: 10*ps
        visible: _bots.botList.count == 0
        text: qsTr("None")
    }

    Item {
        height: Math.ceil(2*ps)
        width: parent.width
    }

    ListView {
        id: bli
        model: _bots.botList
        spacing: Math.ceil(2*ps)
        height: model.count > 0 ? contentHeight : 0
        width: parent.width

        delegate: ListItem {
            text: model.name
            onClicked: pageStack.push(Qt.resolvedUrl("PageBotDetails.qml"), { botId: model.id })
        }
    }

    Item {
        height: Math.ceil(2*ps)
        width: parent.width
    }


}

