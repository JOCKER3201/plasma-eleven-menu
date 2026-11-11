/*
    SPDX-FileCopyrightText: 2026 JOCKER3201 <noreply@users.noreply.github.com>
    SPDX-License-Identifier: MIT
*/

import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

// Category tile like in the Windows 11 Start menu: a rounded plate with
// a 2×2 icon preview of the first applications and a caption underneath.
QQC2.AbstractButton {
    id: tile

    // The application model of this category (for the mini-icon preview).
    property var categoryModel

    // The tile pointed at with the arrow keys (keyboard navigation mode) —
    // highlighted like hover.
    property bool keyboardSelected: false

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
                : tile.keyboardSelected || (tile.hovered && !root.keyboardNav)
                    ? Qt.alpha(Kirigami.Theme.textColor, 0.10)
                    : Qt.alpha(Kirigami.Theme.textColor, 0.05)
            border.width: tile.visualFocus ? 1 : 0
            border.color: Kirigami.Theme.highlightColor
            clip: true

            // Content preview: the first four application icons (2×2);
            // the mini-icon size follows the icon size setting.
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
