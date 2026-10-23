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
            text: i18n("Przypięte")
            visible: pinnedGrid.visible
        }

        GridView {
            id: pinnedGrid

            readonly property int columns: Math.max(2, Math.floor(
                width / (Kirigami.Units.gridUnit * 4.5 * root.iconScale)))

            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.gridUnit
            Layout.rightMargin: Kirigami.Units.gridUnit
            Layout.preferredHeight: Math.ceil(count / columns) * cellHeight

            visible: Plasmoid.configuration.showPinned && count > 0
            interactive: false
            cellWidth: Math.floor(width / columns)
            cellHeight: root.appIconSize + Math.round(Kirigami.Units.gridUnit * 2.5)

            model: rootModel.favoritesModel

            delegate: AppTile {
                width: pinnedGrid.cellWidth
                height: pinnedGrid.cellHeight
                text: model.display
                iconSource: model.decoration
                iconSize: root.appIconSize
                favoriteId: model.favoriteId ?? ""
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
            text: i18n("Wszystko")
        }

        GridView {
            id: categoriesGrid

            readonly property int columns: Math.max(2, Math.floor(
                width / (Kirigami.Units.gridUnit * 9 * root.iconScale)))

            Layout.fillWidth: true
            Layout.leftMargin: Kirigami.Units.gridUnit
            Layout.rightMargin: Kirigami.Units.gridUnit
            Layout.preferredHeight: Math.ceil(count / columns) * cellHeight

            interactive: false
            cellWidth: Math.floor(width / columns)
            cellHeight: Math.round(cellWidth * 0.62) + Math.round(Kirigami.Units.gridUnit * 1.6)

            model: rootModel

            delegate: CategoryTile {
                width: categoriesGrid.cellWidth
                height: categoriesGrid.cellHeight
                text: model.display
                categoryModel: rootModel.modelForRow(index)
                onOpened: {
                    homePage.stackView.push(Qt.resolvedUrl("CategoryPage.qml"), {
                        categoryModel: rootModel.modelForRow(index),
                        title: model.display,
                        categoryIcon: model.decoration
                    })
                }
            }
        }

        Item {
            Layout.preferredHeight: Kirigami.Units.smallSpacing
        }
    }
}
