# Wild Beginner Starting Kit with Controller Support

I wanted to play WoW with a controller without reaching for a mouse every time I opened an addon. This is the setup I put together for that.

The NightPro menu brings bags, gear upgrades, quests, dungeon loot, bank snapshots and auction settings into one place. Gear, Quests, Dungeons & Loot and saved Auction prices now share a window styled from BagPad, with section cards, readable lists and a detail panel.

This pack is for **World of Warcraft Forever, interface 16001**. It is not a Retail or Classic pack.

## What you get

- **NightPro Bags and Bank** — BagPad's native controller inventory, item actions and saved bank contents.
- **NightPro Gear** — a shared gear page using GearedForever's rankings, with class, specialization, level and equipment filters.
- **NightPro Quests** — a shared quest journal, plus Questie, QuestieDB and Questie Forever Gamepad for maps and controller tracking.
- **NightPro Dungeons & Loot** — a shared browser for NeedRoll's dungeon, boss, loot and quest data.
- **NightPro Auctions and Controls** — saved prices in the shared window, backed by Improved Forever. Visit an auctioneer for its live trading controls.
- **NightPro Inventory** — BagPad's saved character and inventory information.
- **NightPro Nameplates** — an optional shortcut to Platynator. Its editor still has controls that need a pointer.

The NightPro names belong to the pack's interface. The addons behind them still belong to their original authors. Their folder names, settings and licenses stay intact.

## Install on Windows

1. Download the release ZIP and extract it.
2. Exit WoW. Keep Battle.net open.
3. Open PowerShell in the extracted folder and run the command below, using your own WoW path:

```powershell
.\Install.ps1 -AddonPath 'D:\World of Warcraft\_forever_\Interface\AddOns'
```

The installer downloads pinned releases from the original distribution hosts and checks their SHA-256 hashes. Existing addon packages are not replaced. For the supported GearedForever and NeedRoll files, the installer verifies their exact hashes and appends a small data bridge so the shared pages can read their data. It backs up the original files first and refuses unknown versions. An existing NightPro menu gets backed up under `Interface\NightProKitBackups` before it is updated. Your `WTF` folder and saved settings are never copied or changed.

Use `-Preview` to see the plan without installing anything. Use `-SkipDependencies` to install only the NightPro menu, or `-IncludeNameplates` to add Platynator. Copying only the companion folder does not install the two data bridges required by Gear and Dungeons. The installer handles them; `Install-Bridges.ps1` can verify or reapply them separately after an upstream update, provided the file hashes are supported.

4. Launch WoW through Battle.net. Enable the addons at character selection.
5. Open wheel page 3 and select **NightPro Kit** from an empty slot. You can also type `/npmenu`.

The wheel shortcut appears only when that page has a free slot. The kit does not overwrite a filled slot or replace your bindings.

**Bag Settings** opens the layout and controller options. Open your actual inventory from **Bags** on the native wheel; that preserves the game's secure item controls. **Inventory** opens the visual snapshot browser.

## Controller buttons

| Button | NightPro menu and shared pages |
| --- | --- |
| D-pad | Move between the sidebar, filters, list and actions |
| A | Open or select |
| X | Cycle a shared-window filter backward |
| B | Back through dungeon levels, list and sidebar, then close |
| LB / RB | Previous / next page in the shared window |

Bags, quest maps and live auction trading keep their own controller handling and on-screen button prompts. Text entry and some advanced editors still need a keyboard or pointer. This is not a promise that every control in every third-party addon is gamepad accessible.

The navigation adapter releases its button bindings in combat. It does not automate movement, attacks, purchases or item destruction.

Bank and inventory snapshots show what you last visited. They cannot move items remotely. Auction buying and selling still requires an auctioneer.

## Updates and removal

The versions in `dependencies.json` are pinned. An existing addon package is skipped, even if its version differs. The data bridges are applied only to verified supported source files; an unknown source file stops bridge installation. Update those addons through their original pages when you choose to; a newer version may change the interface this pack expects.

To remove the shared menu and theme, disable **NightPro | Wild Beginner Starting Kit** in the AddOns list. The original addons keep working. The appended data bridges only expose data references and are inactive without the companion. Original files are backed up under `Interface\NightProKitBackups\bridges-*`. A previous menu can be restored from `Interface\NightProKitBackups` while WoW is closed.

## Credit where it's due

Most of the heavy lifting already existed. Chris built BagPad's controller bags. markg built Improved Forever and its auction controls. Tombons97 and the Questie Forever Gamepad contributors made the quest interface work with a controller. GearedForever and NeedRoll provide the gear and dungeon information.

I brought these tools together, added the shared NightPro pages, display branding and navigation for supported windows, and packaged the setup for other new players. I did not create the original addons or their databases.

See [CREDITS.md](CREDITS.md) for the authors, source links and licenses. The same core credits are available from the in-game menu.

## Development

The NightPro adapter is GPL-3.0-only. Dependencies are downloaded separately under their own licenses; their code is not mirrored in this repository.

Run `python -m pip install -r tests/requirements.txt`, then `python tests/test_controller.py` and `python tests/test_workbench.py`. On Windows, run `powershell -File tests/Test-Installer.ps1` for the installer checks. These tests cover menu navigation, missing dependencies, combat guards and preservation of existing addon files. They do not replace an in-game check after a client update.

## Stability notes

The shared pages draw eight list rows at a time. They do not repeatedly scan the upstream window tree or open item tooltips while you move focus. Gear ranks only when you open it or change a filter. A page error is caught so B can still close the window, and the last twelve page errors are saved locally in `NightProKitDiagnostics`.

A full game exit was reported during testing of the previous interface. No crash report was available to establish its cause. These changes reduce UI work and avoid the old automatic tooltip path; they do not establish that a native client crash is fixed. Advanced settings, map pages and the live auction transaction window still belong to the upstream addons.
