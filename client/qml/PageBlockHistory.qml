import QtQuick 2.6
import QtQuick.Controls 2.0
import QtQuick.Dialogs 1.2
import QtQuick.Layouts 1.1
import QtQuick.Window 2.1
import QtQuick.Controls.Styles 1.4
import QtQuick.Controls.Material 2.0

import "control"
PageBase {
    title: qsTr("History")

    property int blockId

    contextMenu: Menu {
        x: parent.width - width
        MenuItem {
            text: qsTr("Delete Block")
            onTriggered: {
                _blocks.deleteBlock(blockId);
                pageStack.pop();
            }
        }

    }

    fixChildren: Label {
        visible: _blocks.history.count == 0
        font.pixelSize: 12*ps
        text: qsTr("No Events")
        anchors.centerIn: parent
    }

    ListView {
        width: pageWidth
        height: contentHeight
        model: _blocks.history

        delegate: ListItem {
            text_top: new Date(model.date).toLocaleString(null, Locale.ShortFormat)
            text: model.number
        }
    }

}

