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
// i klikalne nad nim. Zawartość otwiera i zamyka animacja od/do środka
// ekranu i jest odsunięta od krawędzi zajmowanych przez panele.
PlasmaCore.Dialog {
    id: dlg

    type: PlasmaCore.Dialog.Normal
    backgroundHints: PlasmaCore.Dialog.NoBackground
    location: PlasmaCore.Types.Floating
    flags: Qt.FramelessWindowHint

    // Zamknięciem (też po utracie aktywności) sterujemy sami, żeby zawsze
    // przechodziło przez animację zamykania.
    hideOnWindowDeactivate: false

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

    // Chwila rozpoczęcia ostatniego zamykania — kliknięcie ikony w panelu
    // najpierw dezaktywuje dialog (co uruchamia zamykanie), a dopiero potem
    // przełącza stan; bez tej blokady ikona nie umiałaby zamykać menu.
    property double lastClosedAt: 0

    function openMenu() {
        if (Date.now() - lastClosedAt < 300) {
            return
        }
        closeAnimation.stop()
        visible = true
        requestActivate()
        fsContent.reset()
        openAnimation.restart()
    }

    function closeMenu() {
        if (!visible || closeAnimation.running) {
            return
        }
        lastClosedAt = Date.now()
        openAnimation.stop()
        closeAnimation.restart()
    }

    function toggle() {
        if (visible) {
            closeMenu()
        } else {
            openMenu()
        }
    }

    // Jak popup: zniknij (z animacją), gdy użytkownik kliknie gdzie indziej.
    onActiveChanged: {
        if (!active && visible) {
            closeMenu()
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

        // Zawartość omija panele: marginesy z każdej strony to odległość
        // między krawędzią ekranu a obszarem wolnym od paneli.
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

        // Zamykanie: ta sama animacja co otwieranie, odtwarzana w drugą
        // stronę; okno znika dopiero po jej zakończeniu.
        SequentialAnimation {
            id: closeAnimation

            ParallelAnimation {
                NumberAnimation {
                    target: screenItem
                    property: "scale"
                    from: 1.0
                    to: 0.6
                    duration: Kirigami.Units.longDuration
                    easing.type: Easing.InCubic
                }
                NumberAnimation {
                    target: screenItem
                    property: "opacity"
                    from: 1.0
                    to: 0.0
                    duration: Kirigami.Units.longDuration
                    easing.type: Easing.InCubic
                }
            }

            ScriptAction {
                script: dlg.visible = false
            }
        }
    }
}
