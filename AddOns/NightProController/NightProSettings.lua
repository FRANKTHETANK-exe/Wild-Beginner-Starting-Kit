-- SPDX-License-Identifier: GPL-3.0-only
local S={page='input',selected=1}
NightProSettings=S
local f=CreateFrame('Frame','NightProSettingsFrame',UIParent,'BackdropTemplate')
S.frame=f
f:SetSize(620,860);f:SetPoint('CENTER');f:SetFrameStrata('DIALOG');f:SetClampedToScreen(true)
f:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8x8',edgeFile='Interface\\Buttons\\WHITE8x8',edgeSize=2})
f:SetBackdropColor(.025,.04,.065,.99);f:SetBackdropBorderColor(.72,.57,.28,1)
f:Hide();tinsert(UISpecialFrames,'NightProSettingsFrame')
local function label(parent,size,x,y,width,value)
 local t=parent:CreateFontString(nil,'OVERLAY');t:SetFont(STANDARD_TEXT_FONT,size,'')
 t:SetPoint('TOPLEFT',x,y);t:SetWidth(width);t:SetJustifyH('LEFT');t:SetJustifyV('TOP');t:SetText(value or '')
 return t
end
label(f,28,24,-23,570,'NIGHTPRO  |  CONTROLS'):SetTextColor(1,.83,.47)
local subtitle=label(f,20,24,-66,570,'Play your way. Change a setting with a click or A.')
local footer=label(f,18,24,-786,570,'')
footer:SetHeight(60)
local cards,tabs={},{}
local function qcmd(cmd)
 if not SlashCmdList.QUESTIEFOREVERGAMEPAD then return false end
 SlashCmdList.QUESTIEFOREVERGAMEPAD(cmd);return true
end
function S:ControllerEnabled()return not NightProPreferences or NightProPreferences.controllerEnabled~=false end
function S:SetController(enabled)
 if InCombatLockdown() then return false end
 NightProPreferences=NightProPreferences or {};NightProPreferences.controllerEnabled=enabled==true
 if ImprovedForever and ImprovedForever.db then
  ImprovedForever.db.padOverrides=enabled==true
  if ImprovedForever.Binds and ImprovedForever.Binds.FocusChanged then ImprovedForever.Binds.FocusChanged()end
 end
 qcmd(enabled and 'gamepad on' or 'gamepad off')
 self:Refresh();return true
end
local function inputRows()
 return {
  {'Controller navigation',S:ControllerEnabled() and 'ON' or 'OFF',
   'ON: D-pad and A/B navigate the kit and quest tools. OFF: use keyboard and mouse. Game movement bindings stay yours.',
   function()S:SetController(not S:ControllerEnabled())end},
  {'Controller bindings','OPEN','Change controller shortcuts in the full binding editor. Your current bindings are kept.',
   function()f:Hide();if ImprovedForever and ImprovedForever.Menu then ImprovedForever.Menu.Open('bindings')end end},
  {'Quest tracking & navigation','OPEN','Open Your journey in Adventure Hub. Tracking and arrow controls use Questie Forever Gamepad.',
   function()S:Open('quests')end},
  {'Adventure Hub','OPEN','One place for your gear, quests, dungeon loot and auction prices.',
   function()f:Hide();if NightProWorkbench then NightProWorkbench:Open()end end},
 }
end
local function button(parent,x,y,w,h)
 local b=CreateFrame('Button',nil,parent,'BackdropTemplate');b:SetPoint('TOPLEFT',x,y);b:SetSize(w,h)
 b:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8x8',edgeFile='Interface\\Buttons\\WHITE8x8',edgeSize=2})
 b:SetBackdropColor(.055,.085,.13,1);b:SetBackdropBorderColor(.28,.34,.43,1)
 return b
end
for i,name in ipairs({'Input','Journey','Close'})do
 local b=button(f,24+(i-1)*194,-106,184,46);b.title=label(b,22,14,-10,160,name);tabs[i]=b
 b:SetScript('OnClick',function()if i==3 then f:Hide()else S:Open(i==1 and 'input' or 'quests')end end)
end
for i=1,4 do
 local b=button(f,24,-174-(i-1)*148,572,134)
 b.title=label(b,24,16,-14,420,'');b.status=label(b,21,444,-16,110,'')
 b.body=label(b,21,16,-52,540,'');b.body:SetHeight(76);b.body:SetTextColor(.84,.88,.94)
 b:SetScript('OnEnter',function()S.selected=i;S:Highlight()end)
 b:SetScript('OnClick',function()S.selected=i;S:Activate()end);cards[i]=b
end
function S:Highlight()
 for i,b in ipairs(cards)do b:SetBackdropBorderColor(i==self.selected and 1 or .28,i==self.selected and .80 or .34,i==self.selected and .38 or .43,1)end
 for i,b in ipairs(tabs)do b:SetBackdropColor((self.page=='input' and i==1 or self.page=='quests' and i==2)and .16 or .055,.085,.13,1)end
end
function S:Refresh()
 self.rows=inputRows()
 for i,row in ipairs(self.rows)do
  cards[i].title:SetText(row[1]);cards[i].status:SetText(row[2]);cards[i].body:SetText(row[3])
  cards[i].status:SetTextColor(row[2]=='OFF' and .8 or .6,row[2]=='OFF' and .65 or 1,.65)
 end
 subtitle:SetText('Keyboard and mouse always work. Controller is optional.')
 footer:SetText(self:ControllerEnabled()and 'D-pad / arrows: choose   A / Enter: select\nLeft / Right: tab   B / Escape: close' or 'Arrows: choose   Enter: select   Left / Right: tab\nClick Controller navigation to enable your controller.')
 self:Highlight()
end
function S:Open(page)
 if InCombatLockdown()then return end
 if page=='quests' then
  if NightProWorkbench then f:Hide();NightProWorkbench:Open('tracking')end
  return
 end
 if NightProAddonMenu then NightProAddonMenu:Hide()end
 if ImprovedForeverConfigFrame then ImprovedForeverConfigFrame:Hide()end
 self.page=page or 'input';self.selected=1
 local h=UIParent:GetHeight();local w=UIParent:GetWidth()
 f:SetScale(math.min(1,(h*9/16*.90)/620,h*.76/860,w*.90/620))
 f:ClearAllPoints();f:SetPoint('CENTER');f:Show();self:Refresh()
end
function S:Move(dx,dy)
 if dx~=0 then self:Open(self.page=='input' and 'quests' or 'input')
 else self.selected=math.max(1,math.min(4,self.selected+(dy>0 and -1 or 1)));self:Highlight()end
end
function S:Activate()
 if InCombatLockdown()then return end
 local row=self.rows and self.rows[self.selected];if row then row[4]();self:Refresh()end
end
f.NightProMove=function(_,dx,dy)S:Move(dx,dy)end
f.NightProActivate=function()S:Activate()end
f.NightProBack=function()f:Hide()end
f:EnableKeyboard(true);f:SetPropagateKeyboardInput(true)
f:SetScript('OnKeyDown',function(self,key)
 if InCombatLockdown()then return end
 local action=({UP=function()S:Move(0,1)end,DOWN=function()S:Move(0,-1)end,
 LEFT=function()S:Move(-1,0)end,RIGHT=function()S:Move(1,0)end,
 ENTER=function()S:Activate()end,ESCAPE=function()self:Hide()end})[key]
 self:SetPropagateKeyboardInput(action==nil);if action then action()end
end)
f:RegisterEvent('PLAYER_REGEN_DISABLED');f:SetScript('OnEvent',function()f:Hide()end)
SLASH_NIGHTPROSETTINGS1='/npcontrols'
SlashCmdList.NIGHTPROSETTINGS=function()S:Open()end
