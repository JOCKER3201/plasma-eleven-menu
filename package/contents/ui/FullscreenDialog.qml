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

    // Chwila rozpoczęcia ostatniego zamykania — kliknięcie ikony w panelu
    // najpierw dezaktywuje dialog (co uruchamia zamykanie), a dopiero potem
    // przełącza stan; bez tej blokady ikona nie umiałaby zamykać menu.
    property double lastClosedAt: 0

    // Animacja otwarcia czeka na pierwszą WYRENDEROWANĄ klatkę okna.
    property bool pendingOpen: false

    function openMenu() {
        if (Date.now() - lastClosedAt < 300) {
            return
        }
        closeAnimation.stop()
        openAnimation.stop()
        // Stan początkowy PRZED pokazaniem: pierwsza (jednorazowo kosztowna
        // przy zimnym starcie) klatka renderuje się niewidocznie, a zegar
        // animacji nie biegnie, zanim cokolwiek trafi na ekran.
        screenItem.scale = 0.6
        screenItem.opacity = 0.0
        pendingOpen = true
        visible = true
        requestActivate()
        fsContent.reset()
        firstFrameFallback.restart()
        // Panele z autoukrywaniem/unikaniem okien na tym ekranie mają
        // zostać widoczne przez cały czas otwarcia menu.
        root.suspendPanelHiding()
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
                + Math.max(0, root.localFreeArea.x)
            anchors.topMargin: Kirigami.Units.gridUnit
                + Math.max(0, root.localFreeArea.y)
            anchors.rightMargin: Kirigami.Units.gridUnit + Math.max(0,
                root.screenGeometry.width
                - root.localFreeArea.x - root.localFreeArea.width)
            anchors.bottomMargin: Kirigami.Units.gridUnit + Math.max(0,
                root.screenGeometry.height
                - root.localFreeArea.y - root.localFreeArea.height)

            focus: true
        }

        // Start animacji od pierwszej pokazanej klatki; Timer to bezpiecznik
        // na wypadek, gdyby klatka nie nadeszła (menu nigdy nie utknie).
        Connections {
            target: dlg
            ignoreUnknownSignals: true
            function onFrameSwapped() {
                if (dlg.pendingOpen) {
                    dlg.pendingOpen = false
                    firstFrameFallback.stop()
                    openAnimation.restart()
                }
            }
        }

        Timer {
            id: firstFrameFallback
            interval: 100
            repeat: false
            onTriggered: {
                if (dlg.pendingOpen) {
                    dlg.pendingOpen = false
                    openAnimation.restart()
                }
            }
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
                script: {
                    dlg.visible = false
                    root.restorePanelHiding()
                }
            }
        }
    }
}
