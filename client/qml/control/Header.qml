import QtQuick 2.6
import QtQuick.Controls 2.0


ControlBase {
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.leftMargin: -margin
    anchors.rightMargin: -margin



    height: il.height * 1.2

    Rectangle {
        anchors.fill: parent
        color: theme.bg_color_1
    }

    property string text

    Label {
        id: il
        text: parent.text
        font.pixelSize: 12 * ps
        anchors.verticalCenter: parent.verticalCenter
        font.bold: true
        width: pageWidth
        anchors.left: parent.left
        anchors.leftMargin: margin

    }
}
