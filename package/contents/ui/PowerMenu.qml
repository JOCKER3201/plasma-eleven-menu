/*
    SPDX-FileCopyrightText: 2026 Michael Furtak <michaelfurtak@tutanota.com>
    SPDX-License-Identifier: MIT
*/

import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.extras as PlasmaExtras

// Menu zasilania: akcje systemowe z modelu kickera + opcjonalna pozycja
// "Tryb Game Mode" (tylko gdy przy starcie appletu istnieje
// /usr/bin/return-to-gamemode i akcja jest włączona w ustawieniach).
// Pozycje modelowe są wstawiane zawsze PRZED separatorem Game Mode,
// więc Game Mode trzyma się końca menu.
PlasmaExtras.Menu {
    id: menu

    PlasmaExtras.MenuItem {
        id: gameModeSeparator
        separator: true
        visible: gameModeItem.visible
    }

    PlasmaExtras.MenuItem {
        id: gameModeItem
        text: i18n("Tryb Game Mode")
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
