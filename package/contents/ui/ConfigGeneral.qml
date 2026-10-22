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
    property int cfg_popupOffsetX
    property int cfg_popupOffsetY

    property string cfg_iconDefault
    property var cfg_favoritesDefault: []
    property bool cfg_favoritesSeededDefault
    property bool cfg_showPinnedDefault
    property var cfg_powerActionsDefault: []
    property bool cfg_fullscreenDefault
    property int cfg_popupOffsetXDefault
    property int cfg_popupOffsetYDefault

    // Wszystkie dostępne akcje zasilania w ustalonej kolejności wyświetlania.
    readonly property var allPowerActions: [
        { id: "lock-screen", label: i18n("Zablokuj") },
        { id: "suspend",     label: i18n("Uśpij") },
        { id: "hibernate",   label: i18n("Hibernuj") },
        { id: "shutdown",    label: i18n("Zamknij") },
        { id: "reboot",      label: i18n("Uruchom ponownie") },
        { id: "logout",      label: i18n("Wyloguj") }
    ]

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
                    onToggled: configGeneral.togglePowerAction(modelData.id, checked)
                }
            }
        }
    }
}
