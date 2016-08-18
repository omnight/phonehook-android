import QtQuick 2.6
import QtQuick.Controls 2.0
import QtQuick.Dialogs 1.2
import QtQuick.Layouts 1.1
import QtQuick.Window 2.1
import QtQuick.Controls.Styles 1.4
import QtQuick.Controls.Material 2.0
import "control"

PageBase {

    title: qsTr("Block Contact")
    pageName: "block-contact"


    ListView {
        width: pageWidth
        height: contentHeight
        model: _native.contacts
        spacing: Math.ceil(2*ps)

        delegate: ListItem {
            text: modelData.name
            onClicked: {
                console.log("BLOXING", modelData.id)
                _blocks.addBlockedContact(modelData.id);
                pageStack.pop();
            }
        }
    }

}

