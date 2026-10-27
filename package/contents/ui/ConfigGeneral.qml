/*
    SPDX-FileCopyrightText: 2026 Michael Furtak <michaelfurtak@tutanota.com>
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

    // Okno konfiguracji Plasmy wstrzykuje przy otwarciu strony property
    // `title` oraz `cfg_<klucz>` i `cfg_<klucz>Default` dla KAŻDEGO wpisu
    // z config/main.xml. Wszystkie muszą istnieć — brak którejkolwiek
    // przerywa inicjalizację strony (strona nie trafia do sceny, wartości
    // nie są wstrzykiwane, a przycisk Zastosuj zostaje nieaktywny).
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

    // Wszystkie dostępne akcje zasilania w ustalonej kolejności wyświetlania.
    readonly property var allPowerActions: [
        { id: "lock-screen", label: i18n("Zablokuj") },
        { id: "suspend",     label: i18n("Uśpij") },
        { id: "hibernate",   label: i18n("Hibernuj") },
        { id: "shutdown",    label: i18n("Zamknij") },
        { id: "reboot",      label: i18n("Uruchom ponownie") },
        { id: "logout",      label: i18n("Wyloguj") },
        { id: "gamemode",    label: i18n("Tryb Game Mode") }
    ]

    // Tryb Game Mode wymaga /usr/bin/return-to-gamemode — sprawdzane przy
    // otwarciu ustawień; bez niego opcja jest wyszarzona.
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

        // --------------------------- Ikona ---------------------------

        RowLayout {
            Kirigami.FormData.label: i18n("Ikona w panelu:")
            spacing: Kirigami.Units.smallSpacing

            QQC2.Button {
                icon.name: configGeneral.cfg_icon
                text: configGeneral.cfg_icon
                onClicked: iconDialog.open()
            }

            QQC2.ToolButton {
                icon.name: "edit-undo"
                enabled: configGeneral.cfg_icon !== configGeneral.cfg_iconDefault

                QQC2.ToolTip.text: i18n("Przywróć domyślną ikonę")
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

        // -------------------------- Wygląd ---------------------------

        QQC2.CheckBox {
            Kirigami.FormData.label: i18n("Strona główna:")
            text: i18n("Pokazuj sekcję Przypięte")
            checked: configGeneral.cfg_showPinned
            onToggled: configGeneral.cfg_showPinned = checked
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Wielkość ikon:")
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
                text: i18n("%1 px", configGeneral.cfg_iconSize)
            }

            QQC2.ToolButton {
                icon.name: "edit-undo"
                enabled: configGeneral.cfg_iconSize !== 32

                QQC2.ToolTip.text: i18n("Przywróć domyślną wielkość (32 px)")
                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay

                onClicked: configGeneral.cfg_iconSize = 32
            }
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        // ------------------ Pozycja zwykłego menu --------------------

        RowLayout {
            Kirigami.FormData.label: i18n("Przesunięcie w poziomie:")
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

                QQC2.ToolTip.text: i18n("Wyzeruj (środek ekranu)")
                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay

                onClicked: configGeneral.cfg_popupOffsetX = 0
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Przesunięcie w pionie:")
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

                QQC2.ToolTip.text: i18n("Wyzeruj (odstęp od panelu jak panelu od krawędzi ekranu)")
                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay

                onClicked: configGeneral.cfg_popupOffsetY = 0
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Powiększenie menu:")
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

                QQC2.ToolTip.text: i18n("Przywróć rozmiar domyślny")
                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay

                onClicked: configGeneral.cfg_popupSizeIncrease = 0
            }
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        // ---------------------- Menu zasilania -----------------------

        ColumnLayout {
            Kirigami.FormData.label: i18n("Przycisk zasilania:")
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
