/*
    SPDX-FileCopyrightText: 2026 JOCKER3201 <noreply@users.noreply.github.com>
    SPDX-License-Identifier: MIT
*/

import QtQuick
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

// The regular popup menu — our own Plasma dialog. The applet's built-in
// popup does not exist (the plasmoid deliberately has no
// fullRepresentation popup — see main.qml), so this dialog is the menu's
// only "regular" form. It opens and closes with the same animation as the
// full-screen mode (scaling from/to the center + a fade).
PlasmaCore.Dialog {
    id: dlg

    type: PlasmaCore.Dialog.Normal
    backgroundHints: PlasmaCore.Dialog.NoBackground
    location: PlasmaCore.Types.Floating
    flags: Qt.FramelessWindowHint

    // We drive closing ourselves (also after losing focus), so it always
    // goes through the closing animation.
    hideOnWindowDeactivate: false

    // Explicit position (the same mechanism as in FullscreenDialog):
    // horizontally — the center of the screen + the offset from the
    // settings (popupOffsetX); vertically — the menu's gap from the panel
    // equal to the panel's gap from the screen edge (symmetry with a
    // floating panel; for a touching panel the gap is 0) + the offset from
    // the settings (popupOffsetY, positive moves away from the panel).
    readonly property bool panelAtTop:
        Plasmoid.location === PlasmaCore.Types.TopEdge

    // The panel's gap from the screen edge, measured from the panel window geometry.
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

    // The moment the last close started — clicking the panel icon first
    // deactivates the dialog (which starts the close) and only then
    // reaches us; without this guard the icon could not close the menu.
    property double lastClosedAt: 0

    // The open animation waits for the window's first RENDERED frame.
    property bool pendingOpen: false

    function openMenu() {
        if (Date.now() - lastClosedAt < 300) {
            return
        }
        closeAnimation.stop()
        openAnimation.stop()
        // Initial state BEFORE showing: the first frame (a one-time cost on
        // a cold start) renders invisibly, and the animation clock does not
        // run before anything reaches the screen — otherwise the animation
        // "passes by" while the scene is built and the menu pops in abruptly.
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

    // Like a native popup: disappear (with the animation) when the user
    // clicks elsewhere.
    onActiveChanged: {
        if (!active && visible) {
            closeMenu()
        }
    }

    mainItem: Item {
        id: popupRoot

        // The base size is enlarged by the percentage from the settings
        // (0% = default) and by the interface scale — with bigger elements
        // and fonts the whole menu window grows, instead of the views
        // losing capacity.
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

        // Start the animation on the first shown frame; the Timer is a
        // safety net in case the frame never arrives (the menu never gets stuck).
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

        // Closing: the same animation played in reverse; the window
        // disappears only once it has finished.
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
