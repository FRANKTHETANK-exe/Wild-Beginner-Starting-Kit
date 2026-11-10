# Wild Beginner Starting Kit with Controller Support

I wanted to play WoW with a controller without reaching for a mouse every time I opened an addon. This is the setup I put together for that.

The NightPro menu brings bags, gear upgrades, quests, dungeon loot, bank snapshots and auction settings into one place. It uses a dark-and-gold style to match the bag interface, with a short explanation beside each tool.

This pack is for **World of Warcraft Forever, interface 16001**. It is not a Retail or Classic pack.

## What you get

- **NightPro Bags and Bank** — BagPad's native controller inventory, item actions and saved bank contents.
- **NightPro Gear** — GearedForever's gear browser, with controller navigation added by the menu adapter.
- **NightPro Quests** — Questie, QuestieDB and Questie Forever Gamepad for quest maps and controller tracking.
- **NightPro Dungeons & Loot** — NeedRoll's dungeon, loot and quest browser, with controller navigation.
- **NightPro Auctions and Controls** — Improved Forever and its Auction module. Visit an auctioneer to buy and sell.
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

The installer downloads pinned releases from the original distribution hosts and checks their SHA-256 hashes. Existing addon folders are left alone. An existing NightPro menu gets backed up under `Interface\NightProKitBackups` before it is updated. Your `WTF` folder and saved settings are never copied or changed.

Use `-Preview` to see the plan without installing anything. Use `-SkipDependencies` to install only the NightPro menu, or `-IncludeNameplates` to add Platynator. If Windows blocks the script, you can copy `AddOns\NightProController` manually and install the dependencies from [the linked releases](DEPENDENCIES.md).

4. Launch WoW through Battle.net. Enable the addons at character selection.
5. Open wheel page 3 and select **NightPro Kit** from an empty slot. You can also type `/npmenu`.

The wheel shortcut appears only when that page has a free slot. The kit does not overwrite a filled slot or replace your bindings.

**Bag Settings** opens the layout and controller options. Open your actual inventory from **Bags** on the native wheel; that preserves the game's secure item controls. **Inventory** opens the visual snapshot browser.

## Controller buttons

| Button | NightPro menu, Gear and Dungeons |
| --- | --- |
| D-pad | Move between buttons |
| A | Open or select |
| X | Alternate click where the tool supports it |
| B | Close the current supported window |
| LB / RB | Scroll the focused list |

Bags, quests and auctions keep their own controller handling and on-screen button prompts. Text entry and some advanced editors still need a keyboard or pointer. This is not a promise that every control in every third-party addon is gamepad accessible.

The navigation adapter releases its button bindings in combat. It does not automate movement, attacks, purchases or item destruction.

Bank and inventory snapshots show what you last visited. They cannot move items remotely. Auction buying and selling still requires an auctioneer.

## Updates and removal

The versions in `dependencies.json` are pinned. An existing addon is skipped, even if its version differs. Update those addons through their original pages when you choose to; a newer version may change the interface this pack expects.

To remove the shared menu and theme, disable **NightPro | Wild Beginner Starting Kit** in the AddOns list. The original addons keep working. A previous menu can be restored from `Interface\NightProKitBackups` while WoW is closed.

## Credit where it's due

Most of the heavy lifting already existed. Chris built BagPad's controller bags. markg built Improved Forever and its auction controls. Tombons97 and the Questie Forever Gamepad contributors made the quest interface work with a controller. GearedForever and NeedRoll provide the gear and dungeon information.

I brought these tools together, added the shared NightPro menu, display branding and navigation for supported windows, and packaged the setup for other new players. I did not create the original addons or their databases.

See [CREDITS.md](CREDITS.md) for the authors, source links and licenses. The same core credits are available from the in-game menu.

## Development

The NightPro adapter is GPL-3.0-only. Dependencies are downloaded separately under their own licenses; their code is not mirrored in this repository.

Run `python -m pip install -r tests/requirements.txt`, then `python tests/test_controller.py`. On Windows, run `powershell -File tests/Test-Installer.ps1` for the installer checks. These tests cover menu navigation, missing dependencies, combat guards and preservation of existing addon files. They do not replace an in-game check after a client update.
