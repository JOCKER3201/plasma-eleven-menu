/*
    plasma-eleven-menu — menu aplikacji dla Plasmy 6 w układzie znanym z Windows 11.

    SPDX-FileCopyrightText: 2026 Michael Furtak <michaelfurtak@tutanota.com>
    SPDX-License-Identifier: MIT

    Kod wygenerowany przez Claude (AI firmy Anthropic) na zamówienie autora projektu.
*/

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import org.kde.plasma.private.kicker as Kicker
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    Plasmoid.icon: Plasmoid.configuration.icon

    toolTipMainText: i18n("plasma-eleven-menu")
    toolTipSubText: i18n("Uruchamiaj aplikacje")

    hideOnWindowDeactivate: true

    // Tryb pełnoekranowy: plazmowy dialog na cały ekran (pod panelami).
    readonly property bool fullscreenMode:
        Plasmoid.configuration.fullscreen === true

    // Wielkość ikon aplikacji z ustawień; iconScale skaluje za nią
    // komórki siatek i kafelki kategorii (foldery ikon).
    readonly property int appIconSize:
        Math.max(16, Math.min(128, Plasmoid.configuration.iconSize))
    readonly property real iconScale:
        appIconSize / Kirigami.Units.iconSizes.medium

    // Wzorzec jak w Application Dashboard (kickerdash, zweryfikowany
    // w źródłach Plasmy 6.7.5): IKONA w panelu jest fullRepresentation
    // renderowaną inline (preferred == full, bez switchWidth/Height applet
    // nigdy nie przechodzi w tryb collapsed), więc wbudowany popup/expander
    // fizycznie nie może powstać i niczego nie dubluje. Oba widoki menu —
    // popup i pełny ekran — są własnymi dialogami, sterowanymi wyłącznie
    // przez toggle() (klik ikony i Plasmoid.onActivated, czyli Super).
    preferredRepresentation: fullRepresentation

    // "activated" (Super/skrót launchera) nie ma ruszać "expanded".
    activationTogglesExpanded: false

    // Aktualnie wybrany widok menu.
    readonly property var activeDialog:
        fullscreenMode ? fullscreenDialog : popupDialog

    // Obszar wolny od paneli, ZNORMALIZOWANY do układu lokalnego ekranu
    // (0,0 = lewy górny róg ekranu appletu). availableScreenRect bywa
    // raportowane lokalnie (na monitorach przesuniętych w układzie
    // globalnym) albo globalnie — sprowadzamy oba warianty do jednego.
    // Pusty prostokąt => cały ekran. Wspólne dla obu dialogów.
    readonly property rect localFreeArea: {
        const sg = root.screenGeometry
        const ar = root.availableScreenRect
        if (!ar || ar.width <= 0 || ar.height <= 0) {
            return Qt.rect(0, 0, sg.width, sg.height)
        }
        if (ar.x >= sg.x && ar.y >= sg.y
                && ar.x + ar.width <= sg.x + sg.width + 1
                && ar.y + ar.height <= sg.y + sg.height + 1) {
            return Qt.rect(ar.x - sg.x, ar.y - sg.y, ar.width, ar.height)
        }
        return Qt.rect(
            Math.max(0, ar.x),
            Math.max(0, ar.y),
            Math.min(ar.width, sg.width),
            Math.min(ar.height, sg.height))
    }

    // Klawisz Super / globalny skrót appletu.
    Connections {
        target: Plasmoid
        function onActivated() {
            root.activeDialog.toggle()
        }
    }

    // Panele z autoukrywaniem wysuwają się na czas otwartego menu.
    // Celowo NeedsAttentionStatus, NIE AcceptingInputStatus: ten drugi
    // każe panelowi przejąć focus klawiatury i wymusić aktywację
    // pierwszego elementu panelu (PanelView::refreshStatus), przez co
    // najechanie na inny aplet w trakcie otwierania aktywowało go
    // zamiast menu. NeedsAttention tylko pokazuje panel (bez focusu),
    // a PanelView::restoreAutoHide nie chowa go, dopóki status >= NeedsAttention.
    Plasmoid.status: fullscreenDialog.visible || popupDialog.visible
        ? PlasmaCore.Types.NeedsAttentionStatus
        : PlasmaCore.Types.ActiveStatus

    function closeMenu() {
        popupDialog.closeMenu()
        fullscreenDialog.closeMenu()
    }

    // --- Zawieszanie ukrywania paneli na czas menu pełnoekranowego ---
    // Status appletu trzyma widoczny tylko panel-gospodarza; pozostałe
    // panele ekranu (autoukrywanie / unikanie okien) przełączamy przez
    // interfejs skryptowy plasmashell na "windowsgobelow" (widoczne nad
    // oknami, bez rezerwowania miejsca) i przywracamy przy zamknięciu. Kopia trybów trafia do konfiguracji appletu, więc po
    // ewentualnej awarii stan naprawia się przy następnym starcie.

    P5Support.DataSource {
        id: shellExec
        engine: "executable"
        connectedSources: []
        onNewData: (sourceName, data) => {
            if (sourceName.indexOf("#suspend") !== -1) {
                const out = data.stdout ?? ""
                const a = out.indexOf("[")
                const b = out.lastIndexOf("]")
                if (a !== -1 && b > a) {
                    try {
                        const saved = JSON.parse(out.substring(a, b + 1))
                        if (saved.length > 0) {
                            Plasmoid.configuration.panelHidingBackup = saved
                        }
                    } catch (e) {}
                }
            }
            disconnectSource(sourceName)
        }
    }

    function shellScriptCommand(js) {
        return 'gdbus call --session --dest org.kde.plasmashell'
            + ' --object-path /PlasmaShell'
            + ' --method org.kde.PlasmaShell.evaluateScript "'
            + js.replace(/"/g, '\\"') + '"'
    }

    function suspendPanelHiding() {
        if (Plasmoid.configuration.panelHidingBackup.length > 0) {
            return
        }
        const sg = root.screenGeometry
        const js = 'var sx=' + sg.x + '; var sy=' + sg.y + '; var saved=[];'
            + 'for (const p of panels()) {'
            + ' var g = screenGeometry(p.screen);'
            + ' if (g.x==sx && g.y==sy'
            + '     && (p.hiding=="autohide" || p.hiding=="dodgewindows")) {'
            + '  saved.push(String(p.screen)+";"+p.location+";"+p.hiding);'
            + '  p.hiding="windowsgobelow";'
            + ' }'
            + '}'
            + 'print(JSON.stringify(saved));'
        shellExec.connectSource(shellScriptCommand(js) + " #suspend")
    }

    function restorePanelHiding() {
        const backup = Plasmoid.configuration.panelHidingBackup
        if (!backup || backup.length === 0) {
            // Kopia mogła jeszcze nie dojechać (zapisuje ją asynchroniczna
            // odpowiedź gdbus po otwarciu) — spróbuj ponownie za chwilę.
            restoreRetryTimer.start()
            return
        }
        // Panel z kopii to NASZ wpis — przywracamy bezwarunkowo,
        // niezależnie od trybu, w którym aktualnie wisi.
        const js = 'var items=' + JSON.stringify(Array.from(backup)) + ';'
            + 'for (const it of items) {'
            + ' var parts = String(it).split(";");'
            + ' for (const p of panels()) {'
            + '  if (String(p.screen)==parts[0] && p.location==parts[1]) {'
            + '   p.hiding = parts[2];'
            + '  }'
            + ' }'
            + '}'
        shellExec.connectSource(shellScriptCommand(js) + " #restore")
        Plasmoid.configuration.panelHidingBackup = []
    }

    // Jedno ponowienie przywracania, gdy kopia trybów była jeszcze w drodze.
    Timer {
        id: restoreRetryTimer
        interval: 600
        repeat: false
        onTriggered: {
            if (!fullscreenDialog.visible
                    && Plasmoid.configuration.panelHidingBackup.length > 0) {
                restorePanelHiding()
            }
        }
    }

    function setFullscreen(on) {
        if (on) {
            popupDialog.closeMenu()
        } else {
            fullscreenDialog.closeMenu()
        }
        Plasmoid.configuration.fullscreen = on
        activeDialog.openMenu()
    }

    // Okno panelu, w którym siedzi ikona — do wyliczania odstępu
    // pływającego panelu od krawędzi ekranu (PopupDialog).
    readonly property var panelWindow:
        fullRepresentationItem ? fullRepresentationItem.panelWindow : null

    fullRepresentation: MouseArea {
        id: iconRoot

        Layout.minimumWidth: -1
        Layout.minimumHeight: -1
        Layout.maximumWidth: Kirigami.Units.iconSizes.huge
        Layout.maximumHeight: Kirigami.Units.iconSizes.huge

        readonly property var panelWindow: Window.window

        hoverEnabled: true
        onClicked: root.activeDialog.toggle()

        Kirigami.Icon {
            anchors.fill: parent
            source: Plasmoid.icon
            active: iconRoot.containsMouse
        }
    }

    FullscreenDialog {
        id: fullscreenDialog
    }

    PopupDialog {
        id: popupDialog
    }

    // Główne źródło danych menu: kategorie aplikacji dokładnie takie,
    // jakich używają Kickoff i Kicker (standardowe kategorie XDG).
    Kicker.RootModel {
        id: rootModel

        autoPopulate: false
        appNameFormat: 0
        flat: false
        sorted: true
        showSeparators: false
        showTopLevelItems: false
        appletInterface: root

        showAllApps: false
        showAllAppsCategorized: false
        showRecentApps: false
        showRecentDocs: false
        showRecentFolders: false
        showPowerSession: false
        showFavoritesPlaceholder: false
        showRootSeparator: false
        highlightNewlyInstalledApps: false

        // systemFavoritesModel jest gotowy dopiero po refresh(), dlatego
        // listę akcji zasilania ustawiamy na sygnał refreshed (idempotentnie).
        onRefreshed: {
            systemFavoritesModel.favorites = Plasmoid.configuration.powerActions
        }
    }

    Connections {
        target: Plasmoid.configuration
        function onPowerActionsChanged() {
            rootModel.systemFavoritesModel.favorites =
                Plasmoid.configuration.powerActions
        }
    }

    // Wyszukiwarka (KRunner): aplikacje + ustawienia systemowe.
    Kicker.RunnerModel {
        id: runnerModel

        appletInterface: root
        favoritesModel: rootModel.favoritesModel
        runners: ["krunner_services", "krunner_systemsettings"]
        mergeResults: true
    }

    Component.onCompleted: {
        rootModel.favoritesModel.initForClient(
            "org.kde.plasma.elevenmenu.favorites.instance-" + Plasmoid.id)

        if (!Plasmoid.configuration.favoritesSeeded) {
            rootModel.favoritesModel.favorites = Plasmoid.configuration.favorites
            Plasmoid.configuration.favoritesSeeded = true
        }

        rootModel.refresh()

        // Samonaprawa: jeśli po awarii zostały zawieszone tryby ukrywania
        // paneli, przywróć je przy starcie.
        if (Plasmoid.configuration.panelHidingBackup.length > 0) {
            restorePanelHiding()
        }
    }
}
