import QtQuick 2.6
import QtQuick.Controls 2.0
import QtQuick.Window 2.0
import "control"

Rectangle {
    id: root
    property string title: "Unnamed"
    property string pageName: ""
    readonly property real ps: Screen.pixelDensity * .25

    property alias fixChildren: root.data
    default property alias _contentChildren: _col.data

    property variant contextMenu: null
    property string contextIcon: null
    property alias contentColumn: _col
    property alias contentScroller: _contentScroller
    property int margin: 10*ps
    property bool isLoading: false

    property bool canBack: true

    readonly property int pageWidth: width - (margin*2)
    readonly property alias theme: _theme

    signal showWarning(var caption)
    signal showInfo(var caption)
    signal retryAction()
    anchors.fill: parent

    PhTheme { id: _theme; colorGroup: SystemPalette.Active }

    Flickable {
        anchors.fill: parent
        anchors.leftMargin: margin
        anchors.rightMargin: margin

        flickableDirection: Flickable.VerticalFlick
        contentHeight: _col.height + 20*ps
        id: _contentScroller

        Column {
            width: parent.width
            id: _col
        }
    }

}

