# plasma-eleven-menu

An application menu (plasmoid) for **KDE Plasma 6** with the layout known from
the Windows 11 Start menu — but powered by real KDE menu data.

> **Authorship / AI:** the code in this project was generated entirely by
> **Claude (an AI by Anthropic)**, commissioned and directed by the repository
> author. Commits containing AI code are marked in their descriptions.

## What it does

- **Pinned** — a favorites section (the KDE favorites database,
  the same one Kickoff uses).
- **Context menu** — right click (or long press) on an application opens the
  standard KDE launcher menu with actions from the kicker backend:
  Add to Desktop, Pin to Task Manager, application actions
  (e.g. Add to Steam), recent documents, Edit Applications… — plus
  Pin to/Unpin from the Pinned section.
- **All** — a grid of category tiles **exactly as in the regular KDE menu**
  (standard XDG categories from the `kicker` backend, e.g. Graphics,
  Internet, Multimedia, Utilities, System…). Each tile shows a 2×2 icon
  preview of the first few applications.
- **Category folder** — clicking a tile opens a folder **filling the whole
  menu surface** (like in Windows 11), with a header and a Back button.
  Subcategories open the same way, recursively.
- **Search** — a field at the top (applications + settings via KRunner);
  Enter launches the best match.
- **Footer** — the user's avatar and name, and a power button with a menu:
  Lock / Sleep / Shut Down / Restart (the set is configurable).
- **Full-screen mode** — a button in the top-right corner (in both modes)
  switches between the popup and a **full-screen Plasma dialog**, opened
  and closed with a mirrored animation from/to the center of the screen.
  The dialog lives in the regular window layer, so Plasma panels stay
  visible and clickable **above** the menu (they are not covered as in
  other launchers), auto-hiding panels slide out while the menu is open,
  and the menu content gets margins computed from the panel geometry —
  nothing ends up underneath a panel. The chosen mode is remembered; the
  panel icon and the Super key always open exactly one, currently
  selected variant.
- **Settings** (right click on the icon → *Configure…*): panel icon,
  visibility of the Pinned section, power menu actions.
- Navigation: `Esc` goes back (clears the search → closes the folder →
  closes the menu). **Both side (thumb) mouse buttons** go back to the
  previous view; they trigger no other actions inside the menu.

## Requirements

- KDE Plasma 6 (developed and tested on 6.7.5),
- `kirigami-addons` (round avatar — usually already present on systems
  with Plasma),
- the `org.kde.plasma.private.kicker` backend (part of plasma-desktop,
  always present).

## Installation

```bash
git clone https://github.com/JOCKER3201/plasma-eleven-menu.git
cd plasma-eleven-menu

make install        # install/update for the current user
sudo make install   # global (system-wide) install/update
make uninstall      # removal (sudo make uninstall — for the global version)
make package        # plasma-eleven-menu-<version>.tar.xz archive
```

Manually, without make:

```bash
kpackagetool6 --type Plasma/Applet --install package
# update after changes:
kpackagetool6 --type Plasma/Applet --upgrade package
# removal:
kpackagetool6 --type Plasma/Applet --remove com.github.jocker3201.elevenmenu
```

Then: desktop edit mode → *Add Widgets* → **plasma-eleven-menu**
(drag onto the panel). It can also be set as an *Alternative* of an
existing menu button (right click on the menu icon → *Show Alternatives…*).

After replacing the files of an already installed plasmoid, plasmashell
must be restarted: `systemctl --user restart plasma-plasmashell.service`.

## Known limitations (v0.1)

- No "Recent" section (to do: `showRecentApps`/`showRecentDocs`).
- Full keyboard navigation only in the search view; grids are mouse-driven.
- No tile drag-and-drop (reordering of Pinned).

## License

**MIT** — all code in this repository is original: written from scratch
against the module API (the `kickerplugin.qmltypes` file), with no code
copied from Kickoff/Kicker; the repository does not contain or distribute
any KDE code. At runtime the plasmoid imports the QML module
`org.kde.plasma.private.kicker` (GPL, part of plasma-desktop) — just like
any plasmoid uses the Plasma libraries; the MIT license is GPL-compatible,
so it places no restrictions on plasmashell loading this package.
