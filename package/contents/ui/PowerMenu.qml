/*
    SPDX-FileCopyrightText: 2026 JOCKER3201 <noreply@users.noreply.github.com>
    SPDX-License-Identifier: MIT
*/

import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.extras as PlasmaExtras

// Power menu: system actions from the kicker model + an optional
// "Game Mode" entry (only when an executable /usr/bin/return-to-gamemode
// exists at applet start and the action is enabled in the settings).
// The model entries are always inserted BEFORE the Game Mode separator,
// so Game Mode sticks to the end of the menu.
PlasmaExtras.Menu {
    id: menu

    PlasmaExtras.MenuItem {
        id: gameModeSeparator
        separator: true
        visible: gameModeItem.visible
    }

    PlasmaExtras.MenuItem {
        id: gameModeItem
        text: i18n("Game Mode")
        icon: "input-gaming"
        visible: root.gameModeAvailable
            && Plasmoid.configuration.powerActions.indexOf("gamemode") !== -1
        onClicked: root.runGameMode()
    }

    property Instantiator _systemItems: Instantiator {
        model: rootModel.systemFavoritesModel

        delegate: PlasmaExtras.MenuItem {
            required property var model
            required property int index

            text: model.display ?? ""
            icon: model.decoration
            onClicked: rootModel.systemFavoritesModel.trigger(index, "", null)
        }

        onObjectAdded: (index, object) => menu.addMenuItem(object, gameModeSeparator)
        onObjectRemoved: (index, object) => menu.removeMenuItem(object)
    }
}
