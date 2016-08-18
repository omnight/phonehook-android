import QtQuick 2.6
import QtQuick.Controls 2.0
import QtQuick.Dialogs 1.2
import QtQuick.Layouts 1.1
import QtQuick.Window 2.1
import QtQuick.Controls.Styles 1.4
import QtQuick.Controls.Material 2.0
import "control"

PageBase {
    title: qsTr("Add Block Source")
    pageName: "block-add-source"


    fixChildren: Label {
        text: qsTr("No sources to add")
        anchors.centerIn: parent
        font.pixelSize: 12*ps
        visible: blockSourceView.model.count == 0
    }

    ListView {
        id: blockSourceView
        model: _blocks.sources
        width: pageWidth
        height: contentHeight
        spacing: Math.ceil(2*ps)

        delegate: ListItem {
            width: pageWidth
            text: model.name
            onClicked: {
                _bots.setBlockSource(model.id, true);
                _blocks.initBlocks();
                pageStack.pop();
            }
        }

    }

}

