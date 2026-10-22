/*
    SPDX-FileCopyrightText: 2026 Michael Furtak <michaelfurtak@tutanota.com>
    SPDX-License-Identifier: MIT
*/

import QtQuick
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

// Zwykłe menu-popup przy ikonie w panelu — własny dialog plazmowy.
// Wbudowany popup appletu nie istnieje (plasmoid celowo nie ma
// fullRepresentation — patrz main.qml), więc ten dialog jest jedyną
// "zwykłą" postacią menu i niczego nie dubluje.
PlasmaCore.Dialog {
    id: dlg

    type: PlasmaCore.Dialog.AppletPopup
    location: Plasmoid.location
    visualParent: root.fullRepresentationItem
    hideOnWindowDeactivate: true

    // Chwila ostatniego zamknięcia — kliknięcie ikony w panelu najpierw
    // dezaktywuje dialog (hideOnWindowDeactivate go zamyka), a dopiero
    // potem dociera do nas; bez tej blokady ikona nie umiałaby zamykać.
    property double lastClosedAt: 0

    function openMenu() {
        if (Date.now() - lastClosedAt < 300) {
            return
        }
        visible = true
        requestActivate()
        content.reset()
    }

    function closeMenu() {
        visible = false
    }

    function toggle() {
        if (visible) {
            closeMenu()
        } else {
            openMenu()
        }
    }

    onVisibleChanged: {
        if (!visible) {
            lastClosedAt = Date.now()
        }
    }

    mainItem: FullRepresentation {
        id: content
        width: Kirigami.Units.gridUnit * 30
        height: Kirigami.Units.gridUnit * 36
        focus: true
    }
}
