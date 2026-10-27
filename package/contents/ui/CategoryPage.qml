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

// Folder kategorii: wypełnia całą powierzchnię menu pod polem wyszukiwania.
Item {
    id: page

    property var categoryModel
    property string title
    property var categoryIcon

    readonly property var stackView: QQC2.StackView.view

    // Wejście z pola wyszukiwania strzałką w dół (oraz od razu po
    // otwarciu folderu klawiaturą).
    function focusFirst() {
        root.keyboardNav = true
        if (appsGrid.count > 0) {
            appsGrid.currentIndex = 0
            appsGrid.forceActiveFocus()
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.largeSpacing

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.smallSpacing
            Layout.rightMargin: Kirigami.Units.gridUnit
            spacing: Kirigami.Units.smallSpacing

            PC3.ToolButton {
                icon.name: "go-previous"
                icon.width: Math.round(Kirigami.Units.iconSizes.smallMedium * root.uiScale)
                icon.height: icon.width
                display: QQC2.AbstractButton.IconOnly
                text: i18n("Wstecz")

                QQC2.ToolTip.text: text
                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay

                onClicked: page.stackView.pop()
            }

            Kirigami.Icon {
                Layout.preferredWidth:
                    Math.round(Kirigami.Units.iconSizes.smallMedium * root.uiScale)
                Layout.preferredHeight:
                    Math.round(Kirigami.Units.iconSizes.smallMedium * root.uiScale)
                source: page.categoryIcon
            }

            PlasmaExtras.Heading {
                Layout.fillWidth: true
                level: 3
                // Jawna skala interfejsu; 1.15 to mnożnik poziomu 3
                // z PlasmaExtras.Heading (własny binding, nie dziedziczy).
                font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.15 * root.fontScale
                text: page.title
                elide: Text.ElideRight
            }
        }

        GridView {
            id: appsGrid

            readonly property int columns: Math.max(2, Math.floor(
                width / (Kirigami.Units.gridUnit * 5 * root.uiScale)))

            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: Kirigami.Units.gridUnit
            Layout.rightMargin: Kirigami.Units.gridUnit

            clip: true
            // Ta siatka przewija się sama, więc wbudowana nawigacja
            // strzałkami sama doprowadza wybrany kafelek do widoku.
            keyNavigationEnabled: true
            cellWidth: Math.floor(width / columns)
            cellHeight: root.appIconSize + Math.round(Kirigami.Units.gridUnit * 2.5 * root.uiScale)

            model: page.categoryModel

            PC3.ScrollBar.vertical: PC3.ScrollBar {}

            onActiveFocusChanged: {
                if (activeFocus && currentIndex < 0) {
                    currentIndex = 0
                }
            }

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
                        || event.key === Qt.Key_Space) {
                    root.keyboardNav = true
                    if (currentItem) {
                        currentItem.clicked()
                    }
                    event.accepted = true
                    return
                }
                if (event.key === Qt.Key_Up || event.key === Qt.Key_Down
                        || event.key === Qt.Key_Left || event.key === Qt.Key_Right) {
                    root.keyboardNav = true
                    if (event.key === Qt.Key_Up
                            && Math.floor(currentIndex / columns) === 0) {
                        searchField.forceActiveFocus()
                        event.accepted = true
                    }
                }
            }

            delegate: AppTile {
                width: appsGrid.cellWidth
                height: appsGrid.cellHeight
                text: model.display
                iconSource: model.decoration
                iconSize: root.appIconSize
                favoriteId: model.favoriteId ?? ""
                keyboardSelected: GridView.isCurrentItem
                    && appsGrid.activeFocus && root.keyboardNav
                onTriggered: {
                    if (model.hasChildren) {
                        // Podkategoria: otwórz kolejny folder na całej powierzchni.
                        const sub = page.stackView.push(
                            Qt.resolvedUrl("CategoryPage.qml"), {
                                categoryModel: page.categoryModel.modelForRow(index),
                                title: model.display,
                                categoryIcon: model.decoration
                            })
                        if (root.keyboardNav && sub && sub.focusFirst) {
                            sub.focusFirst()
                        }
                    } else {
                        page.categoryModel.trigger(index, "", null)
                        root.closeMenu()
                    }
                }
                onActionTriggered: (actionId, argument) => {
                    if (page.categoryModel.trigger(index, actionId, argument)) {
                        root.closeMenu()
                    }
                }
            }
        }
    }
}
