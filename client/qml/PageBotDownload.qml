import QtQuick 2.6
import QtQuick.Controls 2.0
import QtQuick.Dialogs 1.2
import QtQuick.Layouts 1.1
import QtQuick.Window 2.1
import QtQuick.Controls.Styles 1.4
import QtQuick.Controls.Material 2.0

import "control"

PageBase {

    property variant botData
    property string statusText

    property string acceptText: qsTr("Activate")
    property string acceptColor

    property int botId: -1

    title: botData.name

    width: 400
    height: 400

    Item {
        width: pageWidth
        height: ps*20
    }

    Image {
        id: botImage
        width: pageWidth
        height: 80*ps
        anchors.horizontalCenter: parent.horizontalCenter
        source: botData.icon
        //smooth: true

        fillMode: Image.PreserveAspectFit
    }


    Item {
        width: pageWidth
        height: ps*20
    }

    Timer {
        id: downloadDelay
        running: false
        repeat: false
        interval: 100

        onTriggered: {
            _bots.downloadBot(botData.file, false)
        }
    }

    onRetryAction: {
        isLoading = true
        downloadDelay.restart()
    }

    Connections {
        target: _bots
        onBotDownloadSuccess: {
            isLoading = false
            showInfo( qsTr("%1 is active").arg(botData.name) );
            pageStack.replace(Qt.resolvedUrl("PageBotDetails.qml"),
                            { botId: botId })
        }

        onBotDownloadFailure: {
            isLoading = false
            showWarning(qsTr("Failed to activate"))
        }
    }


    Header {
        text: qsTr("Status")
    }

    Flow {
        id: l
        width: pageWidth
        property int cols: pageStack.width > pageStack.height ? 2 : 1

        spacing: Math.ceil(2*ps)

        Label {
            width: (l.width - l.spacing * (l.cols - 1)) / l.cols
            id: statusLabel
            text: statusText
            color: acceptColor
        }

        Button {
            width: (l.width - l.spacing * (l.cols - 1)) / l.cols
            id: beginDownload
            text: acceptText

            onClicked: {
                isLoading = true
                downloadDelay.start()
            }
        }

        Button {
            width: l.width
            text: qsTr("Deactivate")
            visible: botId != -1

            onClicked: {
                _bots.removeBot(botId)
                pageStack.pop()
            }
        }
    }

    Item {
        width: pageWidth
        height: ps*20
    }

    Header {
        text: qsTr("Link")
    }

    Label {
        width: pageWidth
        font.pixelSize: 12 * ps
        text: botData.link
        visible: botData.link != ""
        font.underline: true
        MouseArea {
            anchors.fill: parent
            onClicked: {
                Qt.openUrlExternally(botData.link);
            }
        }

    }

    Item {
        width: pageWidth
        height: ps*20
    }

    Header {
        text: qsTr("Capabilities")
    }

    ListView {
        height: contentHeight
        width: pageWidth
        model: botData.tags

        function m() {
            qsTr("login")
            qsTr("login_google")
            qsTr("login_ms")
            qsTr("login_facebook")
            qsTr("lookup")
            qsTr("person_search")
            qsTr("business_search")
        }

        delegate: ListItem {
            text: "✓ " + qsTr(model.cap)
        }
    }

    Item {
        width: pageWidth
        height: ps*20
    }

    Header {
        text: qsTr("Description")
    }

    Label {
        width: pageWidth
        font.pixelSize: 12 * ps
        text: botData.description
        wrapMode: Text.Wrap
    }


    Component.onCompleted: {
        var status = _bots.botStatusCompare(botData.name, botData.revision)
        console.log('minv', botData.minversion, _bots.version());
        if(botData.minversion && botData.minversion > _bots.version()) status = 3;

        botId = _bots.getBotId(botData.name);

        if(status == 0) { statusText = qsTr("Not installed yet"); }
        if(status == 1) { statusText = qsTr("Installed and up-to-date"); acceptText = qsTr("Reset"); acceptColor = "#006600" }
        if(status == 2) { statusText = qsTr("Update available"); acceptText = qsTr("Update"); acceptColor = "#000099" }
        if(status == 3) { statusText = qsTr("A newer version of phonehook is required"); acceptColor = "#990000"; beginDownload.enabled=false; }
    }
}

