/*
    SPDX-FileCopyrightText: 2026 Michael Furtak <michaelfurtak@tutanota.com>
    SPDX-License-Identifier: MIT
*/

import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

// Kafelek kategorii jak w menu Start Windows 11: zaokrąglona płytka
// z podglądem 2×2 ikon pierwszych aplikacji i podpisem pod spodem.
QQC2.AbstractButton {
    id: tile

    // Model aplikacji tej kategorii (do podglądu mini-ikon).
    property var categoryModel

    signal opened()

    hoverEnabled: true
    padding: Kirigami.Units.smallSpacing

    onClicked: opened()

    background: null

    contentItem: Column {
        spacing: Kirigami.Units.smallSpacing

        Rectangle {
            id: box

            width: parent.width
            height: tile.availableHeight - label.height - parent.spacing
            radius: Kirigami.Units.cornerRadius
            color: tile.pressed
                ? Qt.alpha(Kirigami.Theme.textColor, 0.15)
                : tile.hovered
                    ? Qt.alpha(Kirigami.Theme.textColor, 0.10)
                    : Qt.alpha(Kirigami.Theme.textColor, 0.05)
            border.width: tile.visualFocus ? 1 : 0
            border.color: Kirigami.Theme.highlightColor
            clip: true

            // Podgląd zawartości: pierwsze cztery ikony aplikacji (2×2);
            // wielkość mini-ikon idzie za ustawieniem wielkości ikon.
            GridView {
                id: miniGrid

                anchors.centerIn: parent
                width: cellWidth * 2
                height: cellHeight * 2

                cellWidth: root.appIconSize + Kirigami.Units.smallSpacing
                cellHeight: cellWidth

                interactive: false
                clip: true
                cacheBuffer: 0

                model: tile.categoryModel

                delegate: Item {
                    width: miniGrid.cellWidth
                    height: miniGrid.cellHeight

                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: root.appIconSize
                        height: width
                        source: model.decoration
                    }
                }
            }
        }

        QQC2.Label {
            id: label

            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: tile.text
            elide: Text.ElideRight
            maximumLineCount: 1
        }
    }
}
