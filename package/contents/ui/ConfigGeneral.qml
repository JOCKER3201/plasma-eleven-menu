/*
    SPDX-FileCopyrightText: 2026 JOCKER3201 <noreply@users.noreply.github.com>
    SPDX-License-Identifier: MIT
*/

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami
import org.kde.iconthemes as KIconThemes
import org.kde.plasma.plasma5support as P5Support

KCM.SimpleKCM {
    id: configGeneral

    // When the page opens, the Plasma configuration window injects the
    // `title` property and `cfg_<key>` plus `cfg_<key>Default` for EVERY
    // entry in config/main.xml. All of them must exist — a single missing
    // one aborts the page initialization (the page never reaches the
    // scene, the values are not injected, and the Apply button stays
    // disabled).
    property string cfg_icon
    property var cfg_favorites: []
    property bool cfg_favoritesSeeded
    property bool cfg_showPinned
    property var cfg_powerActions: []
    property bool cfg_fullscreen
    property int cfg_iconSize
    property int cfg_popupOffsetX
    property int cfg_popupOffsetY
    property int cfg_popupSizeIncrease
    property var cfg_panelHidingBackup: []

    property string cfg_iconDefault
    property var cfg_favoritesDefault: []
    property bool cfg_favoritesSeededDefault
    property bool cfg_showPinnedDefault
    property var cfg_powerActionsDefault: []
    property bool cfg_fullscreenDefault
    property int cfg_iconSizeDefault
    property int cfg_popupOffsetXDefault
    property int cfg_popupOffsetYDefault
    property int cfg_popupSizeIncreaseDefault
    property var cfg_panelHidingBackupDefault: []

    // All available power actions, in a fixed display order.
    readonly property var allPowerActions: [
        { id: "lock-screen", label: i18n("Lock") },
        { id: "suspend",     label: i18n("Sleep") },
        { id: "hibernate",   label: i18n("Hibernate") },
        { id: "shutdown",    label: i18n("Shut Down") },
        { id: "reboot",      label: i18n("Restart") },
        { id: "logout",      label: i18n("Log Out") },
        { id: "gamemode",    label: i18n("Game Mode") }
    ]

    // Game Mode requires /usr/bin/return-to-gamemode — checked when the
    // settings open; without it the option is grayed out.
    property bool gameModeAvailable: false

    P5Support.DataSource {
        id: gameModeCheck
        engine: "executable"
        connectedSources: []
        onNewData: (sourceName, data) => {
            configGeneral.gameModeAvailable =
                (data.stdout ?? "").indexOf("GMYES") !== -1
            disconnectSource(sourceName)
        }
    }

    Component.onCompleted: gameModeCheck.connectSource(
        "test -x /usr/bin/return-to-gamemode && echo GMYES")

    function togglePowerAction(id, enabled) {
        const set = new Set(cfg_powerActions)
        if (enabled) {
            set.add(id)
        } else {
            set.delete(id)
        }
        cfg_powerActions = allPowerActions
            .map(action => action.id)
            .filter(actionId => set.has(actionId))
    }

    Kirigami.FormLayout {

        // ---------------------------- Icon ----------------------------

        RowLayout {
            Kirigami.FormData.label: i18n("Panel icon:")
            spacing: Kirigami.Units.smallSpacing

            QQC2.Button {
                icon.name: configGeneral.cfg_icon
                text: configGeneral.cfg_icon
                onClicked: iconDialog.open()
            }

            QQC2.ToolButton {
                icon.name: "edit-undo"
                enabled: configGeneral.cfg_icon !== configGeneral.cfg_iconDefault

                QQC2.ToolTip.text: i18n("Reset to default icon")
                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay

                onClicked: configGeneral.cfg_icon = configGeneral.cfg_iconDefault
            }
        }

        KIconThemes.IconDialog {
            id: iconDialog
            onIconNameChanged: {
                if (iconName.length > 0) {
                    configGeneral.cfg_icon = iconName
                }
            }
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        // ------------------------- Appearance -------------------------

        QQC2.CheckBox {
            Kirigami.FormData.label: i18n("Home page:")
            text: i18n("Show the Pinned section")
            checked: configGeneral.cfg_showPinned
            onToggled: configGeneral.cfg_showPinned = checked
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Interface size:")
            spacing: Kirigami.Units.smallSpacing

            QQC2.Slider {
                Layout.preferredWidth: Kirigami.Units.gridUnit * 12
                from: 16
                to: 64
                stepSize: 2
                value: configGeneral.cfg_iconSize
                onMoved: configGeneral.cfg_iconSize = Math.round(value)
            }

            QQC2.Label {
                Layout.preferredWidth: Kirigami.Units.gridUnit * 3.5
                horizontalAlignment: Text.AlignRight
                text: i18n("%1%", Math.round(configGeneral.cfg_iconSize / 32 * 100))
            }

            QQC2.ToolButton {
                icon.name: "edit-undo"
                enabled: configGeneral.cfg_iconSize !== 32

                QQC2.ToolTip.text: i18n("Reset to default size (100%)")
                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay

                onClicked: configGeneral.cfg_iconSize = 32
            }
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        // ------------------ Regular menu position ---------------------

        RowLayout {
            Kirigami.FormData.label: i18n("Horizontal offset:")
            spacing: Kirigami.Units.smallSpacing

            QQC2.Slider {
                id: offsetXSlider
                Layout.preferredWidth: Kirigami.Units.gridUnit * 12
                from: -1920
                to: 1920
                stepSize: 1
                value: configGeneral.cfg_popupOffsetX
                onMoved: configGeneral.cfg_popupOffsetX = Math.round(value)
            }

            QQC2.Label {
                Layout.preferredWidth: Kirigami.Units.gridUnit * 3.5
                horizontalAlignment: Text.AlignRight
                text: i18n("%1 px", configGeneral.cfg_popupOffsetX)
            }

            QQC2.ToolButton {
                icon.name: "edit-undo"
                enabled: configGeneral.cfg_popupOffsetX !== 0

                QQC2.ToolTip.text: i18n("Reset to zero (center of the screen)")
                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay

                onClicked: configGeneral.cfg_popupOffsetX = 0
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Vertical offset:")
            spacing: Kirigami.Units.smallSpacing

            QQC2.Slider {
                id: offsetYSlider
                Layout.preferredWidth: Kirigami.Units.gridUnit * 12
                from: 0
                to: 1080
                stepSize: 1
                value: configGeneral.cfg_popupOffsetY
                onMoved: configGeneral.cfg_popupOffsetY = Math.round(value)
            }

            QQC2.Label {
                Layout.preferredWidth: Kirigami.Units.gridUnit * 3.5
                horizontalAlignment: Text.AlignRight
                text: i18n("%1 px", configGeneral.cfg_popupOffsetY)
            }

            QQC2.ToolButton {
                icon.name: "edit-undo"
                enabled: configGeneral.cfg_popupOffsetY !== 0

                QQC2.ToolTip.text: i18n("Reset to zero (menu-to-panel gap equal to the panel's gap from the screen edge)")
                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay

                onClicked: configGeneral.cfg_popupOffsetY = 0
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Menu size increase:")
            spacing: Kirigami.Units.smallSpacing

            QQC2.Slider {
                Layout.preferredWidth: Kirigami.Units.gridUnit * 12
                from: 0
                to: 100
                stepSize: 1
                value: configGeneral.cfg_popupSizeIncrease
                onMoved: configGeneral.cfg_popupSizeIncrease = Math.round(value)
            }

            QQC2.Label {
                Layout.preferredWidth: Kirigami.Units.gridUnit * 3.5
                horizontalAlignment: Text.AlignRight
                text: i18n("+%1%", configGeneral.cfg_popupSizeIncrease)
            }

            QQC2.ToolButton {
                icon.name: "edit-undo"
                enabled: configGeneral.cfg_popupSizeIncrease !== 0

                QQC2.ToolTip.text: i18n("Reset to default size")
                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay

                onClicked: configGeneral.cfg_popupSizeIncrease = 0
            }
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        // -------------------------- Power menu ------------------------

        ColumnLayout {
            Kirigami.FormData.label: i18n("Power button:")
            spacing: Kirigami.Units.smallSpacing

            Repeater {
                model: configGeneral.allPowerActions

                QQC2.CheckBox {
                    required property var modelData

                    text: modelData.label
                    checked: configGeneral.cfg_powerActions.indexOf(modelData.id) !== -1
                    enabled: modelData.id !== "gamemode"
                        || configGeneral.gameModeAvailable
                    onToggled: configGeneral.togglePowerAction(modelData.id, checked)
                }
            }
        }
    }
}
