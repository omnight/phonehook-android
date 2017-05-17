import QtQuick 2.6
import QtQuick.Controls 2.0
import QtQuick.Dialogs 1.2
import QtQuick.Layouts 1.1
import QtQuick.Window 2.1
import QtQuick.Controls.Styles 1.4
import QtQuick.Controls.Material 2.0

import "control"

ApplicationWindow {
    visible: true
    width: 640
    height: 480
    title: "phonehook"
    id: root

    property real ps: Screen.pixelDensity * .25

    PhTheme { id: _theme; colorGroup: SystemPalette.Active }

    header: ToolBar {
        Material.foreground: "white"
        //height: 30 * ps
        RowLayout {
            spacing: 20
            anchors.fill: parent

            ToolButton {
                id: pr
                contentItem: Item {
                    Column {
                        //anchors.fill: parent
                        spacing: Math.floor( 3*ps)
                        anchors.centerIn: parent

                        Repeater {
                            model: [0,0,0]
                            delegate: Rectangle {
                                height: Math.floor( 3*ps )
                                width: Math.floor(20*ps)
                                color: drawer.open ? "white" : "black"
                            }
                        }
                    }
                }

                onClicked: drawer.toggle()
            }


            Label {
                id: titleLabel
                text: !pageStack.currentItem ? "" :
                       pageStack.currentItem.title || "?"
                font.pixelSize: 13 * ps
                elide: Label.ElideRight
                horizontalAlignment: Qt.AlignHCenter
                verticalAlignment: Qt.AlignVCenter
                Layout.fillWidth: true
            }

            ToolButton {
                visible: !cmb.visible
                enabled: false
            }

            ToolButton {
                visible: !!(pageStack.currentItem && pageStack.currentItem.contextMenu)
                id: cmb

                contentItem: Item {
                    Image {
                        height: 20*ps
                        width: 20*ps
                        anchors.centerIn: parent
                        //source: "../images/gear-48.png"
                        fillMode: Image.PreserveAspectFit
                        source: pageStack.currentItem.contextIcon || "../images/gear-48.png"
                    }
                }

                onClicked: pageStack.currentItem.contextMenu.open()

                Item {
                    anchors.top: parent.bottom
                    anchors.left: parent.right
                    id: contextMenuHolder
                }
            }
        }
    }


    Item {
        property string highlightColor: 'black'
        property int paddingLarge: 50
    }

    NavigationDrawer {
        id: drawer
        position: Qt.LeftEdge

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        visualParent: pageStack

        color: _theme.window

        Flickable {
            anchors.fill: parent
            contentHeight: navColumns.height
            flickableDirection: Flickable.VerticalFlick

            Column {
                id: navColumns
                width: parent.width
/*Image {
    source: '../images/checked-checkbox-48.png'
}*/

               NavigationItem {
                   text: qsTr("Home")
                   current: pageStack.currentItem.pageName == 'home'
                   icon: '../images/home-5-48.png'
                   onTriggered: {
                       drawer.hide()
                       pageStack.pop(pageStack.get(0), StackView.Transition);
                   }
               }

               NavigationItem {
                   text: qsTr("Search")
                   current: pageStack.currentItem.pageName == 'search'
                   icon: '../images/search-2-48.png'
                   onTriggered: {
                       drawer.hide()

                       pageStack.pop(pageStack.get(0), StackView.Immediate);
                       pageStack.push(Qt.resolvedUrl('PageSearchStart.qml'))
                   }
               }

               NavigationItem {
                   text: qsTr("Blocks")
                   current: pageStack.currentItem.pageName == 'block-start'
                   icon: '../images/restriction-shield-48.png'
                   onTriggered: {
                       drawer.hide()
                       pageStack.pop(pageStack.get(0), StackView.Immediate);
                       pageStack.push( Qt.resolvedUrl('PageBlockStart.qml') )
                   }
               }

               NavigationItem {
                   text: qsTr("Call History")
                   current: pageStack.currentItem.pageName == 'call-log'
                   icon: '../images/time-12-48.png'
                   onTriggered: {
                       drawer.hide()
                       pageStack.pop(pageStack.get(0), StackView.Immediate);
                       pageStack.push( Qt.resolvedUrl('PageCallLogStart.qml') )
                   }
               }

               NavigationItem {
                   text: qsTr("Add Source")
                   current: pageStack.currentItem.pageName == 'botlist'
                   icon: '../images/add-48.png'
                   onTriggered: {
                       drawer.hide()
                       pageStack.pop(pageStack.get(0), StackView.Immediate);
                       pageStack.push( Qt.resolvedUrl('PageServerBotList.qml') )
                   }
               }

               NavigationItem {
                   text: qsTr("Settings")
                   current: pageStack.currentItem.pageName == 'settings'
                   icon: '../images/checked-checkbox-48.png'
                   onTriggered: {
                       drawer.hide()
                       pageStack.pop(pageStack.get(0), StackView.Immediate);
                       pageStack.push( Qt.resolvedUrl('PageAppSettings.qml') )
                   }
               }
            }
        }
    }

    onClosing: {
        if(drawer.open) {
            drawer.hide();
            close.accepted = false;
        } else if(pageStack.depth > 1) {
            pageStack.pop();
            close.accepted = false;
        } else {
            Qt.quit();
        }
    }

    Component {
        id: pageStart
        PageStart {

        }
    }

    StackView {
        id: pageStack
        //PageBlockStart { }/*
        initialItem: pageStart //PageCallLogStart {} //pageStart
        anchors.fill: parent



        Component {
            id: itemCmp
            MenuItem {
                text: ""
                height: 20*ps
                width: 100*ps
            }
        }

        onCurrentItemChanged: {
            //currentItem.contextMenu.parent = contextMenuHolder
        }
    }

    Rectangle {
        anchors.fill: parent
        id: loadingOverlay
        color: _theme.dark
        opacity: 0.5
        visible: !pageStack.currentItem || pageStack.currentItem.isLoading

        MouseArea {
            anchors.fill: parent
        }

        BusyIndicator {
            id: loader
            anchors.centerIn: parent
            width: Math.min( parent.width/4, parent.height/4)
            height: width
            running: true
        }
    }

    MessageDialog {
        id: warningDialog
        title: qsTr("Warning")
        icon: StandardIcon.Warning

        standardButtons: StandardButton.Abort | StandardButton.Retry

        onAccepted: {
            pageStack.currentItem.retryAction()
        }

        onRejected: {

        }
    }

    Connections {
        target: pageStack.currentItem
        onShowWarning: {
            warningDialog.text = caption;
            warningDialog.open();
        }
        onShowInfo: {
            infoDialog.text = caption;
            infoDialog.open();
        }
    }

    function intentTarget() {
        switch(_native.intent_target) {
            case 'blocks':
                infoDialog.close();
                warningDialog.close();
                drawer.hide();

                pageStack.pop(pageStack.get(0), StackView.Immediate);
                pageStack.push( Qt.resolvedUrl('PageBlockStart.qml') )
                return true;
        }

        return false;
    }

    Connections {
        target: _native
        onIntent_targetChanged: {
            root.intentTarget();
        }

        Component.onCompleted: {
            if(!root.intentTarget()) {

                if(_bots.botList.count == 0) {
                    addSourcesStartup.open()
                }
            }
        }
    }

    MessageDialog {
        id: addSourcesStartup

        title: qsTr("Welcome!")

        icon: StandardIcon.Information
        standardButtons: StandardButton.Ok | StandardButton.Cancel
        text: qsTr("Thanks for using Phonehook. Add some data sources now to get started!")

        onAccepted: {
            pageStack.push( Qt.resolvedUrl('PageServerBotList.qml') )
            addSourcesStartup.close()
        }

        onRejected: {
            addSourcesStartup.close()
        }

    }


    MessageDialog {
        id: infoDialog
        title: qsTr("Info")
        icon: StandardIcon.Information

        standardButtons: StandardButton.Ok

        onAccepted: {
            infoDialog.close();
        }

    }

}

