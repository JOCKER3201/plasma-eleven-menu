/*
    SPDX-FileCopyrightText: 2026 Michael Furtak <michaelfurtak@tutanota.com>
    SPDX-License-Identifier: MIT
*/

import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

// Kafelek aplikacji: ikona z podpisem, podświetlenie po najechaniu,
// menu „Przypnij/Odepnij" pod prawym przyciskiem.
QQC2.AbstractButton {
    id: tile

    property var iconSource
    property string favoriteId: ""
    property int iconSize: Kirigami.Units.iconSizes.medium

    signal triggered()
    // Akcja z menu kontekstowego do wykonania na modelu źródłowym wiersza
    // (trigger musi wywołać właściciel modelu, nie kafelek).
    signal actionTriggered(string actionId, var argument)

    hoverEnabled: true
    padding: Math.max(1, Math.round(Kirigami.Units.smallSpacing / 2))

    onClicked: triggered()

    contentItem: Item {
        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            spacing: Math.max(1, Math.round(Kirigami.Units.smallSpacing / 2))

            Kirigami.Icon {
                anchors.horizontalCenter: parent.horizontalCenter
                width: tile.iconSize
                height: tile.iconSize
                source: tile.iconSource
            }

            QQC2.Label {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: tile.text
                wrapMode: Text.Wrap
                elide: Text.ElideRight
                maximumLineCount: 2
            }
        }
    }

    background: Rectangle {
        radius: Kirigami.Units.cornerRadius
        color: tile.pressed
            ? Qt.alpha(Kirigami.Theme.textColor, 0.15)
            : tile.hovered || tile.visualFocus
                ? Qt.alpha(Kirigami.Theme.textColor, 0.08)
                : "transparent"
    }

    // Standardowe menu kontekstowe launchera: akcje z backendu kicker
    // (Dodaj na pulpit, Przypnij do paska zadań, akcje aplikacji, ostatnie
    // dokumenty, Edytuj programy…) + nasze Przypnij/Odepnij na końcu.
    function openContextMenu(pos) {
        let list = []
        if (model.hasActionList) {
            const fromModel = model.actionList
            if (fromModel && fromModel.length > 0) {
                list = list.concat(fromModel)
            }
        }
        if (favoriteId.length > 0) {
            if (list.length > 0) {
                list.push({ separator: true })
            }
            const isFav = rootModel.favoritesModel.isFavorite(favoriteId)
            list.push({
                text: isFav
                    ? i18n("Odepnij od sekcji Przypięte")
                    : i18n("Przypnij do sekcji Przypięte"),
                icon: isFav ? "window-unpin" : "pin",
                actionId: "_eleven_toggle_favorite"
            })
        }
        if (list.length === 0) {
            return
        }
        contextMenu.actionList = list
        contextMenu.open(pos.x, pos.y)
    }

    function handleAction(actionId, argument) {
        if (actionId.length === 0) {
            return
        }
        if (actionId === "_eleven_toggle_favorite") {
            if (rootModel.favoritesModel.isFavorite(favoriteId)) {
                rootModel.favoritesModel.removeFavorite(favoriteId)
            } else {
                rootModel.favoritesModel.addFavorite(favoriteId)
            }
            return
        }
        actionTriggered(actionId, argument)
    }

    // Prawy przycisk przejmowany twardo od wciśnięcia (exclusive grab,
    // bez progu ruchu jak w TapHandler) — zawsze i wyłącznie otwiera menu.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onClicked: mouse => tile.openContextMenu(Qt.point(mouse.x, mouse.y))
    }

    // Długie przytrzymanie (dotyk) — wbudowany gest przycisku.
    onPressAndHold: openContextMenu(Qt.point(width / 2, height / 2))

    ActionsMenu {
        id: contextMenu
        visualParent: tile
        onActionClicked: (actionId, argument) => tile.handleAction(actionId, argument)
    }
}
