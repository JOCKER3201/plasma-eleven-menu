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

    // Wielkość interfejsu z ustawień (bazą jest rozmiar ikony; 32 px =
    // 100%): uiScale skaluje ikony, czcionki, komórki siatek, kafelki
    // kategorii i elementy stopki w całym menu.
    readonly property int appIconSize:
        Math.max(16, Math.min(128, Plasmoid.configuration.iconSize))
    readonly property real uiScale:
        appIconSize / Kirigami.Units.iconSizes.medium
    // Czcionki skalują się ŁAGODNIEJ niż reszta interfejsu (w połowie
    // drogi do pełnej skali): przy interfejsie 200% teksty mają 150%.
    readonly property real fontScale: 1 + (uiScale - 1) / 2

    // Tryb nawigacji klawiaturą: strzałki/Enter w widokach go włączają,
    // ruch myszy nad menu wyłącza. Gdy aktywny, podświetlenie hover pod
    // kursorem gaśnie, a element wybrany strzałkami jest podświetlony
    // IDENTYCZNIE jak hover (jedno podświetlenie naraz).
    property bool keyboardNav: false

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
    // oknami, bez rezerwowania miejsca) i przywracamy przy zamknięciu.
    //
    // KOPIA TRYBÓW ŻYJE W PLIKU NA DYSKU (nie w konfiguracji appletu!):
    // ~/.config/plasma-eleven-menu/panel-backup.json. Konfiguracja
    // appletu odpada jako nośnik, bo plasmashell zrzuca ją na dysk
    // leniwie — przy zamknięciu systemu z otwartym menu tryby paneli
    // zdążały się utrwalić, a kopia nie, i panele zostawały w
    // "windowsgobelow" bez śladu po oryginale. Plik jest zapisywany
    // SYNCHRONICZNIE (sync + atomowe mv) PRZED mutacją paneli, powstaje
    // tylko gdy faktycznie jest co zawieszać, przy starcie plasmashell
    // (= starcie appletu) jest wgrywany z ponawianiem, a po KAŻDYM
    // potwierdzonym przywróceniu — usuwany. Samo istnienie pliku znaczy
    // więc: "panele są zmienione i czekają na przywrócenie".

    // Tryb Game Mode (Bazzite): dostępny tylko, gdy przy starcie appletu
    // istnieje wykonywalny /usr/bin/return-to-gamemode.
    property bool gameModeAvailable: false

    function runGameMode() {
        closeMenu()
        shellExec.connectSource("/usr/bin/return-to-gamemode")
    }

    // Maszyna stanu zawieszania paneli: idle -> reading -> persisting ->
    // applying -> active -> (restore) -> idle. NIEZMIENNIK: żaden panel
    // nie trafia w windowsgobelow, zanim jego oryginalny tryb nie siedzi
    // W PLIKU NA DYSKU, a plik znika dopiero po POTWIERDZONYM
    // przywróceniu.
    property string panelSuspendState: "idle"
    property int panelOpSeq: 0

    // Kopia trybów w pamięci bieżącej sesji (lustro zawartości pliku).
    // Wpis: "idPanelu;screen;location;trybInt" (tryb: 1=autohide,
    // 2=dodgewindows — wartości enum VisibilityMode z panelview.h).
    property var panelBackup: []

    // Dwie instancje appletu (po jednej na monitor) działają w tym samym
    // procesie plasmashell — każda ma WŁASNY plik kopii i własne
    // znaczniki komend, żeby się wzajemnie nie kasowały i żeby silnik
    // "executable" (deduplikuje identyczne komendy) ich nie sklejał.
    readonly property string instanceTag: String(Plasmoid.id)

    function opTag(name) {
        return " #" + name + "@" + instanceTag + ":" + (++panelOpSeq)
    }

    // Ścieżki plików kopii, w formie gotowej do wklejenia w komendę
    // powłoki (rozwijane przez sh dopiero przy wykonaniu).
    readonly property string backupDirSh:
        '"${XDG_CONFIG_HOME:-$HOME/.config}/plasma-eleven-menu"'
    readonly property string backupFileSh:
        backupDirSh.slice(0, -1) + '/panel-backup-' + instanceTag + '.json"'
    // Wspólny plik starszej wersji appletu — czytany i sprzątany
    // migracyjnie przy starcie.
    readonly property string legacyBackupFileSh:
        backupDirSh.slice(0, -1) + '/panel-backup.json"'

    P5Support.DataSource {
        id: shellExec
        engine: "executable"
        connectedSources: []
        onNewData: (sourceName, data) => {
            const ok = (data["exit code"] ?? -1) === 0
            if (sourceName.indexOf("#gamemodecheck") !== -1) {
                root.gameModeAvailable =
                    ok && (data.stdout ?? "").indexOf("GMYES") !== -1
            } else if (sourceName.indexOf("#suspendread") !== -1) {
                root.onSuspendRead(ok, data.stdout ?? "")
            } else if (sourceName.indexOf("#persist") !== -1) {
                root.onPersistDone(ok)
            } else if (sourceName.indexOf("#apply") !== -1) {
                root.onApplyDone(ok)
            } else if (sourceName.indexOf("#restore") !== -1) {
                root.onRestoreDone(ok, data.stdout ?? "")
            } else if (sourceName.indexOf("#bootread") !== -1) {
                root.onBootRead(ok, data.stdout ?? "")
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

    // FAZA 1: wyłącznie ODCZYT trybów paneli tego ekranu — bez mutacji.
    function suspendPanelHiding() {
        if (panelSuspendState !== "idle") {
            return
        }
        if (panelBackup.length > 0) {
            // Zaległa kopia z poprzedniego cyklu — zajmie się nią restore.
            return
        }
        panelSuspendState = "reading"
        // Tryb zapisywany jako INT (1=autohide, 2=dodgewindows), a panel
        // identyfikowany po p.id — to ten sam numer co w grupie
        // [PlasmaViews][Panel <id>] w plasmashellrc, więc kopia pozwala
        // później czytać i pisać tryb WPROST na dysku. Uwaga: panelu już
        // będącego w windowsgobelow ten filtr nie złapie także dlatego,
        // że getter p.hiding w Plasmie 6.7.5 zwraca dla niego "none"
        // (brak case'a w Panel::hiding()).
        const sg = root.screenGeometry
        const js = 'var sx=' + sg.x + '; var sy=' + sg.y + '; var saved=[];'
            + 'for (const p of panels()) {'
            + ' var g = screenGeometry(p.screen);'
            + ' if (g.x==sx && g.y==sy'
            + '     && (p.hiding=="autohide" || p.hiding=="dodgewindows")) {'
            + '  saved.push(String(p.id)+";"+String(p.screen)+";"+p.location'
            + '    +";"+(p.hiding=="dodgewindows" ? "2" : "1"));'
            + ' }'
            + '}'
            + 'print(JSON.stringify(saved));'
        shellExec.connectSource(shellScriptCommand(js) + opTag("suspendread"))
    }

    // FAZA 2: kopia trafia NA DYSK przed jakąkolwiek mutacją — zapis do
    // pliku tymczasowego, sync (trwałość mimo twardego zamknięcia
    // systemu) i atomowe mv. Kopia powstaje tylko, gdy odczyt znalazł
    // panele do zawieszenia, czyli gdy stan paneli ma się różnić od
    // tego, który użytkownik chce mieć po restarcie.
    function onSuspendRead(ok, stdout) {
        if (panelSuspendState !== "reading") {
            return
        }
        let saved = []
        if (ok) {
            const a = stdout.indexOf("[")
            const b = stdout.lastIndexOf("]")
            if (a !== -1 && b > a) {
                try {
                    saved = JSON.parse(stdout.substring(a, b + 1))
                } catch (e) {}
            }
        }
        if (!ok || saved.length === 0) {
            panelSuspendState = "idle"
            return
        }
        if (!fullscreenDialog.visible) {
            // Menu zamknięte zanim odpowiedź dojechała — nic nie mutujemy.
            panelSuspendState = "idle"
            return
        }
        panelBackup = saved
        panelSuspendState = "persisting"
        const base = 'panel-backup-' + instanceTag + '.json'
        shellExec.connectSource(
            'd=' + backupDirSh + ' && mkdir -p "$d"'
            + " && printf '%s' '" + JSON.stringify(Array.from(saved)) + "'"
            + ' > "$d/' + base + '.tmp"'
            + ' && sync "$d/' + base + '.tmp"'
            + ' && mv -f "$d/' + base + '.tmp" "$d/' + base + '"'
            + opTag("persist"))
    }

    function onPersistDone(ok) {
        if (panelSuspendState !== "persisting") {
            return
        }
        if (!ok) {
            // Bez utrwalonej kopii NIE WOLNO mutować paneli (lepiej, żeby
            // panele chowały się pod menu, niż żeby po awarii zostały
            // w windowsgobelow bez śladu po oryginalnych trybach).
            panelBackup = []
            panelSuspendState = "idle"
            return
        }
        if (!fullscreenDialog.visible) {
            // Menu zamknięte w trakcie zapisu — sprzątnij plik, nic nie mutuj.
            shellExec.connectSource('rm -f ' + backupFileSh + opTag("cleanup"))
            panelBackup = []
            panelSuspendState = "idle"
            return
        }
        // FAZA 3: dopiero teraz przełączamy panele na windowsgobelow
        // (tylko w pamięci plasmashella — dysk zaktualizuje jego leniwy
        // zapis; plik kopii już utrwalony, więc każdy scenariusz
        // zamknięcia jest odwracalny).
        panelSuspendState = "applying"
        const js = 'var items=' + JSON.stringify(Array.from(panelBackup)) + ';'
            + 'for (const it of items) {'
            + ' var parts = String(it).split(";");'
            + ' for (const p of panels()) {'
            + '  if (String(p.id)==parts[0]) {'
            + '   p.hiding = "windowsgobelow";'
            + '  }'
            + ' }'
            + '}'
        shellExec.connectSource(shellScriptCommand(js) + opTag("apply"))
    }

    function onApplyDone(ok) {
        if (panelSuspendState !== "applying") {
            return
        }
        panelSuspendState = "active"
        if (!fullscreenDialog.visible) {
            // Menu zamknięte w trakcie przełączania — przywróć od razu.
            restorePanelHiding()
        }
    }

    // Przywracanie z weryfikacją DYSKOWĄ. Trzy kroki w JEDNEJ komendzie:
    // (A) evaluateScript ustawia p.hiding w PAMIĘCI plasmashella (żywy
    //     efekt + jego przyszły leniwy zapis utrwali tę samą wartość),
    // (B) kwriteconfig6 zapisuje panelVisibility WPROST do plasmashellrc
    //     (trwałe od razu — plasmashell zapisuje config dopiero
    //     debouncowanym timerem 10 s, który przy zamykaniu systemu
    //     zwyczajnie nie zdąża; dlatego pamięciowe potwierdzenie było
    //     fałszywe i panele wstawały z brudnego dysku),
    // (C) kreadconfig6 czyta wartości Z POWROTEM — kopia znika DOPIERO,
    //     gdy dysk pokazuje tryby użytkownika.
    // Licznik dopasowań w (A) chroni przed "pustym sukcesem" przy
    // starcie, gdy panele jeszcze nie istnieją. Dawna bramka "stuck"
    // (zliczanie p.hiding=="windowsgobelow") usunięta: getter hiding
    // w Plasmie 6.7.5 nie ma case'a dla windowsgobelow i zwraca "none",
    // więc tamten licznik był tożsamościowo zerowy (martwy strażnik).
    function restorePanelHiding() {
        if (panelSuspendState === "reading"
                || panelSuspendState === "persisting"
                || panelSuspendState === "applying") {
            restoreRetryTimer.restart()
            return
        }
        const backup = panelBackup
        if (!backup || backup.length === 0) {
            panelSuspendState = "idle"
            restoreRetryTimer.stop()
            restoreRetryTimer.attempts = 0
            return
        }
        // Wpisy nowe: "id;screen;location;trybInt"; wpisy starszej wersji
        // (migracja): "screen;location;trybString" — oba obsługiwane.
        const js = 'var items=' + JSON.stringify(Array.from(backup)) + ';'
            + 'var matched=0;'
            + 'for (const it of items) {'
            + ' var q = String(it).split(";");'
            + ' for (const p of panels()) {'
            + '  var hit = (q.length>=4)'
            + '    ? String(p.id)==q[0]'
            + '    : (String(p.screen)==q[0] && p.location==q[1]);'
            + '  if (hit) {'
            + '   p.hiding = (q.length>=4)'
            + '     ? (q[3]=="2" ? "dodgewindows" : "autohide")'
            + '     : q[2];'
            + '   matched++;'
            + '  }'
            + ' }'
            + '}'
            + 'print(matched);'
        let cmd = shellScriptCommand(js) + ' && R=""'
        for (const it of backup) {
            const q = String(it).split(";")
            if (q.length < 4) {
                continue
            }
            cmd += ' && kwriteconfig6 --file plasmashellrc --group PlasmaViews'
                + ' --group "Panel ' + q[0] + '" --key panelVisibility ' + q[3]
                + ' && R="$R;$(kreadconfig6 --file plasmashellrc'
                + ' --group PlasmaViews --group "Panel ' + q[0] + '"'
                + ' --key panelVisibility)"'
        }
        cmd += ' && printf "READBACK%s" "$R"'
        shellExec.connectSource(cmd + opTag("restore"))
        restoreRetryTimer.restart()
    }

    function onRestoreDone(ok, stdout) {
        let confirmed = false
        if (ok) {
            // gdbus pakuje wynik print() w krotkę: ('N\n',).
            const m = stdout.match(/\('([0-9]+)/)
            const matched = m ? parseInt(m[1], 10) : -1
            const idx = stdout.indexOf("READBACK")
            const readback = idx === -1 ? [] : stdout.substring(idx + 8)
                .trim().split(";").filter(s => s.length > 0)
            const expected = []
            for (const it of panelBackup) {
                const q = String(it).split(";")
                if (q.length >= 4) {
                    expected.push(q[3])
                }
            }
            confirmed = matched >= panelBackup.length
                && readback.length === expected.length
                && expected.every((v, i) => readback[i] === v)
        }
        if (confirmed) {
            // DYSK potwierdził tryby użytkownika — dopiero teraz kopia
            // znika (plik instancji + migracyjne nośniki starszej wersji).
            shellExec.connectSource('rm -f ' + backupFileSh + ' '
                + legacyBackupFileSh + opTag("cleanup"))
            Plasmoid.configuration.panelHidingBackup = []
            panelBackup = []
            panelSuspendState = "idle"
            restoreRetryTimer.stop()
            restoreRetryTimer.attempts = 0
        }
        // W przeciwnym razie kopia zostaje — powtarzalny retry ponowi.
    }

    // Powtarzalne ponawianie przywracania (z limitem i watchdogiem na
    // zgubioną odpowiedź read/apply).
    Timer {
        id: restoreRetryTimer
        interval: 500
        repeat: true
        property int attempts: 0
        onTriggered: {
            if (fullscreenDialog.visible) {
                stop()
                attempts = 0
                return
            }
            if (root.panelBackup.length === 0
                    && panelSuspendState === "idle") {
                stop()
                attempts = 0
                return
            }
            attempts++
            if (attempts > 30) {
                stop()
                attempts = 0
                return
            }
            if ((panelSuspendState === "reading"
                    || panelSuspendState === "persisting"
                    || panelSuspendState === "applying") && attempts >= 6) {
                // Odpowiedź read/persist/apply uznana za zgubioną.
                panelSuspendState = "active"
            }
            if (panelSuspendState !== "reading"
                    && panelSuspendState !== "persisting"
                    && panelSuspendState !== "applying") {
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
        onRefreshed: root.applyPowerActions()
    }

    // "gamemode" to nasza własna pozycja (PowerMenu), nie akcja kickera —
    // do modelu systemowego trafiają tylko pozostałe.
    function applyPowerActions() {
        rootModel.systemFavoritesModel.favorites =
            Array.from(Plasmoid.configuration.powerActions)
                .filter(a => a !== "gamemode")
    }

    Connections {
        target: Plasmoid.configuration
        function onPowerActionsChanged() {
            root.applyPowerActions()
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

        // Wykrycie trybu Game Mode (raz, przy uruchomieniu menu).
        shellExec.connectSource(
            "test -x /usr/bin/return-to-gamemode && echo GMYES"
            + opTag("gamemodecheck"))

        // Samonaprawa przy KAŻDYM starcie plasmashell: jeśli na dysku
        // leży plik kopii trybów (restore nie zdążył albo jego zapis
        // przepadł przy zamknięciu systemu), wgraj go — plik zniknie
        // dopiero po dyskowym potwierdzeniu w onRestoreDone. Czytany
        // jest plik TEJ instancji oraz, migracyjnie, wspólny plik
        // starszej wersji appletu.
        shellExec.connectSource('cat ' + backupFileSh
            + ' 2>/dev/null; printf "@@SEP@@"; cat ' + legacyBackupFileSh
            + ' 2>/dev/null; true' + opTag("bootread"))
    }

    function parseBackupArray(text) {
        const a = text.indexOf("[")
        const b = text.lastIndexOf("]")
        if (a === -1 || b <= a) {
            return []
        }
        try {
            const parsed = JSON.parse(text.substring(a, b + 1))
            return Array.isArray(parsed) ? parsed : []
        } catch (e) {
            return []
        }
    }

    function onBootRead(ok, stdout) {
        const parts = (stdout ?? "").split("@@SEP@@")
        let saved = parseBackupArray(parts[0] ?? "")
            .concat(parseBackupArray(parts[1] ?? ""))
        if (saved.length === 0) {
            // Migracja: najstarsza wersja appletu trzymała kopię w configu.
            saved = Array.from(Plasmoid.configuration.panelHidingBackup ?? [])
        }
        if (saved.length === 0 || panelSuspendState !== "idle") {
            return
        }
        panelBackup = saved
        panelSuspendState = "active"
        restorePanelHiding()
    }
}
