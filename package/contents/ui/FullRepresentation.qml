/*
    SPDX-FileCopyrightText: 2026 Michael Furtak <michaelfurtak@tutanota.com>
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
    }

    // Cofnięcie o jeden widok (wyszukiwanie → folder → strona główna).
    // Zwraca false, gdy nie było już czego cofać.
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

    Connections {
        target: root
        function onExpandedChanged() {
            if (root.expanded) {
                fullRep.reset()
            }
        }
    }

    Keys.onEscapePressed: {
        if (!goBack()) {
            root.closeMenu()
        }
    }

    // Spodnia warstwa (NIE nakładka!): boczne przyciski myszy cofają widok,
    // a prawy klik w puste tło jest połykany. Leży pod całą zawartością,
    // bo MouseArea zawsze ustawia kursor strzałki (setCursor w konstruktorze)
    // — warstwa na wierzchu wymuszałaby strzałkę nad całym menu i psuła
    // kursor tekstowy nad polem wyszukiwania. Zdarzenia i tak tu docierają:
    // żaden element wyżej nie akceptuje tych przycisków.
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

                placeholderText: i18n("Wyszukaj aplikacje, ustawienia i dokumenty")

                // Kursor tekstowy nad całą pigułką pola, nie tylko nad samym
                // wewnętrznym obszarem tekstu (paddingi i ikona lupy go gubią).
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

            // Przełącznik trybu pełnoekranowego — prawy górny narożnik,
            // ten sam w obu trybach (popup i okno pełnoekranowe).
            PC3.ToolButton {
                id: fullscreenButton

                icon.name: root.fullscreenMode ? "view-restore" : "view-fullscreen"
                display: QQC2.AbstractButton.IconOnly
                text: root.fullscreenMode
                    ? i18n("Wyłącz tryb pełnoekranowy")
                    : i18n("Tryb pełnoekranowy")

                QQC2.ToolTip.text: text
                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay

                onClicked: root.setFullscreen(!root.fullscreenMode)
            }
        }

        // Cała powierzchnia menu pod polem wyszukiwania: strona główna,
        // a po kliknięciu kategorii — folder wypełniający ten obszar.
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

            // Użytkownik jako przycisk: otwiera Ustawienia systemowe
            // na module Użytkownicy (jak w Kickoffie).
            PC3.ToolButton {
                id: userButton

                readonly property string displayName:
                    kuser.fullName.length > 0 ? kuser.fullName : kuser.loginName

                text: i18n("Otwórz ustawienia użytkowników")

                QQC2.ToolTip.text: text
                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay

                contentItem: RowLayout {
                    spacing: Kirigami.Units.smallSpacing

                    KirigamiComponents.Avatar {
                        Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                        Layout.preferredHeight: Kirigami.Units.iconSizes.medium
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
                display: QQC2.AbstractButton.IconOnly
                text: i18n("Zasilanie")

                QQC2.ToolTip.text: text
                QQC2.ToolTip.visible: hovered
                QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay

                onClicked: powerMenu.openRelative()
            }
        }
    }

    // Menu zasilania zasilane wprost modelem akcji systemowych kickera
    // (zestaw akcji konfigurowalny w ustawieniach plasmoidu).
    PlasmaExtras.ModelContextMenu {
        id: powerMenu
        visualParent: powerButton
        model: rootModel.systemFavoritesModel
        onClicked: m => rootModel.systemFavoritesModel.trigger(m.index, "", null)
    }
}
