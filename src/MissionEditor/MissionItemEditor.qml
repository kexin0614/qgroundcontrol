import QtQuick                  2.3
import QtQuick.Controls         1.2
import QtQuick.Controls.Styles  1.4
import QtQuick.Dialogs          1.2

import QGroundControl.ScreenTools   1.0
import QGroundControl.Vehicle       1.0
import QGroundControl.Controls      1.0
import QGroundControl.FactControls  1.0
import QGroundControl.Palette       1.0


/// Mission item edit control
Rectangle {
    id: _root

    height: editorLoader.y + editorLoader.height + (_margin * 2)
    color:  _currentItem ? qgcPal.buttonHighlight : qgcPal.windowShade
    radius: _radius

    property var    missionItem     ///< MissionItem associated with this editor
    property bool   readOnly        ///< true: read only view, false: full editing view

    signal clicked
    signal remove
    signal insert
    signal moveHomeToMapCenter

    property bool   _currentItem:           missionItem.isCurrentItem
    property color  _outerTextColor:        _currentItem ? "black" : qgcPal.text
    property bool   _noMissionItemsAdded:   ListView.view.model.count == 1

    readonly property real  _editFieldWidth:    Math.min(width - _margin * 2, ScreenTools.defaultFontPixelWidth * 12)
    readonly property real  _margin:            ScreenTools.defaultFontPixelWidth / 2
    readonly property real  _radius:            ScreenTools.defaultFontPixelWidth / 2
    readonly property real  _hamburgerSize:     commandPicker.height * 0.75

    QGCPalette {
        id: qgcPal
        colorGroupEnabled: enabled
    }

    MouseArea {
        anchors.fill:   parent
        onClicked:      _root.clicked()
    }

    QGCLabel {
        id:                     label
        anchors.verticalCenter: commandPicker.verticalCenter
        anchors.leftMargin:     _margin
        anchors.left:           parent.left
        text:                   missionItem.abbreviation
        color:                  _outerTextColor
    }

    QGCColoredImage {
        id:                     hamburger
        anchors.rightMargin:    ScreenTools.defaultFontPixelWidth
        anchors.right:          parent.right
        anchors.verticalCenter: commandPicker.verticalCenter
        width:                  _hamburgerSize
        height:                 _hamburgerSize
        sourceSize.height:      _hamburgerSize
        source:                 "qrc:/qmlimages/Hamburger.svg"
        visible:                missionItem.isCurrentItem && missionItem.sequenceNumber != 0
        color:                  qgcPal.windowShade

    }

    MouseArea {
        // The MouseArea for the hamburger is larger than the hamburger image itself in order to provide a larger
        // touch area on mobile
        anchors.top:        parent.top
        anchors.bottom:     editorLoader.top
        anchors.leftMargin: -hamburger.anchors.rightMargin
        anchors.left:       hamburger.left
        anchors.right:      parent.right
        onClicked:          hamburgerMenu.popup()

        Menu {
            id: hamburgerMenu

            MenuItem {
                text:           qsTr("Insert")
                onTriggered:    insert()
            }

            MenuItem {
                text:           qsTr("Delete")
                onTriggered:    remove()
            }

            MenuItem {
                text:           "Change command..."
                onTriggered:    commandPicker.clicked()
            }

            MenuSeparator {
                visible: missionItem.isSimpleItem
            }

            MenuItem {
                text:       qsTr("Show all values")
                checkable:  true
                checked:    missionItem.isSimpleItem ? missionItem.rawEdit : false
                visible:    missionItem.isSimpleItem

                onTriggered:    {
                    if (missionItem.rawEdit) {
                        if (missionItem.friendlyEditAllowed) {
                            missionItem.rawEdit = false
                        } else {
                            qgcView.showMessage(qsTr("Mission Edit"), qsTr("You have made changes to the mission item which cannot be shown in Simple Mode"), StandardButton.Ok)
                        }
                    } else {
                        missionItem.rawEdit = true
                    }
                    checked = missionItem.rawEdit
                }
            }
        }
    }

    QGCButton {
        id:                     commandPicker
        anchors.topMargin:      _margin / 2
        anchors.leftMargin:     ScreenTools.defaultFontPixelWidth * 2
        anchors.rightMargin:    ScreenTools.defaultFontPixelWidth
        anchors.left:           label.right
        anchors.top:            parent.top
        visible:                missionItem.sequenceNumber != 0 && missionItem.isCurrentItem && !missionItem.rawEdit && missionItem.isSimpleItem
        text:                   missionItem.commandName

        Component {
            id: commandDialog

            MissionCommandDialog {
                missionItem: _root.missionItem
            }
        }

        onClicked: qgcView.showDialog(commandDialog, qsTr("Select Mission Command"), qgcView.showDialogDefaultWidth, StandardButton.Cancel)
    }

    QGCLabel {
        anchors.fill:       commandPicker
        visible:            missionItem.sequenceNumber == 0 || !missionItem.isCurrentItem || !missionItem.isSimpleItem
        verticalAlignment:  Text.AlignVCenter
        text:               missionItem.sequenceNumber == 0 ? qsTr("Mission Settings") : missionItem.commandName
        color:              _outerTextColor
    }

    Loader {
        id:                 editorLoader
        anchors.leftMargin: _margin
        anchors.topMargin:  _margin
        anchors.left:       parent.left
        anchors.top:        commandPicker.bottom
        height:             item ? item.height : 0
        source:             missionItem.sequenceNumber == 0 ? "qrc:/qml/MissionSettingsEditor.qml" : missionItem.editorQml

        onLoaded: {
            item.visible = Qt.binding(function() { return _currentItem; })
        }

        property real   availableWidth: _root.width - (_margin * 2) ///< How wide the editor should be
        property var    editorRoot:     _root
    }
} // Rectangle
