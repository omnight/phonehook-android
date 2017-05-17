import QtQuick 2.6
import QtQuick.Controls 2.0
import QtQuick.Dialogs 1.2
import QtQuick.Layouts 1.1
import QtQuick.Window 2.1
import QtQuick.Controls.Styles 1.4
import QtQuick.Controls.Material 2.0


Column {
    width: parent.width
    spacing: 5*ps
    signal valueChanged(string value)

    Label {
        font.pixelSize: 10*ps
        text: model.title
    }

    TextField {
        id: textField1        

        text: model.value
        width: parent.width

        onTextChanged: {
            valueChanged(text)
        }
    }
}



