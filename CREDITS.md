# Credits

This kit would not exist without the people who built the addons below. NightPro is the shared pages, packaging and navigation adapter. It is not a replacement author credit for their work.

| Project | Original authors | What the kit uses | License |
| --- | --- | --- | --- |
| [BagPad](https://www.curseforge.com/wow/addons/bagpad-forever) | Chris / TheFerdinandGamer | Native controller bags, item actions, bank and inventory snapshots, the dark-and-gold visual style | MIT |
| [Improved Forever](https://github.com/markgravity/ImprovedForever) | markg / markgravity | Controller settings and bindings | MIT |
| [Improved Forever Auction](https://github.com/markgravity/ImprovedForever) | markg / markgravity | Controller auction interface | MIT |
| [Easy Controller - Forever](https://github.com/moust4ki/EasyControllerWowForever) | moust4ki | Work credited by Improved Forever in its configuration, wheel editor and vibration features | MIT |
| [GearedForever](https://www.curseforge.com/wow/addons/gearedforever) | Nathan / fistedwaffles05 | Gear browser and upgrade information | GPLv3 |
| [NeedRoll](https://www.curseforge.com/wow/addons/needroll) | mikebvs; published by flowmotion_x | Dungeons, loot, quests and related data | GPLv3 |
| [Questie Forever Gamepad](https://www.curseforge.com/wow/addons/questie-forever-gamepad) | Tombons97 and contributors | Quest controller support, objective identity and model framing for quest pictures; design reference for the adapter's read-only wheel overlay | GPL-3.0-only |
| [Questie](https://github.com/Questie/Questie) | Questie contributors | Quest maps and tracking | See upstream's mixed-license notice |
| [QuestieDB](https://github.com/Questie/QuestieDB) | Logonz and Questie contributors | Quest database | See upstream's license notices |
| [Platynator](https://www.curseforge.com/wow/addons/platynator) | plusmouse | Optional nameplates; opened through the menu | All Rights Reserved |

BagPad credits xeR's **Forever Quality of Life Settings** as the visual reference for its interface. The kit follows that existing bag style. It does not claim the design as original NightPro artwork.

Auctionator (plusmouse and Borjamacare) and Syndicator (plusmouse) were part of the earlier local setup. They are not included or required by this release. Their code is All Rights Reserved, and their authors retain that ownership.

## What changed

NightPro's companion addon adds shared Gear, Quests, Dungeons & Loot and saved Auction pages, plus a single launcher with tool descriptions, missing-addon status, first steps and credits. It adds directional focus, button activation, scrolling and back navigation to supported gear and dungeon windows. It provides a visual shortcut over an unused slot on the native wheel, without replacing the wheel's data.

Original addon windows keep their own names, artwork and authors. The separate **Your journey** page inside Adventure Hub calls Questie Forever Gamepad's supported commands for tracker and arrow settings. The original editor remains available under its original name. NightPro does not claim the tracker, arrow, quest database or original editor as its own work.

Marked bridges in the verified GearedForever Core.lua, NeedRoll API.lua and Questie Forever Gamepad Core.lua files let the hub read their data and use existing quest-picture helpers. Byte-for-byte backups are kept first. These bridges expose existing functions and data; they do not replace the original implementations.

Native bag controls come from BagPad. Quest controller controls come from Questie Forever Gamepad. Auction controller controls come from Improved Forever Auction. Those are not new features authored by NightPro.

## Distribution

The source in `AddOns/NightProController` and `AddOns/NightProAdventureHub` is GPL-3.0-only. Its wheel integration follows the design of Questie Forever Gamepad's `RadialMenu.lua`; that relationship is retained in the source notice.

Upstream addon code is not included in this repository or the kit ZIP. The installer downloads original releases directly from GitHub or CurseForge's distribution CDN and verifies the pinned hashes. Each addon keeps its own license, authors, libraries and artwork. The GPL license in this repository applies to the NightPro companion, not to every dependency.

World of Warcraft and its game assets belong to Blizzard Entertainment. This is a community addon pack and is not an official Blizzard product.

The Adventure Hub badge uses the Alliance and Horde faction textures already provided by the WoW client. Those emblems belong to Blizzard Entertainment. No game artwork is bundled in this repository.
