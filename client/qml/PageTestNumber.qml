import QtQuick 2.6
import QtQuick.Controls 2.0

import "control"

PageBase {

    property string name
    property int botId


    title: qsTr("Test Number")


    Label {
        width: pageWidth
        text: name
        font.pixelSize: 16*ps
    }

    Item {
        height: 20*ps
        width: pageWidth
    }

    TextField {
        id: numberInput
        width: pageWidth
        inputMethodHints: Qt.ImhDialableCharactersOnly
    }

    Component.onCompleted: {
        numberInput.forceActiveFocus()
    }

    Item {
        height: 20*ps
        width: pageWidth
    }

    Button {
        text: qsTr("OK")
        enabled: numberInput.text.length > 1
        anchors.horizontalCenter: parent.horizontalCenter

        onClicked: {
            _native.testNumber(botId, numberInput.text)
        }
    }

}


