# Install Wild Starting Kit

**For WoW Forever on Windows. Not Retail or Classic.**

## Easiest way

**1. Install the kit in CurseForge.** Choose your Forever game folder. Allow the required addons to install too. They belong to the original authors. If you do not see the latest file, check the project's Files tab and its Beta option.

**2. Close WoW.** Open your game's `_forever_` folder, then `Interface`, `AddOns`, and `NightProController`.

**3. Connect the addons.** Right-click an empty space in that folder and open a PowerShell terminal. Paste this, then press Enter:

```powershell
.\Install.ps1 -AddonPath (Split-Path -Parent $PWD.Path)
```

**4. Open WoW through Battle.net.** At character selection, click **AddOns** and enable both NightPro addons and the required originals. Enter the game and type **`/adventurehub`**.

That's the main menu: **Find Gear, My Quests, Dungeons & Loot, and Auction Prices.** For bags, use **Bags** on your normal controller wheel. For controls, setup help or credits, type **`/npmenu`**.

**Step 3 is required.** CurseForge installs the files but cannot run the connection step for you. The script saves backups and preserves your settings. If it says a version is unsupported or Windows blocks it, stop and keep the message for help.

## Want AI to walk you through it?

Open [AI-SETUP.txt](AI-SETUP.txt), copy the whole prompt and paste it into your AI assistant. It can guide you or, if you have given it computer access, help with the actual setup. No AI subscription or AI tool is required to use the addon.

In the game, **`/npmenu` > Set Up with AI** or **`/npai`** opens the same prompt. Click the text, press **Ctrl+A**, then **Ctrl+C** to copy it. The addon does not connect to an AI service or send your data anywhere.

## Downloaded a ZIP instead?

Put **NightProController** and **NightProAdventureHub** directly inside your game's `Interface\AddOns` folder. Install the eight originals from [DEPENDENCIES.md](DEPENDENCIES.md) in that same folder, then follow steps 2–4 above. A ZIP cannot install them automatically.

## Something missing?

| What you see | What to do |
| --- | --- |
| An addon is missing | Install its Forever version in the same game folder, then fully restart WoW. |
| An addon is disabled | Enable it in the character's AddOns list. |
| Connection needed | Close WoW and repeat step 3. |
| Unsupported version or an error | Keep the message and [report it](https://github.com/FRANKTHETANK-exe/Wild-Beginner-Starting-Kit/issues). Do not replace files or bypass checks to force it. |
| No quest tracker or arrow | Open **My Quests > Tracking & arrow**. |

**`/npdeps`** shows which original addon needs attention and its official link. [Advanced setup and recovery](SETUP-DETAILS.md) has the less common options.

## Pick your controls

Open **NightPro Controls > Input**. Controller navigation can be on or off; mouse clicks work either way.

- **D-pad up/down:** choose. **Left/right:** change pages.
- **A:** open. **B:** back. **LB/RB:** previous/next page.
- **Mouse:** click the same choices and Back buttons.

Bank and auction pages show saved information. Visit a banker or auctioneer to move items or trade. Some original advanced settings still need a mouse or keyboard.

The original addons do the heavy lifting. NightPro brings them into a shared hub with navigation and setup help. [Meet the authors and read the credits](CREDITS.md).
