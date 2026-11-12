# 1.5.2 Beta: connected guides and controller page changes

- D-pad left/right changes list and detail pages, and map floors/zones. Back restores the gear item, quest or map floor that opened the next page.
- Gear source links open the matching boss loot or dungeon quest guide when the original data contains a match. Quest rewards include both fixed and choice rewards.
- Dungeon quest guides keep objectives, requirements, giver, turn-in, rewards, available target pictures and maps inside Adventure Hub.
- Added dungeon floor maps with boss, quest and entrance points, plus supported Questie target-location maps. Nearby labels avoid covering the selected point; up/down can still select every point.
- Fixed quest NPC picture framing and clarified the map button prompts.
- Kept the existing menus, bags, bank and original addon ownership. No upstream addon code or databases are bundled.
- Shortened the public name to Wild Starting Kit. Existing folder names, settings and project links remain compatible.
- Added fresh in-game screenshots and a shorter setup guide. Detailed connection, backup and recovery instructions remain in INSTALL.md.

# 1.5.1 candidate: dependency status and recovery help

- Fixed overlapping NightPro windows when opening dependency help or the kit menu from Adventure Hub or Controls. Combat leaves existing windows unchanged.
- Kept named dependency help visible when controller focus first enters the menu.
- Added per-addon missing, disabled, load-error, connection-needed and API/integration status in the existing menu/hub panels, with exact official project links and paged installation/restart instructions.
- Added `/npdeps` for all dependency help, or a specific original addon. Status queries never enable/force-load addons, open a browser or change security settings.
- Added explicit `-AllowMissingDependencies` setup/restoration for absent originals. Available verified sources remain atomic; unknown/incomplete installed files still stop safely. Later official installation and reapplication are supported.
- Kept the same four hub cards, menu rows, geometry and healthy connected feature paths. Native quest text remains usable when its optional integrations are absent.
- Retained the reviewed owned-file/bridge rollback and linked-path protections, with missing/disabled/API failure and partial/later-install regressions.

# Unreleased: official-install setup

- Kept the existing layout, connected-page/data paths, navigation and model algorithms. The later 1.5.1 additions below provide the explicitly requested status/help only.
- Removed direct dependency downloads from local setup. Originals are installed through their own CurseForge projects.
- Kept exactly the same three local Lua bridge bodies, with explicit disclosure and exact source-hash checks for examined original/current releases.
- Added staged/preflighted NightPro-owned installation, atomic writes, rollback of owned files on copy/bridge failure, exact bridge-suffix removal and per-run recovery records. Linked leaf destinations and relevant root/ancestor junctions are refused.
- Added offline installation, update/recovery and original-code data-contract tests. A live game/client installation check remains required before publication.

# 1.5.0

- Adventure Hub is a separate addon with direct minimap and controller-wheel access.
- Added Your journey inside the hub for tracker visibility and arrow controls.
- Removed replacement names and skins from original addon windows. Questie Forever Gamepad, BagPad and other tools keep their own identity.
- Added quest target pictures, short next steps and known enemy level ranges.
- Enlarged input settings and added a saved controller navigation switch.
- Centered supported menus, bags and settings for portrait streams.
- Kept Start Here first and expanded project credits.

