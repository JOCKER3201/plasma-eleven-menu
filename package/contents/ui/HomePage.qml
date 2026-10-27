/*
    SPDX-FileCopyrightText: 2026 Michael Furtak <michaelfurtak@tutanota.com>
    SPDX-License-Identifier: MIT
*/

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PC3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami

Flickable {
    id: homePage

    readonly property var stackView: QQC2.StackView.view

    clip: true
    contentWidth: -1
    contentHeight: content.implicitHeight
    boundsBehavior: Flickable.StopAtBounds

    // Wejście z pola wyszukiwania strzałką w dół: fokus na pierwszy
    // kafelek (Przypięte, a gdy sekcja ukryta — kategorie).
    function focusFirst() {
        root.keyboardNav = true
        const grid = pinnedGrid.visible ? pinnedGrid : categoriesGrid
        if (grid.count > 0) {
            grid.currentIndex = 0
            grid.forceActiveFocus()
        }
    }

    // Siatki nie przewijają się same (pełna wysokość w Flickable) —
    // kafelek wybrany strzałkami doprowadzamy do widoku ręcznie.
    function ensureVisible(item) {
        if (!item) {
            return
        }
        const y = item.mapToItem(content, 0, 0).y
        const bottom = y + item.height
        if (y < contentY) {
            contentY = Math.max(0, y - Kirigami.Units.smallSpacing)
        } else if (bottom > contentY + height) {
            contentY = Math.min(Math.max(0, contentHeight - height),
                                bottom - height + Kirigami.Units.smallSpacing)
        }
    }

    PC3.ScrollBar.vertical: PC3.ScrollBar {}

    ColumnLayout {
        id: content
        width: homePage.width
        height: implicitHeight
        spacing: Kirigami.Units.largeSpacing

        // ------------------------- Przypięte -------------------------

        PlasmaExtras.Heading {
            Layout.leftMargin: Kirigami.Units.gridUnit
            level: 4
            // Heading ma własny binding rozmiaru (nie dziedziczy fontu
            // z menu) — skala interfejsu nakładana jawnie; 1.10 to mnożnik
            // poziomu 4 z PlasmaExtras.Heading.
            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.10 * root.fontScale
            text: i18n("Przypięte")
            visible: pinnedGrid.visible
        }

        GridView {
            id: pinnedGrid

            readonly property int columns: Math.max(2, Math.floor(
                width / (Kirigami.Units.gridUnit * 4.5 * root.uiScale)))

            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.gridUnit
            Layout.rightMargin: Kirigami.Units.gridUnit
            Layout.preferredHeight: Math.ceil(count / columns) * cellHeight

            visible: Plasmoid.configuration.showPinned && count > 0
            interactive: false
            // Przy interactive: false wbudowana nawigacja strzałkami jest
            // domyślnie wyłączona — włączamy jawnie.
            keyNavigationEnabled: true
            cellWidth: Math.floor(width / columns)
            cellHeight: root.appIconSize + Math.round(Kirigami.Units.gridUnit * 2.5 * root.uiScale)

            model: rootModel.favoritesModel

            // Wejście z siatki kategorii strzałką w górę: ostatni wiersz,
            // możliwie ta sama kolumna.
            function focusFromBelow(col) {
                const lastRowStart =
                    (Math.ceil(count / columns) - 1) * columns
                currentIndex = Math.min(lastRowStart + col, count - 1)
                forceActiveFocus()
            }

            onActiveFocusChanged: {
                if (activeFocus && currentIndex < 0) {
                    currentIndex = 0
                }
                if (activeFocus) {
                    homePage.ensureVisible(currentItem)
                }
            }
            onCurrentItemChanged: {
                if (activeFocus) {
                    homePage.ensureVisible(currentItem)
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
                    const row = Math.floor(currentIndex / columns)
                    if (event.key === Qt.Key_Up && row === 0) {
                        searchField.forceActiveFocus()
                        event.accepted = true
                    } else if (event.key === Qt.Key_Down
                               && row === Math.floor((count - 1) / columns)) {
                        categoriesGrid.focusFromAbove(currentIndex % columns)
                        event.accepted = true
                    }
                    // Pozostałe ruchy obsługuje wbudowana nawigacja GridView.
                }
            }

            delegate: AppTile {
                width: pinnedGrid.cellWidth
                height: pinnedGrid.cellHeight
                text: model.display
                iconSource: model.decoration
                iconSize: root.appIconSize
                favoriteId: model.favoriteId ?? ""
                keyboardSelected: GridView.isCurrentItem
                    && pinnedGrid.activeFocus && root.keyboardNav
                onTriggered: {
                    rootModel.favoritesModel.trigger(index, "", null)
                    root.closeMenu()
                }
                onActionTriggered: (actionId, argument) => {
                    if (rootModel.favoritesModel.trigger(index, actionId, argument)) {
                        root.closeMenu()
                    }
                }
            }
        }

        // --------------------- Wszystko: kategorie --------------------

        PlasmaExtras.Heading {
            Layout.leftMargin: Kirigami.Units.gridUnit
            level: 4
            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.10 * root.fontScale
            text: i18n("Wszystko")
        }

        GridView {
            id: categoriesGrid

            readonly property int columns: Math.max(2, Math.floor(
                width / (Kirigami.Units.gridUnit * 9 * root.uiScale)))

            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.gridUnit
            Layout.rightMargin: Kirigami.Units.gridUnit
            Layout.preferredHeight: Math.ceil(count / columns) * cellHeight

            interactive: false
            keyNavigationEnabled: true
            cellWidth: Math.floor(width / columns)
            cellHeight: Math.round(cellWidth * 0.62) + Math.round(Kirigami.Units.gridUnit * 1.6)

            model: rootModel

            // Wejście z siatki Przypiętych strzałką w dół: pierwszy
            // wiersz, możliwie ta sama kolumna.
            function focusFromAbove(col) {
                currentIndex = Math.min(col, count - 1)
                forceActiveFocus()
            }

            onActiveFocusChanged: {
                if (activeFocus && currentIndex < 0) {
                    currentIndex = 0
                }
                if (activeFocus) {
                    homePage.ensureVisible(currentItem)
                }
            }
            onCurrentItemChanged: {
                if (activeFocus) {
                    homePage.ensureVisible(currentItem)
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
                        if (pinnedGrid.visible && pinnedGrid.count > 0) {
                            pinnedGrid.focusFromBelow(currentIndex % columns)
                        } else {
                            searchField.forceActiveFocus()
                        }
                        event.accepted = true
                    }
                }
            }

            delegate: CategoryTile {
                width: categoriesGrid.cellWidth
                height: categoriesGrid.cellHeight
                text: model.display
                categoryModel: rootModel.modelForRow(index)
                keyboardSelected: GridView.isCurrentItem
                    && categoriesGrid.activeFocus && root.keyboardNav
                onOpened: {
                    const page = homePage.stackView.push(
                        Qt.resolvedUrl("CategoryPage.qml"), {
                            categoryModel: rootModel.modelForRow(index),
                            title: model.display,
                            categoryIcon: model.decoration
                        })
                    // Folder otwarty klawiaturą od razu przejmuje strzałki.
                    if (root.keyboardNav && page && page.focusFirst) {
                        page.focusFirst()
                    }
                }
            }
        }

        Item {
            Layout.preferredHeight: Kirigami.Units.smallSpacing
        }
    }
}
