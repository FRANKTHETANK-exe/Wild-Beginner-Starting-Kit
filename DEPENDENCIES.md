# Original addons and compatibility baseline

Install originals through their own CurseForge projects. The local setup script downloads nothing. No upstream source or data is bundled. The table records the original tested baseline, not an instruction to bypass the authors' current distribution.

| Tool | Version | Release | Required |
| --- | --- | --- | --- |
| BagPad | BagPad-1.4.0 | [Original release](https://www.curseforge.com/wow/addons/bagpad-forever/files/9522659) | Yes |
| GearedForever | GearedForever_1.0.1 | [Original release](https://www.curseforge.com/wow/addons/gearedforever/files/9521100) | Yes |
| NeedRoll | NeedRoll-v1.4.1-forever | [Original release](https://www.curseforge.com/wow/addons/needroll/files/9530991) | Yes |
| Questie | Questie-v12.6.4 | [Original release](https://www.curseforge.com/wow/addons/questie/files/9502146) | Yes |
| QuestieDB | QuestieDB-1.0.13-Forever | [Original release](https://www.curseforge.com/wow/addons/questiedb/files/9514215) | Yes |
| QuestieForeverGamepad | QuestieForeverGamepad-0.2.93 | [Original release](https://www.curseforge.com/wow/addons/questie-forever-gamepad/files/9526337) | Yes |
| Platynator | Platynator-542 | [Original release](https://www.curseforge.com/wow/addons/platynator/files/9516030) | Optional |
| ImprovedForever | ImprovedForever-0.16.0 | [Original release](https://github.com/markgravity/ImprovedForever/releases/tag/Core-v0.16.0) | Yes |
| ImprovedForever_Auction | ImprovedForever_Auction-0.9.0 | [Original release](https://github.com/markgravity/ImprovedForever/releases/tag/Auction-v0.9.0) | Yes |

The source repository retains historical pins in `dependencies.json`. The active official project links and required/optional relationships are in `curseforge-dependencies.json`. Both Improved Forever projects are on CurseForge: core project 1731245 and Auction project 1736874. Their baseline files are [0.16.0](https://www.curseforge.com/wow/addons/improved-forever/files/9528875) and [0.9.0](https://www.curseforge.com/wow/addons/improved-forever-auction/files/9528876). Read exact release notices as well as current project terms.

The supported client is World of Warcraft Forever (interface 16001). These pins are a compatibility baseline, not an automatic update feed.

Local source connections support GearedForever 1.0.1/1.0.2, NeedRoll 1.4.1/1.6.0 and Questie Forever Gamepad 0.2.93/0.3.15 by exact source hash. Required Dependency relationships must be saved and verified on the CurseForge file; this manifest alone does not configure the site or download anything. Optional Platynator is not automatically required.

For deliberately missing originals, the game UI reports each dependency individually and keeps available features usable. Explicit `-AllowMissingDependencies` setup connects only installed, verified targets; unknown/incomplete installed sources are refused. It does not change the complete-kit CurseForge relationship declarations. `/npdeps <addon name>` shows that original's exact project and repair instructions.
