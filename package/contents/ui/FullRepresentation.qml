/*
    SPDX-FileCopyrightText: 2026 JOCKER3201 <noreply@users.noreply.github.com>
    SPDX-License-Identifier: MIT
*/

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PC3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami
import org.kde.coreaddons as KCoreAddons
import org.kde.kirigamiaddons.components as KirigamiComponents
import org.kde.kcmutils as KCM

FocusScope {
    id: fullRep

    Layout.preferredWidth: Kirigami.Units.gridUnit * 30
    Layout.preferredHeight: Kirigami.Units.gridUnit * 36
    Layout.minimumWidth: Kirigami.Units.gridUnit * 24
    Layout.minimumHeight: Kirigami.Units.gridUnit * 26

    readonly property bool searching: searchField.text.length > 0

    function reset() {
        searchField.text = ""
        stack.pop(null, QQC2.StackView.Immediate)
        searchField.forceActiveFocus()
        root.keyboardNav = false
    }

    // Go back one view (search → folder → home page).
    // Returns false when there was nothing left to go back from.
    function goBack() {
        if (searching) {
            searchField.text = ""
            searchField.forceActiveFocus()
            return true
        }
        if (stack.depth > 1) {
            stack.pop()
            return true
        }
        return false
    }

    Keys.onEscapePressed: {
        if (!goBack()) {
            root.closeMenu()
        }
    }

    // A shared font multiplier for the WHOLE menu: QtQuick controls
    // (Label, fields, buttons, delegates) inherit the font from the
    // nearest Control-type ancestor, so one scaled pointSize here enlarges
    // text in all views. Elements with their own size binding (headings,
    // result descriptions) scale explicitly.
    QQC2.Control {
        anchors.fill: parent
        font.pointSize: Kirigami.Theme.defaultFont.pointSize * root.fontScale

        // Mouse movement over the menu ends keyboard navigation mode
        // (hover comes back, the arrow-key highlight goes out). The hover
        // handlers are cooperative — they do not steal events from the
        // search field or the tiles.
        // NOTE: after every scene change under the cursor Qt delivers a
        // SYNTHETIC hover event with an unchanged mouse position (merely
        // moving the highlight with the arrow keys would trigger it and
        // the mode would die after one frame) — so the mode is only
        // disabled by an ACTUAL change of the cursor position.
        HoverHandler {
            id: pointerWatch

            property real lastX: -1
            property real lastY: -1

            onPointChanged: {
                if (!hovered) {
                    return
                }
                const p = point.scenePosition
                if (p.x !== pointerWatch.lastX || p.y !== pointerWatch.lastY) {
                    pointerWatch.lastX = p.x
                    pointerWatch.lastY = p.y
                    root.keyboardNav = false
                }
            }
        }

        // Bottom layer (NOT an overlay!): the side mouse buttons go back a
        // view, and a right click on empty background is swallowed. It lies
        // under all content, because a MouseArea always sets the arrow cursor
        // (setCursor in the constructor) — a layer on top would force the
        // arrow over the whole menu and break the text cursor over the search
        // field. Events still get here: no element above accepts these buttons.
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.BackButton | Qt.ForwardButton | Qt.RightButton
            onPressed: mouse => {
                if (mouse.button === Qt.BackButton || mouse.button === Qt.ForwardButton) {
                    fullRep.goBack()
                }
                mouse.accepted = true
            }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: Kirigami.Units.largeSpacing

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Kirigami.Units.gridUnit
                Layout.rightMargin: Kirigami.Units.smallSpacing
                Layout.topMargin: Kirigami.Units.smallSpacing
                spacing: Kirigami.Units.smallSpacing

                PlasmaExtras.SearchField {
                    id: searchField

                    Layout.fillWidth: true

                    placeholderText: i18n("Search for apps, settings, and documents")

                    // Text cursor over the whole pill of the field, not just
                    // over the inner text area itself (the paddings and the
                    // magnifier icon lose it).
                    HoverHandler {
                        cursorShape: Qt.IBeamCursor
                    }

                    onTextChanged: {
                        runnerModel.query = text
                        const current = stack.currentItem
                        if (text.length > 0) {
                            if (!current || current.objectName !== "searchPage") {
                                stack.pop(null, QQC2.StackView.Immediate)
                                stack.push(Qt.resolvedUrl("SearchPage.qml"), {},
                                           QQC2.StackView.Immediate)
                            }
                        } else if (current && current.objectName === "searchPage") {
                            stack.pop(null, QQC2.StackView.Immediate)
                        }
                    }
                    onAccepted: {
                        const current = stack.currentItem
                        if (current && current.activateFirst) {
                            current.activateFirst()
                        }
                    }
                    Keys.onDownPressed: {
                        const current = stack.currentItem
                        if (current && current.focusFirst) {
                            current.focusFirst()
                        }
                    }
                }

                // Full-screen mode toggle — top-right corner, the same one
                // in both modes (popup and full-screen window).
                PC3.ToolButton {
                    id: fullscreenButton

                    icon.name: root.fullscreenMode ? "view-restore" : "view-fullscreen"
                    icon.width: Math.round(Kirigami.Units.iconSizes.smallMedium * root.uiScale)
                    icon.height: Math.round(Kirigami.Units.iconSizes.smallMedium * root.uiScale)
                    display: QQC2.AbstractButton.IconOnly
                    text: root.fullscreenMode
                        ? i18n("Exit full-screen mode")
                        : i18n("Full-screen mode")

                    QQC2.ToolTip.text: text
                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay

                    onClicked: root.setFullscreen(!root.fullscreenMode)
                }
            }

            // The whole menu surface below the search field: the home page,
            // and after clicking a category — a folder filling this area.
            QQC2.StackView {
                id: stack
                Layout.fillWidth: true
                Layout.fillHeight: true
                initialItem: HomePage {}
                clip: true
            }

            Kirigami.Separator {
                Layout.fillWidth: true
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Kirigami.Units.gridUnit
                Layout.rightMargin: Kirigami.Units.gridUnit
                Layout.bottomMargin: Kirigami.Units.smallSpacing
                spacing: Kirigami.Units.largeSpacing

                KCoreAddons.KUser {
                    id: kuser
                }

                // The user as a button: opens System Settings on the
                // Users module (like in Kickoff).
                PC3.ToolButton {
                    id: userButton

                    readonly property string displayName:
                        kuser.fullName.length > 0 ? kuser.fullName : kuser.loginName

                    text: i18n("Open user settings")

                    QQC2.ToolTip.text: text
                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay

                    contentItem: RowLayout {
                        spacing: Kirigami.Units.smallSpacing

                        KirigamiComponents.Avatar {
                            Layout.preferredWidth:
                                Math.round(Kirigami.Units.iconSizes.medium * root.uiScale)
                            Layout.preferredHeight:
                                Math.round(Kirigami.Units.iconSizes.medium * root.uiScale)
                            name: userButton.displayName
                            source: kuser.faceIconUrl
                        }

                        QQC2.Label {
                            text: userButton.displayName
                            elide: Text.ElideRight
                        }
                    }

                    onClicked: {
                        KCM.KCMLauncher.openSystemSettings("kcm_users")
                        root.closeMenu()
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                PC3.ToolButton {
                    id: powerButton

                    icon.name: "system-shutdown"
                    icon.width: Math.round(Kirigami.Units.iconSizes.smallMedium * root.uiScale)
                    icon.height: Math.round(Kirigami.Units.iconSizes.smallMedium * root.uiScale)
                    display: QQC2.AbstractButton.IconOnly
                    text: i18n("Power")

                    QQC2.ToolTip.text: text
                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay

                    onClicked: powerMenu.openRelative()
                }
            }
        }
    }

    // Power menu: kicker's system actions + an optional Game Mode entry
    // (the action set is configurable in the plasmoid settings).
    PowerMenu {
        id: powerMenu
        visualParent: powerButton
    }
}
