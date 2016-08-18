import QtQuick 2.6
import QtQuick.Controls 2.0


ControlBase {
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.leftMargin: -margin
    anchors.rightMargin: -margin
    id: root

    property string name
    property string address
    property bool expanded: false
    property bool isBusiness: false

    signal clicked()

    color: "transparent"

    //width: 400
    //height: 100
    //property int pageWidth: 400

    height: contCol.height

    Column {

        id: contCol
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: margin
        anchors.rightMargin: margin

        Item {
            width: pageWidth
            height: 30*ps

            Image {
                id: profImg
                width: 30*ps
                height: 30*ps
                source: isBusiness ?   "../../images/shop-48.png" : "../../images/contacts-48.png"
                anchors.left: parent.left
                anchors.top: parent.top
            }

            Column {
                anchors.left: profImg.right
                anchors.leftMargin: margin
                anchors.top: parent.top
                anchors.right: parent.right

                Label {
                    text: name
                    font.pixelSize: 12*ps
                    anchors.left: parent.left
                    anchors.right: parent.right
                    elide: Text.ElideRight
                }

                Label {
                    text: address
                    font.pixelSize: 10*ps
                    anchors.left: parent.left
                    anchors.right: parent.right
                    elide: Text.ElideRight
                }
            }
        }



        Item {  // spacer
            width: pageWidth
            height: 5*ps
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            root.clicked()
        }
    }
}

