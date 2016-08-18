import QtQuick 2.6
import QtQuick.Controls 2.0
import QtQuick.Dialogs 1.2
import QtQuick.Layouts 1.1
import QtQuick.Window 2.1
import QtQuick.Controls.Styles 1.4
import QtQuick.Controls.Material 2.0

import "control"

PageBase {

    title:  _native.call_log_type == "missed" ? qsTr("Missed") :
            _native.call_log_type == "incoming" ? qsTr("Incoming") :
            _native.call_log_type == "outgoing" ? qsTr("Outgoing") :
            qsTr("Calls");

    pageName: "call-log"

    contextIcon: "../images/phone-48.png"
    contextMenu:  Menu {
        x: parent.width - width

        MenuItem {
            text: qsTr("Incoming Calls")
            onTriggered: {
                onClicked: _native.call_log_type = "incoming"
            }
        }

        MenuItem {
            text: qsTr("Missed Calls")
            onTriggered: {
                onClicked: _native.call_log_type = "missed"
            }
        }

        MenuItem {
            text: qsTr("Outgoing Calls")
            onTriggered: {
                onClicked: _native.call_log_type = "outgoing"
            }
        }
    }

    ListView {
        model: _native.call_log
        width: pageWidth
        height: contentHeight

        delegate: ListItem {
            width: pageWidth
            text: modelData.name || modelData.number
            text_top: new Date(modelData.date).toLocaleString(null, Locale.ShortFormat)
            text_bottom: modelData.name ? modelData.number : ""
            menu: Menu {
                id: menu
                x: parent.width - width

                MenuItem {
                    text: qsTr("Lookup")
                    onTriggered: {
                        _native.testNumber(0, modelData.number);
                    }
                }

                MenuItem {
                    text: qsTr("Block")
                    onTriggered: {
                        pageStack.push(Qt.resolvedUrl("PageBlockAddManual.qml"), {name: modelData.name, number: modelData.number } )
                    }
                }
            }
        }
    }

    Timer {
        id: delayLoadMore
        interval: 100
        onTriggered: {
            _native.moreCallLogs()
        }
    }

    function maybeLoadMore() {
        if(contentScroller.atYEnd && _native.has_more_call_logs) {
            delayLoadMore.restart()
        }
    }


    Connections {
        target: contentScroller
        onAtYEndChanged: {
            maybeLoadMore();
        }
    }

    Connections {
        target: _native
        onHasMoreCallLogsChanged: {
            maybeLoadMore();
        }
    }

    Component.onCompleted: {
        _native.call_log_type = "incoming"
    }

}

