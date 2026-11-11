/*
    SPDX-FileCopyrightText: 2026 JOCKER3201 <noreply@users.noreply.github.com>
    SPDX-License-Identifier: MIT
*/

import QtQuick
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

// Full-screen mode as a Plasma popup (PlasmaCore.Dialog), not a window:
// a Normal-type dialog covers the whole screen but lives in the regular
// window layer — the Plasma panels (the always-on-top layer) stay visible
// and clickable above it. The content opens and closes with an animation
// from/to the center of the screen and is inset from the edges occupied
// by panels.
PlasmaCore.Dialog {
    id: dlg

    type: PlasmaCore.Dialog.Normal
    backgroundHints: PlasmaCore.Dialog.NoBackground
    location: PlasmaCore.Types.Floating
    flags: Qt.FramelessWindowHint

    // We drive closing ourselves (also after losing focus), so it always
    // goes through the closing animation.
    hideOnWindowDeactivate: false

    x: root.screenGeometry.x
    y: root.screenGeometry.y

    // The moment the last close started — clicking the panel icon first
    // deactivates the dialog (which starts the close) and only then toggles
    // the state; without this guard the icon could not close the menu.
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
        // run before anything reaches the screen.
        screenItem.scale = 0.6
        screenItem.opacity = 0.0
        pendingOpen = true
        visible = true
        requestActivate()
        fsContent.reset()
        firstFrameFallback.restart()
        // Auto-hiding/window-dodging panels on this screen are to stay
        // visible for the whole time the menu is open.
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

    // Like a popup: disappear (with the animation) when the user clicks elsewhere.
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

        // The content avoids the panels: the margin on each side is the
        // distance between the screen edge and the panel-free area.
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

        // Closing: the same animation as opening, played in reverse;
        // the window disappears only once it has finished.
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
