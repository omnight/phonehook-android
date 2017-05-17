import QtQuick 2.6
import QtQuick.Controls 2.0
import QtQuick.Dialogs 1.2
import QtQuick.Layouts 1.1
import QtQuick.Window 2.1
import QtQuick.Controls.Styles 1.4
import QtQuick.Controls.Material 2.0

RowLayout {
    width: parent.width
    signal valueChanged(string value)

    Label {
        font.pixelSize: 10*ps
        text: model.title
        Layout.fillWidth: true
        wrapMode: Text.Wrap
    }
    Switch {
        checked: model.value == "1"
        onCheckedChanged: {
            valueChanged(checked ? "1" : "0")
        }
    }
}
