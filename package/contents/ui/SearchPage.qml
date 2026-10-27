/*
    SPDX-FileCopyrightText: 2026 Michael Furtak <michaelfurtak@tutanota.com>
    SPDX-License-Identifier: MIT
*/

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.components as PC3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami

Item {
    id: page

    objectName: "searchPage"

    // Wywoływane Enterem z pola wyszukiwania: uruchom najlepszy wynik.
    function activateFirst() {
        if (resultsList.count > 0) {
            resultsList.model.trigger(0, "", null)
            root.closeMenu()
        }
    }

    // Wywoływane strzałką w dół z pola wyszukiwania.
    function focusFirst() {
        if (resultsList.count > 0) {
            resultsList.currentIndex = 0
            resultsList.forceActiveFocus()
        }
    }

    ListView {
        id: resultsList

        anchors.fill: parent
        anchors.leftMargin: Kirigami.Units.gridUnit
        anchors.rightMargin: Kirigami.Units.gridUnit

        clip: true
        currentIndex: -1
        keyNavigationEnabled: true
        highlightMoveDuration: 0

        // mergeResults: true — wszystkie wyniki w jednym podmodelu (wiersz 0).
        model: runnerModel.count > 0 ? runnerModel.modelForRow(0) : null

        PC3.ScrollBar.vertical: PC3.ScrollBar {}

        delegate: PC3.ItemDelegate {
            id: resultDelegate

            width: resultsList.width
            text: model.display
            highlighted: ListView.isCurrentItem

            onClicked: {
                resultsList.model.trigger(index, "", null)
                root.closeMenu()
            }

            // Standardowe menu kontekstowe launchera, jak na kafelkach.
            function openContextMenu(pos) {
                if (!model.hasActionList) {
                    return
                }
                const list = model.actionList
                if (!list || list.length === 0) {
                    return
                }
                resultMenu.actionList = list
                resultMenu.open(pos.x, pos.y)
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.RightButton
                onClicked: mouse => resultDelegate.openContextMenu(Qt.point(mouse.x, mouse.y))
            }

            ActionsMenu {
                id: resultMenu
                visualParent: resultDelegate
                onActionClicked: (actionId, argument) => {
                    if (resultsList.model.trigger(index, actionId, argument)) {
                        root.closeMenu()
                    }
                }
            }

            contentItem: RowLayout {
                spacing: Kirigami.Units.smallSpacing

                Kirigami.Icon {
                    Layout.preferredWidth:
                        Math.round(Kirigami.Units.iconSizes.medium * root.uiScale)
                    Layout.preferredHeight:
                        Math.round(Kirigami.Units.iconSizes.medium * root.uiScale)
                    source: model.decoration
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    QQC2.Label {
                        Layout.fillWidth: true
                        text: model.display
                        elide: Text.ElideRight
                    }

                    PlasmaExtras.DescriptiveLabel {
                        Layout.fillWidth: true
                        text: model.description ?? ""
                        visible: text.length > 0
                        elide: Text.ElideRight
                        // Mniejszy font opisu skalowany razem z interfejsem
                        // (jawnie — przypisanie całego fontu wyłącza
                        // dziedziczenie pointSize z menu).
                        font.pointSize: Kirigami.Theme.smallFont.pointSize * root.fontScale
                    }
                }
            }
        }

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Up && resultsList.currentIndex === 0) {
                resultsList.currentIndex = -1
                searchField.forceActiveFocus()
                event.accepted = true
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                if (resultsList.currentIndex >= 0) {
                    resultsList.model.trigger(resultsList.currentIndex, "", null)
                    root.closeMenu()
                }
                event.accepted = true
            }
        }
    }

    PlasmaExtras.PlaceholderMessage {
        anchors.centerIn: parent
        width: parent.width - Kirigami.Units.gridUnit * 4
        visible: resultsList.count === 0 && !runnerModel.querying
        iconName: "edit-none"
        text: i18n("Brak wyników")
    }
}
