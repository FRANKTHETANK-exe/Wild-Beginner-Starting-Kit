# Wild Beginner Starting Kit

I put this together because I wanted new players to spend less time figuring out addon menus and more time playing. It brings existing tools together through Adventure Hub, with controller navigation and keyboard-and-mouse support.

**This is a new-player starting guide and integration pack. I did not create the original addons.** NightPro adds the shared pages, launcher, navigation adapter and installation setup. The original tools keep their names, authors and licenses.

## What it does

- Adventure Hub gives you four clear choices: gear, quests, dungeon loot and saved auction prices.
- Gear starts with your class. Choose a role, slot and level range, then check an item's source. Suggestions come from GearedForever.
- Quest details show objectives, target pictures when available, known enemy levels and a short next step. Questie, QuestieDB and Questie Forever Gamepad provide the quest information and picture helpers.
- Your journey puts tracker visibility and arrow controls inside the hub. The original Questie Forever Gamepad editor remains available under its own name.
- Dungeons & Loot separates locations, bosses, loot and dungeon quests, using NeedRoll's information.
- Auction Prices shows saved observations from Improved Forever. Buying and selling still require an auctioneer.
- BagPad provides the native controller bags, item actions and bank snapshots. NightPro does not replace those systems.
- The kit's menus use a narrow, centered layout for portrait streams. Controller navigation is optional; keyboard and mouse remain available.

## Compatibility and installation

**WoW Forever only, interface 16001. This is an alpha integration release, not a Retail or Classic addon.**

Installing the two NightPro folders alone is not the full setup. The required addons and three small, version-checked data bridges must also be installed. CurseForge does not run that setup script for you.

1. Install or extract both NightPro addon folders into `_forever_/Interface/AddOns`.
2. Close WoW. Open PowerShell in the installed `NightProController` folder.
3. Run `./Install.ps1 -AddonPath 'D:\World of Warcraft\_forever_\Interface\AddOns'`, replacing the path with your own installation.
4. Reopen the game through Battle.net. Enable both NightPro addons and their dependencies.
5. Click the split faction badge on the minimap or choose Adventure Hub on controller wheel page 3 when a free slot is available. `/adventurehub` also opens it. `/npmenu` opens Start Here and the kit controls.

The installer fetches pinned original releases from their distribution hosts and checks their hashes. It preserves existing addons and saved settings. It backs up supported files before appending the data bridges; unknown versions are refused. After an upstream update, a bridge may need a compatible update too.

Text entry, some advanced settings and moving the arrow still need a keyboard or pointer. The kit does not automate combat, movement, trading or item destruction. Bank and auction snapshots are saved information, not live remote access.

## The people who made this possible

- **Chris / TheFerdinandGamer — [BagPad](https://www.curseforge.com/wow/addons/bagpad-forever):** controller bags, item actions, bank and inventory snapshots. MIT.
- **markg / markgravity — [Improved Forever and Auction](https://github.com/markgravity/ImprovedForever):** controller settings, bindings and auction controls. MIT.
- **moust4ki — [Easy Controller - Forever](https://github.com/moust4ki/EasyControllerWowForever):** work credited by Improved Forever in its controller configuration, wheel editor and vibration features. MIT.
- **Nathan / fistedwaffles05 — [GearedForever](https://www.curseforge.com/wow/addons/gearedforever):** gear information and recommendations. GPLv3.
- **mikebvs / flowmotion_x — [NeedRoll](https://www.curseforge.com/wow/addons/needroll):** dungeon, loot and related quest information. GPLv3.
- **Tombons97 and contributors — [Questie Forever Gamepad](https://www.curseforge.com/wow/addons/questie-forever-gamepad):** controller quest support, tracker, navigation arrow and quest-picture helpers. GPL-3.0-only.
- **Questie contributors — [Questie](https://github.com/Questie/Questie):** quest information, maps and tracking. See its original license notices.
- **Logonz and Questie contributors — [QuestieDB](https://github.com/Questie/QuestieDB):** quest database. See its original license notices.
- **plusmouse — [Platynator](https://www.curseforge.com/wow/addons/platynator):** optional nameplates. All Rights Reserved; not bundled.
- **xeR — Forever Quality of Life Settings:** the visual reference credited by BagPad. The kit follows that existing style; it does not claim it as original artwork.

Thank you to all of these authors. This kit only brings their work together and makes it easier to move around for new players. Original addon code is downloaded separately, not republished as NightPro's work. World of Warcraft and its game assets belong to Blizzard Entertainment.

NightPro's own integration code is GPL-3.0-only. That license does not replace the licenses of the dependencies.

[Source, full credits and issue tracker](https://github.com/FRANKTHETANK-exe/Wild-Beginner-Starting-Kit)
