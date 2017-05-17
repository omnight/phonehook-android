import QtQuick 2.6
import QtQuick.Controls 2.0
import QtQuick.Controls.Styles 1.4
import QtQuick.Controls.Material 2.0


import "control"

PageBase {
    title: qsTr("Results")
    pageName: "results"

    property string what
    property string where
    property string tag
    property int botId

    Component.onCompleted: {
        _bots.search( {"searchName": what,
                       "searchArea": where,
                       "tagWanted": tag},
                     true, botId);
    }

    Item {
        width: pageWidth
        height: 10*ps
    }

    Label {
        visible: _bots.searchResult.length == 0 && !_bots.searchResultLoading && _bots.searchResultNext == null
        text: qsTr("No Results")
        font.pixelSize: 14*ps
        anchors.horizontalCenter: parent
    }

    function maybeLoadMore() {
        if(!_bots.searchResultLoading && contentScroller.atYEnd && _bots.searchResultNext != null) {
            console.log('next page', JSON.stringify(_bots.searchResultNext), botId);
            _bots.search( _bots.searchResultNext,
                         false, botId);
        }
    }

    Connections {
        target: _bots
        onSearchResultLoadingChanged: {
            maybeLoadMore();
        }
    }

    Connections {
        target: contentScroller
        onAtYEndChanged: {
            maybeLoadMore();
        }
    }

    ListView {
        id: resultList
        height: contentHeight
        width: pageWidth
        model: _bots.searchResult
        interactive: false

        delegate: SearchResultListItem {
            width: pageWidth
            name: model.modelData.name
            address: model.modelData.address.replace(/\n/g, ", ")
            isBusiness: model.modelData.type == 'business'
            onClicked: {
                pageStack.push(Qt.resolvedUrl("PageSearchResultDetail.qml"), { resultData: model.modelData } )
            }
        }

        footer: BusyIndicator {
            width: 40*ps
            height: 40*ps
            anchors.horizontalCenter: parent.horizontalCenter
            running: _bots.searchResultLoading
            visible: _bots.searchResultLoading
        }

    }

/*
    Label {
        width: pageWidth
        text: "---"
    }

    */

}

