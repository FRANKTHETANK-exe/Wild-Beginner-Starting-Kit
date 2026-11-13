-- SPDX-License-Identifier: GPL-3.0-only
local S={};NightProSetup=S
S.prompt=[=[Help me install Wild Starting Kit for World of Warcraft Forever on Windows.

Project: https://www.curseforge.com/wow/addons/wild-beginner-starting-kit
Source and setup: https://github.com/FRANKTHETANK-exe/Wild-Beginner-Starting-Kit

First read the current README.md, INSTALL.md and curseforge-dependencies.json. Find my actual _forever_/Interface/AddOns folder; ask if there is more than one. This kit is for Forever interface 16001, not Retail or Classic.

Install the kit and its eight required original addons from their official CurseForge projects into the same game installation. Keep their original names, credits and licenses. Platynator is optional. A manual ZIP does not fetch dependencies. Never use a random download mirror.

Before changing files, make sure WoW is closed and preserve existing addons, bindings and WTF settings. Do not close a running game without asking. Inspect the included Install.ps1. Run it first with -AddonPath pointing to the verified folder and -Preview. If the preview passes, run that same command without -Preview. It connects supported originals and saves backups; it does not download them. Do not bypass unsupported-version checks, turn off security, change execution policy, delete my settings or downgrade an original addon to force setup.

If a dependency is missing or a version is unsupported, explain exactly which one and stop that step. After setup, launch WoW through Battle.net, enable both NightPro addons and their required originals, and help me open /adventurehub. Check Find Gear, My Quests, Dungeons & Loot and Auction Prices. Use /npdeps for any missing tool. Ask whether I prefer controller or keyboard and mouse, and help me choose that in NightPro Controls. Do not automate gameplay, purchases or account sign-in.

If you cannot control my computer, guide me one short step at a time. Never claim something is installed or tested unless you checked it. End with what works, anything still missing and where the setup backup was saved.]=]
local window
function S:Open()
 if InCombatLockdown()then return end
 for _,name in ipairs({'NightProAddonMenu','NightProWorkbenchFrame','NightProSettingsFrame'})do if _G[name]then _G[name]:Hide()end end
 if not window then
  window=CreateFrame('Frame','NightProSetupPromptFrame',UIParent,'BackdropTemplate')
  window:SetSize(620,860);window:SetPoint('CENTER');window:SetFrameStrata('DIALOG');window:SetClampedToScreen(true)
  window:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8x8',edgeFile='Interface\\Buttons\\WHITE8x8',edgeSize=2})
  window:SetBackdropColor(.035,.035,.045,.98);window:SetBackdropBorderColor(.65,.55,.30,.9)
  tinsert(UISpecialFrames,'NightProSetupPromptFrame')
  local function label(y,value)
   local f=window:CreateFontString(nil,'OVERLAY','GameFontHighlight');f:SetPoint('TOPLEFT',24,y);f:SetWidth(572);f:SetJustifyH('LEFT');f:SetText(value);return f
  end
  label(-24,'SET UP WITH AI'):SetTextColor(1,.82,0)
  label(-60,'Click the prompt. Ctrl+A selects all. Ctrl+C copies.\nPaste it into your AI assistant. AI is optional.')
  local scroll=CreateFrame('ScrollFrame',nil,window,'UIPanelScrollFrameTemplate')
  scroll:SetPoint('TOPLEFT',24,-112);scroll:SetSize(546,646)
  local edit=CreateFrame('EditBox','NightProSetupPromptText',scroll)
  edit:SetMultiLine(true);edit:SetAutoFocus(false);edit:SetFontObject('GameFontHighlight');edit:SetWidth(520)
  edit:SetText(S.prompt);edit:SetCursorPosition(0);scroll:SetScrollChild(edit)
  edit:SetScript('OnTextChanged',function(self,user)if user then self:SetText(S.prompt);self:SetCursorPosition(0)end end)
  edit:SetScript('OnEscapePressed',function(self)self:ClearFocus();window:NightProBack()end)
  edit:SetScript('OnEditFocusGained',function(self)self:HighlightText()end)
  window:SetScript('OnHide',function()edit:ClearFocus()end)
  local back=CreateFrame('Button','NightProSetupPromptBack',window,'UIPanelButtonTemplate');back:SetSize(572,36);back:SetPoint('TOPLEFT',24,-780);back:SetText('Back to kit menu')
  back:SetScript('OnClick',function()window:NightProBack()end)
  label(-830,'No AI connection. No automatic downloads. You choose what runs.')
  function window:NightProBack()self:Hide();if SlashCmdList.NIGHTPROMENU then SlashCmdList.NIGHTPROMENU()end end
 end
 window:SetScale(math.min(1,UIParent:GetWidth()*.29/620,UIParent:GetHeight()*.60/860));window:Show()
end
SLASH_NIGHTPROSETUPAI1='/npai';SlashCmdList.NIGHTPROSETUPAI=function()S:Open()end
