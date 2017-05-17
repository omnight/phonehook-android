import QtQuick 2.6
import QtQuick.Controls 2.0
import QtQuick.Controls.Styles 1.4
import QtQuick.Controls.Material 2.0


import "control"

PageBase {
    title: qsTr("Details")
    pageName: "search-detail"

    property variant resultData

    Component.onCompleted: {
      console.log(JSON.stringify(resultData));
    }

    Item {
        width: pageWidth
        height: 10*ps
    }

    Item {
        width: pageWidth
        height: Math.max(addIcon.height, nameLbl.height)

        Image {
            id: addIcon
            height: 30*ps
            width: 30*ps
            source: "../images/add-user-3-128.png"
            anchors.right: parent.right
            anchors.top: parent.top
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    var number = "";
                    if(typeof resultData.number != 'undefined')
                        number = resultData.number;
                    else if(typeof resultData.number_array != 'undefined') {
                        for(var i=0; i < resultData.number_array.length; i++)
                            number += resultData.number_array[i].number + "|";
                    }

                    _native.launchAddContact(resultData.name, resultData.address, number, resultData.url)
                }
            }
        }

        Label {
            id: nameLbl
            font.pixelSize: 16 * ps
            wrapMode: Text.Wrap
            anchors.rightMargin: 10*ps
            anchors.left: parent.left
            anchors.right: addIcon.left
            anchors.verticalCenter: parent.verticalCenter
            text: resultData.name
        }

    }




    Item {
        width: pageWidth
        height: 10*ps
        visible: resultData.address.length > 0
    }

    Header {
        visible: resultData.address.length > 0
        text: qsTr("Address")
    }

    Label {
        font.pixelSize: 10 * ps
        wrapMode: Text.Wrap
        width: pageWidth
        text: resultData.address
        visible: resultData.address.length > 0
    }

    Image {
        visible: resultData.address.length > 0
        width: pageWidth
        height: width/2
        source: "http://maps.googleapis.com/maps/api/staticmap?center=" + encodeURIComponent(resultData.address) + "&zoom=13&scale=false&size=600x300&maptype=roadmap&format=png&visual_refresh=true"
        + "&markers=size:mid%7Ccolor:0xff0000%7Clabel:1%7C" + encodeURIComponent(resultData.address)
        MouseArea {
            anchors.fill: parent
            onClicked: {
                _native.launchMaps(resultData.address)
            }
        }
    }

    Item {
        width: pageWidth
        height: 10*ps
    }

    Header {
        text: qsTr("Phone")
        visible: resultData.number || resultData.number_array
    }

    ListView {
        height: contentHeight
        width: pageWidth
        model: resultData.number_array || (resultData.number ? [resultData] : [] )
        delegate: ListItem {
            width: pageWidth
            text: model.modelData.number
            onClicked: {
                _native.launchNumber(model.modelData.number)
            }
        }
    }

    Header {
        text: qsTr("URL")
        visible: resultData.url
    }


    Label {
        width: pageWidth
        visible: resultData.url
        text: resultData.url
        font.pixelSize: 10*ps
        font.underline: true
        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
        MouseArea {
            anchors.fill: parent

            onClicked: {
                Qt.openUrlExternally(resultData.url)
            }
        }
    }


}

