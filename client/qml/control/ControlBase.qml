import QtQuick 2.6
import QtQuick.Window 2.0
import QtQuick.Controls 2.0

Rectangle {

    property alias theme: _theme

    PhTheme { id: _theme; colorGroup: SystemPalette.Active }
    readonly property real ps: Screen.pixelDensity * .25

}

