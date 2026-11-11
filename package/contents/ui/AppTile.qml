/*
    SPDX-FileCopyrightText: 2026 JOCKER3201 <noreply@users.noreply.github.com>
    SPDX-License-Identifier: MIT
*/

import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

// Application tile: an icon with a caption, a highlight on hover,
// a "Pin/Unpin" menu under the right mouse button.
QQC2.AbstractButton {
    id: tile

    property var iconSource
    property string favoriteId: ""
    property int iconSize: Kirigami.Units.iconSizes.medium
    // Set by the grid delegate: the tile pointed at with the arrow keys
    // (in keyboard navigation mode) — highlighted like hover.
    property bool keyboardSelected: false

    signal triggered()
    // A context-menu action to be executed on the row's source model
    // (trigger must be called by the model's owner, not by the tile).
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
        // In keyboard navigation mode, hover under the cursor does NOT
        // light up — only the tile selected with the arrow keys is
        // highlighted (with the same color).
        color: tile.pressed
            ? Qt.alpha(Kirigami.Theme.textColor, 0.15)
            : tile.keyboardSelected || tile.visualFocus
                  || (tile.hovered && !root.keyboardNav)
                ? Qt.alpha(Kirigami.Theme.textColor, 0.08)
                : "transparent"
    }

    // The standard launcher context menu: actions from the kicker backend
    // (Add to Desktop, Pin to Task Manager, application actions, recent
    // documents, Edit Applications…) + our Pin/Unpin at the end.
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
                    ? i18n("Unpin from Pinned section")
                    : i18n("Pin to Pinned section"),
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

    // The right button is grabbed firmly from the press (an exclusive
    // grab, without TapHandler's movement threshold) — it always and only
    // opens the menu.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onClicked: mouse => tile.openContextMenu(Qt.point(mouse.x, mouse.y))
    }

    // Long press (touch) — the button's built-in gesture.
    onPressAndHold: openContextMenu(Qt.point(width / 2, height / 2))

    ActionsMenu {
        id: contextMenu
        visualParent: tile
        onActionClicked: (actionId, argument) => tile.handleAction(actionId, argument)
    }
}
