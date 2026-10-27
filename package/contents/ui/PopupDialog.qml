/*
    SPDX-FileCopyrightText: 2026 Michael Furtak <michaelfurtak@tutanota.com>
    SPDX-License-Identifier: MIT
*/

import QtQuick
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

// Zwykłe menu-popup — własny dialog plazmowy. Wbudowany popup appletu
// nie istnieje (plasmoid celowo nie ma fullRepresentation — patrz
// main.qml), więc ten dialog jest jedyną "zwykłą" postacią menu.
// Otwiera się i zamyka tą samą animacją co tryb pełnoekranowy
// (skalowanie od/do środka + przenikanie).
PlasmaCore.Dialog {
    id: dlg

    type: PlasmaCore.Dialog.Normal
    backgroundHints: PlasmaCore.Dialog.NoBackground
    location: PlasmaCore.Types.Floating
    flags: Qt.FramelessWindowHint

    // Zamknięciem (też po utracie aktywności) sterujemy sami, żeby zawsze
    // przechodziło przez animację zamykania.
    hideOnWindowDeactivate: false

    // Pozycja jawna (ten sam mechanizm co w FullscreenDialog):
    // poziomo — środek ekranu + przesunięcie z ustawień (popupOffsetX);
    // pionowo — odstęp menu od panelu równy odstępowi panelu od krawędzi
    // ekranu (symetria z pływającym panelem; dla przylegającego panelu
    // odstęp wynosi 0) + przesunięcie z ustawień (popupOffsetY, dodatnie
    // oddala od panelu).
    readonly property bool panelAtTop:
        Plasmoid.location === PlasmaCore.Types.TopEdge

    // Odstęp panelu od krawędzi ekranu, mierzony z geometrii okna panelu.
    readonly property int panelEdgeGap: {
        const sg = root.screenGeometry
        const pw = root.panelWindow
        if (!pw) {
            return Kirigami.Units.largeSpacing
        }
        if (panelAtTop) {
            return Math.max(0, pw.y - sg.y)
        }
        return Math.max(0, (sg.y + sg.height) - (pw.y + pw.height))
    }

    x: root.screenGeometry.x
        + Math.round((root.screenGeometry.width - dlg.width) / 2)
        + Plasmoid.configuration.popupOffsetX

    y: {
        const sg = root.screenGeometry
        const pw = root.panelWindow
        const offset = Plasmoid.configuration.popupOffsetY
        if (panelAtTop) {
            const panelBottom = pw
                ? (pw.y + pw.height)
                : (sg.y + root.localFreeArea.y)
            return panelBottom + panelEdgeGap + offset
        }
        const panelTop = pw
            ? pw.y
            : (sg.y + root.localFreeArea.y + root.localFreeArea.height)
        return panelTop - panelEdgeGap - dlg.height - offset
    }

    // Chwila rozpoczęcia ostatniego zamykania — kliknięcie ikony w panelu
    // najpierw dezaktywuje dialog (co uruchamia zamykanie), a dopiero
    // potem dociera do nas; bez tej blokady ikona nie umiałaby zamykać.
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
        // animacji nie biegnie, zanim cokolwiek trafi na ekran — inaczej
        // animacja "mija" podczas budowy sceny i menu pojawia się skokiem.
        popupRoot.scale = 0.6
        popupRoot.opacity = 0.0
        pendingOpen = true
        visible = true
        requestActivate()
        content.reset()
        firstFrameFallback.restart()
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

    // Jak natywny popup: zniknij (z animacją), gdy użytkownik kliknie
    // gdzie indziej.
    onActiveChanged: {
        if (!active && visible) {
            closeMenu()
        }
    }

    mainItem: Item {
        id: popupRoot

        // Rozmiar bazowy powiększany procentowo z ustawień (0% = domyślny)
        // oraz skalą interfejsu — przy większych elementach i czcionkach
        // rośnie całe okno menu, nie maleje pojemność widoków.
        readonly property real sizeFactor:
            (1 + Plasmoid.configuration.popupSizeIncrease / 100) * root.uiScale

        width: Math.round(Kirigami.Units.gridUnit * 30 * sizeFactor)
        height: Math.round(Kirigami.Units.gridUnit * 36 * sizeFactor)

        transformOrigin: Item.Center

        Rectangle {
            anchors.fill: parent
            radius: Kirigami.Units.cornerRadius
            color: Kirigami.Theme.backgroundColor
            border.width: 1
            border.color: Qt.alpha(Kirigami.Theme.textColor, 0.15)
            Kirigami.Theme.colorSet: Kirigami.Theme.Window
            Kirigami.Theme.inherit: false
        }

        FullRepresentation {
            id: content
            anchors.fill: parent
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
                target: popupRoot
                property: "scale"
                from: 0.6
                to: 1.0
                duration: Kirigami.Units.longDuration
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: popupRoot
                property: "opacity"
                from: 0.0
                to: 1.0
                duration: Kirigami.Units.longDuration
                easing.type: Easing.OutCubic
            }
        }

        // Zamykanie: ta sama animacja odtwarzana w drugą stronę; okno
        // znika dopiero po jej zakończeniu.
        SequentialAnimation {
            id: closeAnimation

            ParallelAnimation {
                NumberAnimation {
                    target: popupRoot
                    property: "scale"
                    from: 1.0
                    to: 0.6
                    duration: Kirigami.Units.longDuration
                    easing.type: Easing.InCubic
                }
                NumberAnimation {
                    target: popupRoot
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
