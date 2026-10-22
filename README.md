# plasma-eleven-menu

Menu aplikacji (plasmoid) dla **KDE Plasma 6** w układzie znanym z menu Start
Windows 11 — ale zasilane prawdziwymi danymi menu KDE.

> **Autorstwo / AI:** kod tego projektu został w całości wygenerowany przez
> **Claude (AI firmy Anthropic)** na zamówienie i pod kierunkiem autora
> repozytorium. Commity z kodem AI są oznaczane w opisie.

## Co robi

- **Przypięte** — sekcja ulubionych aplikacji (baza ulubionych KDE,
  ta sama co w Kickoffie).
- **Menu kontekstowe** — prawy przycisk (lub długie przytrzymanie) na
  aplikacji otwiera standardowe menu launchera KDE z akcjami z backendu
  kicker: Dodaj na pulpit, Przypnij do paska zadań, akcje aplikacji
  (np. Add to Steam), ostatnie dokumenty, Edytuj programy… — plus
  Przypnij/Odepnij od sekcji Przypięte.
- **Wszystko** — siatka kafelków kategorii **dokładnie takich, jak w zwykłym
  menu KDE** (standardowe kategorie XDG z backendu `kicker`, np. Grafika,
  Internet, Multimedia, Narzędzia, System…). Każdy kafelek pokazuje podgląd
  2×2 ikon pierwszych aplikacji.
- **Folder kategorii** — kliknięcie kafelka otwiera folder **wypełniający całą
  powierzchnię menu** (jak w Windows 11), z nagłówkiem i przyciskiem Wstecz.
  Podkategorie otwierają się tak samo, rekurencyjnie.
- **Wyszukiwanie** — pole na górze (aplikacje + ustawienia przez KRunner);
  Enter uruchamia najlepszy wynik.
- **Stopka** — awatar i nazwa użytkownika oraz przycisk zasilania z menu:
  Zablokuj / Uśpij / Zamknij / Uruchom ponownie (zestaw konfigurowalny).
- **Tryb pełnoekranowy** — przycisk w prawym górnym narożniku (w obu
  trybach) przełącza między popupem a **pełnoekranowym dialogiem
  plazmowym**, który otwiera się animacją od środka ekranu. Dialog żyje
  w warstwie zwykłych okien, więc panele Plasmy pozostają widoczne
  i klikalne **nad** menu (nie są przykrywane jak w innych launcherach),
  a zawartość menu ma marginesy wyliczone z geometrii paneli — nic nie
  wpada pod panel. Wybrany tryb jest zapamiętywany; ikona w panelu
  otwiera zawsze aktualnie wybrany wariant.
- **Ustawienia** (prawy przycisk na ikonie → *Konfiguruj…*): ikona panelu,
  widoczność sekcji Przypięte, akcje menu zasilania.
- Nawigacja: `Esc` cofa (czyści wyszukiwanie → zamyka folder → zamyka menu).
  **Oba boczne (kciukowe) przyciski myszy** cofają do poprzedniego widoku;
  nie wywołują w menu żadnych innych akcji.

## Wymagania

- KDE Plasma 6 (tworzone i sprawdzane na 6.7.5),
- `kirigami-addons` (okrągły awatar — na systemach z Plasmą zwykle już jest),
- backend `org.kde.plasma.private.kicker` (część plasma-desktop, zawsze obecny).

## Instalacja

```bash
kpackagetool6 --type Plasma/Applet --install package
# aktualizacja po zmianach:
kpackagetool6 --type Plasma/Applet --upgrade package
# usunięcie:
kpackagetool6 --type Plasma/Applet --remove com.github.jocker3201.elevenmenu
```

Potem: tryb edycji pulpitu → *Dodaj elementy interfejsu* → **plasma-eleven-menu**
(przeciągnij na panel). Można też ustawić jako *Alternatywę* istniejącego
przycisku menu (prawy przycisk na ikonie menu → *Pokaż alternatywy…*).

Po podmianie plików już zainstalowanego plasmoidu trzeba zrestartować
plasmashell: `systemctl --user restart plasma-plasmashell.service`.

## Znane ograniczenia (v0.1)

- Brak sekcji „Ostatnie" (do zrobienia: `showRecentApps`/`showRecentDocs`).
- Nawigacja klawiaturą pełna tylko w wyszukiwarce; siatki obsługiwane myszą.
- Brak przeciągania kafelków (zmiana kolejności Przypiętych).

## Licencja

**MIT** — cały kod w tym repozytorium jest autorski: pisany od zera na
podstawie API modułu (plik `kickerplugin.qmltypes`), bez kodu kopiowanego
z Kickoffa/Kickera; repozytorium nie zawiera i nie dystrybuuje żadnego kodu
KDE. W czasie działania plasmoid importuje moduł QML
`org.kde.plasma.private.kicker` (GPL, część plasma-desktop) — tak jak każdy
plasmoid korzysta z bibliotek Plasmy; licencja MIT jest zgodna z GPL, więc
nie nakłada ograniczeń na plasmashella ładującego ten pakiet.
