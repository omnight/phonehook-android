import QtQuick 2.6
import QtQuick.Controls 2.0
import QtQuick.Dialogs 1.2
import QtQuick.Layouts 1.1
import QtQuick.Window 2.1
import QtQuick.Controls.Styles 1.4
import QtQuick.Controls.Material 2.0
import "control"

PageBase {
    title: qsTr("Settings")
    pageName: "settings"

    width: 400
    height: 800

    contentColumn.spacing: 10*ps

    Header {
        text: qsTr("Basic Settings")
    }

    RowLayout {
        width: parent.width
        Label {
            font.pixelSize: 10*ps
            text: qsTr("Show only for unknown numbers")
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }
        Switch {
            id: checkOnlyUnknown

            checked: _setting.get("activate_only_unknown", "true") == "true"
            onCheckedChanged: {
                _setting.put("activate_only_unknown", checked)
            }
        }
    }

    RowLayout {
        width: parent.width
        Label {
            font.pixelSize: 10*ps
            text: qsTr("Auto update sources")
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }
        Switch {
            id: checkAutoUpdate

            checked: _setting.get("auto_update_enabled", "true") == "true"
            onCheckedChanged: {
                _setting.put("auto_update_enabled", checked)
            }
        }
    }

    RowLayout {
        width: parent.width
        Label {
            font.pixelSize: 10*ps
            text: qsTr("Use while roaming")
            Layout.fillWidth: true
            wrapMode: Text.Wrap
        }
        Switch {
            id: checkRoaming

            checked: _setting.get("enable_roaming", "false") == "true"
            onCheckedChanged: {
                _setting.put("enable_roaming", checked)
            }
        }
    }

    Row {
        width: parent.width
        Text {
            id: label2
            anchors.verticalCenter: parent.verticalCenter
            text: qsTr("Popup Timeout")
            font.pixelSize: 10*ps
            wrapMode: Text.Wrap
            width: pageWidth/2
        }

        Column {
            width: pageWidth/2

            Slider {
                id: timerSlider
                width: parent.width
                to: 120
                value: _setting.get("popup_timeout", "0")
                onValueChanged: {
                    _setting.put("popup_timeout", Math.floor(value))
                }
            }

            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                font.pixelSize: 8*ps
                text: timerSlider.value == 0 ? "Disabled" : Math.floor(timerSlider.value)+"s"
            }
        }


    }

    Row {
        width: parent.width
        Label {
            anchors.verticalCenter: parent.verticalCenter
            font.pixelSize: 10*ps
            text: qsTr("Popup Position")
            width: pageWidth/2
            wrapMode: Text.Wrap
        }

        ComboBox {
            width: pageWidth/2
            //Layout.fillWidth: true
            currentIndex: _setting.get("popup_position", "1")
            model: ListModel {
                ListElement { text: "Top"; }
                ListElement { text: "Middle"; }
                ListElement { text: "Bottom"; }
            }

            onCurrentIndexChanged: {
                _setting.put("popup_position", currentIndex)
            }
        }
    }

    Item {
        width: parent.width
        height: 20*ps
    }

    Header {
        text: qsTr("Advanced")
    }

    RowLayout {
        width: parent.width
        Label {
            font.pixelSize: 10*ps
            text: qsTr("Test sources");
            Layout.fillWidth: true
            wrapMode: Text.Wrap
        }
        Switch {
            id: checkTestSource

            checked: _setting.get("download_root_url", "") !== ""

            onCheckedChanged: {
                if(checked) {
                    _setting.put("download_root_url", "https://raw.githubusercontent.com/omnight/phonehook-sources/beta/files/")
                    _setting.put("auto_update_index_url", "https://raw.githubusercontent.com/omnight/phonehook-sources/beta/files/i.js")
                    _setting.put("sources_index_url", "https://raw.githubusercontent.com/omnight/phonehook-sources/beta/files/index.js")
                } else {
                    // use default values
                    _setting.remove("download_root_url")
                    _setting.remove("auto_update_index_url")
                    _setting.remove("sources_index_url")
                }
            }
        }
    }


}

