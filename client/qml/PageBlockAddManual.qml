import QtQuick 2.6
import QtQuick.Controls 2.0
import QtQuick.Dialogs 1.2
import QtQuick.Layouts 1.1
import QtQuick.Window 2.1
import QtQuick.Controls.Styles 1.4
import QtQuick.Controls.Material 2.0
import "control"

PageBase {
    title: qsTr("Manual Block")
    pageName: "block-add-manual"

    property string name
    property string number

    RowLayout {
        width: parent.width
        Label {
            font.pixelSize: 10*ps
            text: qsTr("Hidden number")
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }
        Switch {
            id: blockHidden
        }
    }

    Header {
        text: qsTr("Name")
    }

    Item {
        width: pageWidth
        height: 5*ps
    }

    TextField {
        id: blockName
        text: name
        width: pageWidth
        enabled: !blockHidden.checked
    }

    Item {
        width: pageWidth
        height: 20*ps
    }

    Header {
        text: qsTr("Number")
    }

    Item {
        width: pageWidth
        height: 5*ps
    }

    TextField {
        id: blockNumber
        text: number
        width: pageWidth
        enabled: !blockHidden.checked
    }

    Item {
        width: pageWidth
        height: 20*ps
    }

    Button {
        id: addManual
        text: qsTr("Add Block")
        width: pageWidth
        enabled: blockHidden.checked || (blockName.text != '' && blockNumber.text != '')

        onClicked: {
            _blocks.addManualBlock(blockName.text,blockNumber.text,blockHidden.checked);
            pageStack.pop();
        }
    }


}

