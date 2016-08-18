import QtQuick 2.6
import QtQuick.Controls 2.0
import QtQuick.Dialogs 1.2
import QtQuick.Layouts 1.1
import QtQuick.Window 2.1
import QtQuick.Controls.Styles 1.4
import QtQuick.Controls.Material 2.0

import "control"

PageBase {
    property int botId: 0
    property variant botModel: null
    title: botModel.name + " (Rev. " + botModel.revision + ")"
    id: pageRoot

    Header {
        text: qsTr("Source Settings")
    }

    Label {
        font.pixelSize: 12 * ps
        text: qsTr("None")
        visible: params.model.count == 0 // && !_bots.hasBlockTag(botId)
    }

    ListView {
        id: params
        height: model.count > 0 ? contentHeight : 0
        width: pageWidth
        spacing: Math.ceil(10*ps)

        delegate: Loader {
                id: cpLoader
                width: params.width

                Component.onCompleted: {
                    if(model.type === "string") source = "setting/SettingString.qml";
                    if(model.type === "password") source = "setting/SettingPassword.qml";
                    if(model.type === "bool") source = "setting/SettingBool.qml";
                }

                Connections {
                    ignoreUnknownSignals: true
                    target: cpLoader.item

                    onValueChanged: {
                        _bots.setBotParam(model.bot_id,model.key, value);
                    }
                }
            }

    }


    Item {
        width: parent.width
        height: 20*ps
    }

    Header {
        visible: logins.model.count > 0
        text: qsTr("Login")
    }

    ListView {
        id: logins
        height: model.count > 0 ? contentHeight : 1
        spacing: Math.ceil(2*ps)
        width: pageWidth
        delegate: ListItem {
             width: pageWidth
             text: model.name
             onClicked: {

                 var login_data = JSON.stringify(model, function replacer(key, value) {
                     if (["model", "objectName","hasModelChildren","index"].indexOf(key) != -1) {
                       return undefined;
                     }
                     return value;
               });

                 console.log(login_data);               
                 _native.startLogin(botId, login_data)
                 pageRoot.enabled = false

             }
        }
    }

    Connections {
        target: _native
        onLoginResult: {
            pageRoot.enabled = true
            if(success) {
                showInfo(qsTr('Login success!'))
            } else {
                showInfo(qsTr('Login failed, code ' + code))
            }
        }
        onLoginCancel: {
            pageRoot.enabled = true
            console.log('Login Cancelled');
        }
    }

    Item {
        visible: logins.model.count > 0
        width: parent.width
        height: 20*ps
    }

    Header {
        text: qsTr("Description")
    }

    Label {
        width: pageWidth
        font.pixelSize: 10 * ps
        text: botModel.description
        wrapMode: Text.Wrap
    }

    Item {
        width: parent.width
        height: 20*ps
        visible: botModel.link != ""
    }

    Header {
        text: qsTr("Link")
        visible: botModel.link != ""
    }

    Label {
        width: pageWidth
        font.pixelSize: 12 * ps
        text: botModel.link
        visible: botModel.link != ""
        font.underline: true
        MouseArea {
            anchors.fill: parent
            onClicked: {
                Qt.openUrlExternally(botModel.link);
            }
        }

    }

    contextMenu:  Menu {
        x: parent.width - width

        MenuItem {
            text: qsTr("Delete")
            onTriggered: {
                _bots.removeBot(botId)
                _blocks.initBlocks();
                pageStack.pop()
            }
        }

        MenuItem {
            text: qsTr("Clear Cache")
            onTriggered: {
                _bots.clearCache(botId);
                showInfo(qsTr("Cache cleared!"));
            }
        }

        MenuItem {
            enabled: _native.daemonRunning
            text: qsTr("Test Number")
            onTriggered: {
                pageStack.push(Qt.resolvedUrl("PageTestNumber.qml"), { botId: botId, name: botModel.name } )
            }
        }

        MenuItem {
            text: qsTr("Report a Problem")
            onTriggered: {
                Qt.openUrlExternally("https://github.com/omnight/phonehook/issues")
            }
        }
/*
        MenuItem {
            text: qsTr("Error?")
            onTriggered: {
                showRetry("Testing stuff...")
            }
        }
        */
    }

    Timer {
        id: msgBoxTest
        interval: 1000
        onTriggered: {
            isLoading = false
            showWarning("Fail again...")
        }
    }

    onRetryAction: {
        isLoading = true
        msgBoxTest.restart()
    }

    Component.onCompleted: {
        console.log('CREATING DETAILS PAGE')
        botModel = _bots.getBotDetails(botId);
        _bots.setActiveBot(botId);       

        params.model = _bots.paramList;
        logins.model = _bots.loginList;
    }

}
