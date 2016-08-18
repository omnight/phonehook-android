import QtQuick 2.6
import QtQuick.Controls 2.0
import QtQuick.Controls.Styles 1.4
import QtQuick.Controls.Material 2.0

import "control"

PageBase {

    title: qsTr("Search")
    pageName: "search"

    property string selectedTag: ''
    property int selectedBotId: 0

    contentColumn.spacing: 10*ps


    Column {
        width: pageWidth
        visible: botView.model && botView.model.count != 0
        spacing: 10*ps


        Header {
            text: qsTr("What?")
        }

        TextField {
            id: inputName
            width: parent.width
        }

        Header {
            text: qsTr("Where?")
        }

        TextField {
            id: inputLocation
            width: parent.width
        }

        Header {
            text: qsTr("Type")
        }

        Row {
            width: pageWidth

            CheckBox {
                text: qsTr('People')
                width: parent.width/2
                id: searchPeopleCheck
                checked: selectedTag == 'person_search'
                onCheckedChanged: {

                    selectedTag = checked ? 'person_search'
                                          : 'business_search';

                    _bots.setBotSearchListTag(selectedTag);
                    _setting.get("search_last_used_tag", selectedTag);
                    checked = Qt.binding(function() { return selectedTag == 'person_search' });
                }
            }

            CheckBox {
                text: qsTr('Businesses')
                id: searchBusinessCheck
                width: parent.width/2
                checked: selectedTag == 'business_search'
                onCheckedChanged: {
                    selectedTag = checked ? 'business_search'
                                          : 'person_search';

                    _bots.setBotSearchListTag(selectedTag);
                    _bots.setSetting("search_last_used_tag", selectedTag);

                    checked = Qt.binding(function() { return selectedTag == 'business_search' });
                }
            }
        }

        Header {
            text: qsTr("Search In")
        }


        Label {
            text: qsTr("There are no installed sources with search capability")
            wrapMode: Text.Wrap
            width: pageWidth * 0.7
            horizontalAlignment: Text.AlignHCenter
            anchors.horizontalCenter: parent.horizontalCenter
            font.pixelSize: 12*ps
            visible: botView.model.count == 0
        }

        ListView {
            id: botView
            width: pageWidth
            height: contentHeight || 0
            //anchors.fill: parent
            interactive: false

            delegate:
                ListItem {
                    id: delegate
                    text: model.name || ''
                    color: selectedBotId == model.id ? theme.highlight : theme.button;
                    onClicked: {
                            //console.log('checked to', model.id, checked);
                            selectedBotId = model.id;
                            _bots.setSetting("search_last_bot_id", selectedBotId);
                        }
                }
        }


        Button {
            width: pageWidth
            text: qsTr("Search")
            enabled: selectedBotId != 0 && inputName.text != ''

            anchors.horizontalCenter: parent.horizontalCenter

            onClicked: {

                pageStack.push(Qt.resolvedUrl("PageSearchResults.qml"),
                               { what: inputName.text,
                                 where: inputLocation.text,
                                 tag: selectedTag,
                                 botId: selectedBotId});

            }
        }
    }



    Component.onCompleted: {

        selectedTag = _setting.get("search_last_used_tag", "person_search");

        _bots.setBotSearchListTag(selectedTag);
        botView.model = _bots.botSearchList;

    }

    Connections {
        target: _bots
        onBotSearchList_changed: {

            if(!selectedBotId) {
                var lastSelection = parseInt(_setting.get("search_last_bot_id", "0"));

                if(lastSelection != 0) {
                    for(var i=0; i < _bots.botSearchList.count; i++) {
                        if(lastSelection == _bots.botSearchList.getValue(i, "id"))
                            selectedBotId = lastSelection;
                    }
                }
            }

            // validate selection
            var valid = false;
            for(var i=0; i < _bots.botSearchList.count; i++) {
                valid = valid || (_bots.botSearchList.getValue(i, "id") == selectedBotId);
            }

            if(!valid && _bots.botSearchList.count > 0)
                selectedBotId = _bots.botSearchList.getValue(0, "id");

        }
    }

}

