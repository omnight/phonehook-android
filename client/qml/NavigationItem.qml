import QtQuick 2.6
import QtQuick.Controls 2.0
import QtQuick.Window 2.1
import "control"

Rectangle {

    id: root
    property real ps: Screen.pixelDensity * .25
    property alias text: lbl.text
    property string target
    property bool current: false
    property url icon

    signal triggered()

    height: 35*ps
    width: parent.width

    PhTheme { id: _theme; colorGroup: SystemPalette.Active }

    color: current ? _theme.bg_color_1 : _theme.alternateBase

    Image {
        id: icon_block
        width: parent.height*.5
        height: width
        source: icon
        anchors.left: parent.left
        anchors.leftMargin: 10*ps
        anchors.verticalCenter: parent.verticalCenter
    }

    Label {
        id: lbl
        anchors.left: icon_block.right
        anchors.leftMargin: 10*ps
        font.pixelSize: 10 * ps
        anchors.verticalCenter: parent.verticalCenter
    }

    Rectangle {
        height: Math.ceil(1*ps)
        color: _theme.light
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        onClicked: {
            triggered()
        }
    }

    states: State {
        name: "active"
        when: ma.pressed
        PropertyChanges {
            target: root
            color: _theme.highlight
        }
        PropertyChanges {
            target: lbl
            color: _theme.highlightedText
        }
    }

}

