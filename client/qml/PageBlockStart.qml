import QtQuick 2.6
import QtQuick.Controls 2.0
import QtQuick.Dialogs 1.2
import QtQuick.Layouts 1.1
import QtQuick.Window 2.1
import QtQuick.Controls.Styles 1.4
import QtQuick.Controls.Material 2.0

import "control"


PageBase {

    title: qsTr("Call Blocks")
    pageName: "block-start"


    contextIcon: "../images/plus-2-48.png"
    contextMenu: Menu {
        x: parent.width - width
        MenuItem {
            text: qsTr("Add Manual Block")
            onTriggered: {
                pageStack.push(Qt.resolvedUrl("PageBlockAddManual.qml") )
            }
        }

        MenuItem {
            text: qsTr("Block Contact")
            onTriggered: {
                pageStack.push(Qt.resolvedUrl("PageBlockContact.qml") )
            }
        }

        MenuItem {
            text: qsTr("Add Block Source")
            onTriggered: {
                _blocks.initSources();
                pageStack.push(Qt.resolvedUrl("PageBlockAddSource.qml") )
            }
        }

    }

    fixChildren: Label {
        text: qsTr("No blocks activated")
        font.pixelSize: 12*ps
        visible: _blocks.db_blocks.count == 0
        anchors.centerIn: parent
    }

    ListView {
        height: contentHeight
        width: pageWidth
        spacing: Math.ceil(2*ps)
        model: _blocks.db_blocks

        delegate: ListItem {
            icon: model.contact_id ? "../images/contacts-48.png" :
                    model.bot_name ? "../images/website-optimization-48.png" :
                                     "../images/edit-6-48.png"

            text: model.name || model.bot_name || (model.contact_id ? _native.contactName(model.contact_id) : "??");
            text_top: model.date ? new Date(model.date).toLocaleString(null, Locale.ShortFormat) : null
            onClicked: {
                _blocks.initHistory(model.id);
                pageStack.push(Qt.resolvedUrl("PageBlockHistory.qml"), { blockId: model.id } );
            }
        }
    }

    Component.onCompleted: {
        _blocks.setAllViewed();
    }

}

