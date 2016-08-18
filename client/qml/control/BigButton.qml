import QtQuick 2.6
import QtQuick.Controls 2.0


ControlBase {
    id: root
    property string text
    property url image
    signal clicked

    Rectangle {
        id: bg
        anchors.fill: parent
        opacity: .4
        color: _theme.bg_color_1
        radius: 10*ps
    }

    Column {

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 10*ps
        anchors.rightMargin: 10*ps
        anchors.verticalCenter: parent.verticalCenter

        spacing: 5*ps

        Image {
            id: btnImage
            source: image
            anchors.horizontalCenter: parent.horizontalCenter
            width: root.height*.5
            height: root.width*.5
            fillMode: Image.PreserveAspectFit
        }

        Label {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            text: root.text
            font.pixelSize: 12*ps
            font.bold: true
        }
    }



    states: State {
        name: "pressed"
        when: ma.pressed
        PropertyChanges {
            target: bg
            opacity: .8
        }
    }

    MouseArea {
        anchors.fill: parent
        id: ma
        onClicked: root.clicked()
    }
}
