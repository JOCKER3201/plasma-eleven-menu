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
                display: QQC2.AbstractButton.IconOnly
                text: i18n("Wstecz")

                QQC2.ToolTip.text: text
                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay

                onClicked: page.stackView.pop()
            }

            Kirigami.Icon {
                Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                source: page.categoryIcon
            }

            PlasmaExtras.Heading {
                Layout.fillWidth: true
                level: 3
                text: page.title
                elide: Text.ElideRight
            }
        }

        GridView {
            id: appsGrid

            readonly property int columns:
                Math.max(4, Math.floor(width / (Kirigami.Units.gridUnit * 6)))

            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: Kirigami.Units.gridUnit
            Layout.rightMargin: Kirigami.Units.gridUnit

            clip: true
            cellWidth: Math.floor(width / columns)
            cellHeight: Kirigami.Units.gridUnit * 5.5

            model: page.categoryModel

            PC3.ScrollBar.vertical: PC3.ScrollBar {}

            delegate: AppTile {
                width: appsGrid.cellWidth
                height: appsGrid.cellHeight
                text: model.display
                iconSource: model.decoration
                favoriteId: model.favoriteId ?? ""
                onTriggered: {
                    if (model.hasChildren) {
                        // Podkategoria: otwórz kolejny folder na całej powierzchni.
                        page.stackView.push(Qt.resolvedUrl("CategoryPage.qml"), {
                            categoryModel: page.categoryModel.modelForRow(index),
                            title: model.display,
                            categoryIcon: model.decoration
                        })
                    } else {
                        page.categoryModel.trigger(index, "", null)
                        root.expanded = false
                    }
                }
                onActionTriggered: (actionId, argument) => {
                    if (page.categoryModel.trigger(index, actionId, argument)) {
                        root.expanded = false
                    }
                }
            }
        }
    }
}
