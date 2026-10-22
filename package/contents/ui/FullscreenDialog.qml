/*
    SPDX-FileCopyrightText: 2026 Michael Furtak <michaelfurtak@tutanota.com>
    SPDX-License-Identifier: MIT
*/

import QtQuick
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

// Tryb pełnoekranowy jako plazmowy popup (PlasmaCore.Dialog), nie okno:
// dialog typu Normal pokrywa cały ekran, ale żyje w warstwie zwykłych
// okien — panele Plasmy (warstwa zawsze-na-wierzchu) pozostają widoczne
// i klikalne nad nim. Zawartość otwiera się animacją od środka ekranu
// i jest odsunięta od krawędzi zajmowanych przez panele, żeby nic
// (np. pole wyszukiwania) nie wpadało pod panel.
PlasmaCore.Dialog {
    id: dlg

    type: PlasmaCore.Dialog.Normal
    backgroundHints: PlasmaCore.Dialog.NoBackground
    location: PlasmaCore.Types.Floating
    flags: Qt.FramelessWindowHint
    hideOnWindowDeactivate: true

    x: root.screenGeometry.x
    y: root.screenGeometry.y

    // Obszar wolny od paneli, ZNORMALIZOWANY do układu lokalnego ekranu
    // (0,0 = lewy górny róg ekranu appletu). availableScreenRect bywa
    // raportowane lokalnie (na monitorach przesuniętych w układzie
    // globalnym, np. drugi monitor od x=2560) albo globalnie — tu
    // sprowadzamy oba warianty do jednego. Pusty prostokąt => cały ekran.
    readonly property rect localFreeArea: {
        const sg = root.screenGeometry
        const ar = root.availableScreenRect
        if (!ar || ar.width <= 0 || ar.height <= 0) {
            return Qt.rect(0, 0, sg.width, sg.height)
        }
        // Wariant globalny: prostokąt mieści się w globalnej geometrii
        // ekranu — przesuwamy do układu lokalnego.
        if (ar.x >= sg.x && ar.y >= sg.y
                && ar.x + ar.width <= sg.x + sg.width + 1
                && ar.y + ar.height <= sg.y + sg.height + 1) {
            return Qt.rect(ar.x - sg.x, ar.y - sg.y, ar.width, ar.height)
        }
        // Wariant lokalny: przycinamy do rozmiaru ekranu dla pewności.
        return Qt.rect(
            Math.max(0, ar.x),
            Math.max(0, ar.y),
            Math.min(ar.width, sg.width),
            Math.min(ar.height, sg.height))
    }

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
        fsContent.reset()
        openAnimation.restart()
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

    mainItem: Item {
        id: screenItem

        width: root.screenGeometry.width
        height: root.screenGeometry.height

        transformOrigin: Item.Center

        Rectangle {
            anchors.fill: parent
            color: Kirigami.Theme.backgroundColor
            Kirigami.Theme.colorSet: Kirigami.Theme.Window
            Kirigami.Theme.inherit: false
        }

        // Zawartość omija panele: marginesy z każdej strony to różnica
        // między geometrią ekranu a obszarem wolnym od paneli.
        FullRepresentation {
            id: fsContent

            anchors.fill: parent
            anchors.leftMargin: Kirigami.Units.gridUnit
                + Math.max(0, dlg.localFreeArea.x)
            anchors.topMargin: Kirigami.Units.gridUnit
                + Math.max(0, dlg.localFreeArea.y)
            anchors.rightMargin: Kirigami.Units.gridUnit + Math.max(0,
                root.screenGeometry.width
                - dlg.localFreeArea.x - dlg.localFreeArea.width)
            anchors.bottomMargin: Kirigami.Units.gridUnit + Math.max(0,
                root.screenGeometry.height
                - dlg.localFreeArea.y - dlg.localFreeArea.height)

            focus: true
        }

        ParallelAnimation {
            id: openAnimation

            NumberAnimation {
                target: screenItem
                property: "scale"
                from: 0.6
                to: 1.0
                duration: Kirigami.Units.longDuration
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: screenItem
                property: "opacity"
                from: 0.0
                to: 1.0
                duration: Kirigami.Units.longDuration
                easing.type: Easing.OutCubic
            }
        }
    }
}
