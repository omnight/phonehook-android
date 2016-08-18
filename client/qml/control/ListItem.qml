import QtQuick 2.6
import QtQuick.Controls 2.0

ControlBase {
    id: root

    anchors.left: parent.left
    anchors.right: parent.right
    anchors.leftMargin: -margin
    anchors.rightMargin: -margin

    property string text
    property url icon
    property string text_bottom
    property string text_left
    property string text_top

    property variant menu

    //property variant menu

    signal clicked()

    height: innerColumn.height * 1.5
    color: _theme.button

    Image {
        id: imgIcon
        height: parent.height
        width: 20*ps
        visible: icon != ''
        source: icon
        anchors.leftMargin: margin
        anchors.left: parent.left
        fillMode: Image.PreserveAspectFit
    }

    Column {
        id: innerColumn
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: icon != '' ? imgIcon.right : parent.left
        anchors.leftMargin: margin
        anchors.right: parent.right
        anchors.rightMargin: margin

        Label {
            id: l1
            visible: !!root.text_top
            height: visible ? undefined: 0
            text: root.text_top
            font.pixelSize: 10 * ps
        }

        Label {
            id: l2
            text: root.text
            font.pixelSize: 14 * ps
        }

        Label {
            id: l3
            visible: !!root.text_bottom
            height: visible ? undefined: 0
            text: root.text_bottom
            font.pixelSize: 10 * ps
        }

    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        onClicked: {
            if(menu) menu.open();
            else root.clicked()
        }
    }

    states: State {
        name: "active"
        when: mouseArea.pressed
        PropertyChanges {
            target: root
            color: _theme.highlight
        }
        /*PropertyChanges {
            target: innerLabel
            color: _theme.highlightedText
        }*/
    }
    }
