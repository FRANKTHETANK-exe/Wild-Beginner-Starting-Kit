-- NightPro accessibility adapter. No writes or hooks to native gamepad frames.
-- The read-only wheel overlay follows the design of QuestieForeverGamepad RadialMenu.lua
-- (QuestieForeverGamepad contributors, GPL-3.0-only). This file is GPL-3.0-only.
local root,selected,buttons,active
local own=CreateFrame('Frame','NightProControllerBindings',UIParent,'SecureHandlerStateTemplate')
own:SetAttribute('_onstate-combat', 'if newstate == "combat" then self:ClearBindings() end')
RegisterStateDriver(own,'combat','[combat] combat; peace')
local mark=CreateFrame('Frame',nil,UIParent,'BackdropTemplate')
mark:SetBackdrop({edgeFile='Interface\\Buttons\\WHITE8x8',edgeSize=3});mark:SetBackdropBorderColor(1,.82,0);mark:SetFrameStrata('TOOLTIP');mark:Hide()
local legend=mark:CreateFontString(nil,'OVERLAY','GameFontNormal');legend:SetPoint('BOTTOM',UIParent,'BOTTOM',0,38);legend:SetText('D-pad: move   A: select   X: alternate   B: back   LB/RB: scroll')

local panel=CreateFrame('Frame','NightProAddonMenu',UIParent,'BackdropTemplate')
panel:SetSize(920,650);panel:SetPoint('CENTER');panel:SetFrameStrata('DIALOG')
panel:SetClampedToScreen(true)
panel:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8x8',edgeFile='Interface\\Buttons\\WHITE8x8',edgeSize=2})
panel:SetBackdropColor(.035,.035,.045,.98);panel:SetBackdropBorderColor(.65,.55,.30,.9)
panel:Hide();tinsert(UISpecialFrames,'NightProAddonMenu')
local function text(parent,font,x,y,width,value)
 local f=parent:CreateFontString(nil,'OVERLAY',font)
 f:SetPoint('TOPLEFT',x,y);f:SetWidth(width);f:SetJustifyH('LEFT');f:SetText(value)
 return f
end
local heading=text(panel,'GameFontNormalLarge',24,-22,870,'NIGHTPRO  |  WILD BEGINNER STARTING KIT')
heading:SetTextColor(1,.82,0)
text(panel,'GameFontHighlight',24,-53,870,'Controller support for World of Warcraft Forever')
local detail=CreateFrame('Frame',nil,panel,'BackdropTemplate')
detail:SetPoint('TOPLEFT',400,-93);detail:SetSize(496,484)
detail:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8x8',edgeFile='Interface\\Buttons\\WHITE8x8',edgeSize=1})
detail:SetBackdropColor(.06,.06,.075,1);detail:SetBackdropBorderColor(.40,.35,.22,.8)
local detailTitle=text(detail,'GameFontNormalLarge',22,-24,452,'Welcome')
detailTitle:SetTextColor(1,.82,0)
local detailBody=text(detail,'GameFontHighlight',22,-65,452,'Choose a tool on the left.')
detailBody:SetSpacing(5)
local status=text(detail,'GameFontNormal',22,-434,452,'')
local footer=text(panel,'GameFontHighlight',24,-604,870,'D-pad: move    A: open    B: close    LB / RB: scroll')
footer:SetTextColor(.85,.80,.68)
local function loaded(name)
 local fn=C_AddOns and C_AddOns.IsAddOnLoaded or IsAddOnLoaded
 return fn and fn(name)
end
local function slash(key,arg)
 if SlashCmdList[key] then SlashCmdList[key](arg or '');return true end
 print('|cffffd100NightPro|r: This tool is not ready. Check the AddOns list at character selection.')
end
local function controls()
 if ImprovedForever and ImprovedForever.RunCommand then ImprovedForever.RunCommand('') end
end
local firstSteps='1. Open NightPro from the empty slot on wheel page 3, or type /npmenu.\n\n2. Bags still opens the native controller bag. Use its own button prompts to equip, move or destroy items.\n\n3. Visit your bank once to save its contents. Snapshots show the last visit; they cannot move remote items.\n\n4. Check Gear for upgrades, then Dungeons for drops and quests.\n\n5. Auction buying and selling still needs an auctioneer.\n\nB backs out of this menu and supported tool windows. Combat keeps control of your game buttons.'
local credits='BagPad: Chris / TheFerdinandGamer (MIT).\n\nImproved Forever and Auction: markg / markgravity (MIT). Includes work from moust4ki\'s Easy Controller (MIT).\n\nGearedForever: Nathan / fistedwaffles05 (GPLv3).\n\nNeedRoll: mikebvs / flowmotion_x (GPLv3).\n\nQuestie Forever Gamepad: Tombons97 and contributors (GPLv3). Questie and QuestieDB: their contributors.\n\nBagPad\'s style cites xeR\'s Forever Quality of Life Settings.\n\nNightPro: this shared menu, branding and navigation adapter. Original addon code and authorship stay with their creators.'
local choices={
 {'NightPro Bag Settings','BagPad','Open the bag layout and controller options.\n\nTo open your inventory, choose Bags on the native controller wheel. Use its item prompts to equip, move or destroy items.',function()slash('BAGPAD')end},
 {'NightPro Bank','BagPad','Browse bank contents saved on your last visit.\n\nVisit a banker to deposit or withdraw items. This does not provide remote bank access.',function()slash('BAGPAD','bank')end},
 {'NightPro Gear','GearedForever','Look up gear by class, spec and level.\n\nD-pad selects a control. A activates it. X uses an alternate click where the tool supports one. LB / RB scroll.',function()if NightProWorkbench then NightProWorkbench:Open('gear')else slash('GEAREDFOREVER')end end},
 {'NightPro Quests','QuestieForeverGamepad','Read your current quests and objectives in the shared interface.\n\nYour map and tracker stay available. Open Tracker settings from the Quests page.',function()if NightProWorkbench then NightProWorkbench:Open('quests')else slash('QUESTIEFOREVERGAMEPAD','settings')end end},
 {'NightPro Dungeons & Loot','NeedRoll','Find dungeons, bosses, drops and dungeon quests.\n\nUse D-pad and A to browse. LB / RB changes pages. B steps back through bosses and dungeons.',function()if NightProWorkbench then NightProWorkbench:Open('dungeons')else slash('NEEDROLL')end end},
 {'NightPro Auctions','ImprovedForever_Auction','Saved auction prices in the shared interface. Live trading opens at an auctioneer.\n\nYou cannot buy or sell from anywhere in the world.',function()if NightProWorkbench then NightProWorkbench:Open('auctions')else controls()end end},
 {'NightPro Inventory','BagPad','Inventory snapshots and saved characters.\n\nSnapshots only know what the addon has seen. Visit a character or bank to update them.',function()slash('BAGPAD','characters')end},
 {'NightPro Controls','ImprovedForever','Open controller bindings and module settings.\n\nThe kit keeps your existing bindings. Tools with their own controller support keep handling their own buttons.',controls},
 {'NightPro Nameplates','Platynator','Optional nameplate settings.\n\nPlatynator is a separate addon by plusmouse. Its original editor stays intact; some editing controls still need a pointer.',function()slash('Platynator')end},
 {'Start Here',nil,firstSteps},
 {'Credits',nil,credits},
 {'Close',nil,'Back to the game.',function()end},
}
local function describe(choice)
 detailTitle:SetText(choice[1]);detailBody:SetText(choice[3])
 if choice[2] then
  local ready=loaded(choice[2]);status:SetText(ready and 'READY' or 'NOT LOADED - see the install guide')
  status:SetTextColor(ready and .55 or 1,ready and .85 or .65,.35)
 else status:SetText('') end
end
for i,choice in ipairs(choices) do
 local b=CreateFrame('Button','NightProMenuChoice'..i,panel,'BackdropTemplate')
 b:SetSize(352,35);b:SetPoint('TOPLEFT',24,-93-(i-1)*40)
 b:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8x8',edgeFile='Interface\\Buttons\\WHITE8x8',edgeSize=1})
 b:SetBackdropColor(.08,.08,.10,1);b:SetBackdropBorderColor(.40,.35,.22,.8)
 local label=text(b,'GameFontHighlight',14,-10,315,choice[1])
 b:SetScript('OnEnter',function(self) self:SetBackdropColor(.20,.17,.08,1);describe(choice) end)
 b:SetScript('OnLeave',function(self) self:SetBackdropColor(.08,.08,.10,1) end)
 b:SetScript('OnClick',function()
  if InCombatLockdown() then return end
  describe(choice)
  if choice[2] and not loaded(choice[2]) then return end
  if choice[4] then panel:Hide();C_Timer.After(0,choice[4]) end
 end)
end
panel:SetScript('OnShow',function()
 local width,height=UIParent:GetWidth(),UIParent:GetHeight()
 panel:SetScale(math.min(1,(width-32)/920,(height-32)/650))
 describe(choices[10])
end)
local function visible(f) return f and f.IsVisible and f:IsVisible() end
local function allowed(f) return f and not (f.IsForbidden and f:IsForbidden()) and not (f.IsProtected and f:IsProtected()) end
local function release()
 if active and not InCombatLockdown() then own:Execute('self:ClearBindings()');active=false end
 mark:Hide();selected=nil
end
local function focus(f)
 if selected==f then return end
 if selected and selected~=f then local cb=selected:GetScript('OnLeave');if cb then cb(selected)end end
 selected=f;if not f then mark:Hide();return end
 mark:ClearAllPoints();mark:SetPoint('TOPLEFT',f,'TOPLEFT',-3,3);mark:SetPoint('BOTTOMRIGHT',f,'BOTTOMRIGHT',3,-3);mark:Show()
 local cb=f:GetScript('OnEnter');if cb and root==panel then cb(f)end
end
local function collect(f)
 if f and f.NightProMove then buttons={};mark:Hide();return end
 buttons={};local function walk(parent,depth)
  if depth>15 then return end
  for _,child in ipairs({parent:GetChildren()})do
   if allowed(child) and visible(child) then
    local clickable=child.IsObjectType and child:IsObjectType('Button') and (not child.IsEnabled or child:IsEnabled()) and child:GetScript('OnClick')
    if clickable then local x,y=child:GetCenter();if x and y then buttons[#buttons+1]={f=child,x=x,y=y}end end
    walk(child,depth+1)
   end
  end
 end;walk(f,0)
 table.sort(buttons,function(a,b) if math.abs(a.y-b.y)>6 then return a.y>b.y else return a.x<b.x end end)
 local kept=false;for _,b in ipairs(buttons)do if b.f==selected then kept=true;break end end
 if not kept then focus(buttons[1] and buttons[1].f)end
end
local function move(dx,dy)
 if not root then return end;if root.NightProMove then root:NightProMove(dx,dy);return end;collect(root);if not selected then return end
 local x,y=selected:GetCenter();local best,cost
 for _,b in ipairs(buttons)do
  local ex,ey=b.x-x,b.y-y;local forward=ex*dx+ey*dy;local side=math.abs(ex*dy-ey*dx)
  if b.f~=selected and forward>3 then local score=forward+side*3;if not cost or score<cost then best=b.f;cost=score end end
 end
 if best then focus(best)end
end
local function click(which)
 if not InCombatLockdown() and visible(root) and root.NightProActivate then root:NightProActivate(which);return end
 if InCombatLockdown() or not visible(selected) or not allowed(selected) then return end
 selected:Click(which or 'LeftButton');C_Timer.After(0,function()if visible(root)then collect(root)end end)
end
local function scroll(delta)
 if InCombatLockdown() or not root then return end
 if root.NightProScroll then root:NightProScroll(delta);return end
 local f=selected
 while f do local cb=f:GetScript('OnMouseWheel');if cb then cb(f,delta);C_Timer.After(0,function()if visible(root)then collect(root)end end);return end;if f==root then break end;f=f:GetParent()end
 local function find(parent)
  if not visible(parent)then return end
  local cb=parent:GetScript('OnMouseWheel');if cb then cb(parent,delta);return true end
  for _,c in ipairs({parent:GetChildren()})do if find(c)then return true end end
 end;find(root);C_Timer.After(0,function()if visible(root)then collect(root)end end)
end
local function back()
 if InCombatLockdown()then return end
 if root and root.NightProBack then root:NightProBack();if visible(root)then return end
 elseif root and allowed(root)then root:Hide()end
 release();root=nil
end
local defs={PADDUP=function()move(0,1)end,PADDDOWN=function()move(0,-1)end,PADDLEFT=function()move(-1,0)end,PADDRIGHT=function()move(1,0)end,PAD1=function()click('LeftButton')end,PAD3=function()click('RightButton')end,PAD2=back,PADLSHOULDER=function()scroll(1)end,PADRSHOULDER=function()scroll(-1)end}
local targets={};for key,fn in pairs(defs)do local b=CreateFrame('Button','NightProNav_'..key,UIParent);b:RegisterForClicks('AnyDown');b:SetScript('OnClick',fn);targets[key]=b:GetName()end
local function bind()
 if InCombatLockdown()then return end
 own:Execute('self:ClearBindings()')
 for key,name in pairs(targets)do own:Execute(('self:SetBindingClick(true, %q, %q, "LeftButton")'):format(key,name))end;active=true
end
local rootNames={'NightProWorkbenchFrame','NightProAddonMenu','GearedForeverFrame','NeedRollFrame','NeedRollNativeFrame','NeedRollDarkFrame','NeedRollElvUIFrame'}
local function currentRoot()
 if visible(panel) then return panel end
 local best
 local names={};for _,n in ipairs(rootNames)do names[#names+1]=n end
 for _,n in ipairs(UISpecialFrames)do if n:match('^GearedForever')or n:match('^NeedRoll.*Frame$')or n:match('^PlatynatorCustomiseDialog')then names[#names+1]=n end end
 for _,name in ipairs(names)do
  local f=_G[name]
  if allowed(f)and visible(f)then if not best or f:GetFrameLevel()>best:GetFrameLevel()then best=f end end
 end
 return best
end
-- Own visual on the last empty slot of native wheel page 3, leaving Questie's first slot free.
local overlay=CreateFrame('Frame',nil,UIParent);overlay:SetFrameStrata('FULLSCREEN_DIALOG');overlay:EnableMouse(false);overlay:SetSize(60,60);overlay:Hide()
local icon=overlay:CreateTexture(nil,'ARTWORK');icon:SetAllPoints();icon:SetTexture(134063)
local label=overlay:CreateFontString(nil,'OVERLAY','GameFontNormal');label:SetPoint('TOP',overlay,'BOTTOM',0,-3);label:SetText('NightPro Kit')
local lastIndex,slot,armed,waitOpen,closeOwner,closeTarget
local function wheelTick()
 local w=GamepadRadial
 if not visible(w)then
  overlay:Hide()
  if armed and w and not w.isCancelled then if waitOpen then armed=nil;waitOpen=nil;panel:Show()else waitOpen=true end else armed=nil end
  lastIndex=nil;return
 end
 local page=w.mainMenuPages and w.mainMenuPages[3]
 if w.currentPage~=page or w.isCancelled then overlay:Hide();armed=nil;lastIndex=nil;return end
 slot=nil;for i=8,1,-1 do if page.buttons[i]==nil and w.SegmentList[i]and not w.SegmentList[i].handler then slot=i;break end end
 if not slot then overlay:Hide();return end
 local seg=w.SegmentList[slot];local x,y=seg:GetCenter();if not x then return end
 local ox,oy=seg:GetIconOffset('function');local scale=seg:GetEffectiveScale()/UIParent:GetEffectiveScale();overlay:ClearAllPoints();overlay:SetPoint('CENTER',UIParent,'BOTTOMLEFT',(x+ox)*scale,(y+oy)*scale);overlay:Show()
 local index=w.currentIndex
 if index and index~=0 and index~=slot then armed=nil end
 if lastIndex==slot and index==0 and (w.lastDistanceSq or 1)<.04 then
  armed=true
  if not InCombatLockdown()then
   closeOwner=closeOwner or CreateFrame('Frame',nil,UIParent,'SecureHandlerBaseTemplate')
   if closeTarget~=w then closeOwner:SetFrameRef('wheel',w);closeTarget=w end
   local ok=pcall(closeOwner.Execute,closeOwner,'local wheel=self:GetFrameRef("wheel"); if wheel then wheel:Hide(true) end');if not ok then label:SetText('NightPro Kit - press B')end
  end
 end
 lastIndex=index
end
local timer=0;local driver=CreateFrame('Frame')
driver:SetScript('OnUpdate',function(_,dt)
 timer=timer+dt;if timer<.10 then return end;timer=0
 if InCombatLockdown()or not(InputUtil and InputUtil.IsGamepadUIEnabled())then release();overlay:Hide();armed=nil;waitOpen=nil;lastIndex=nil;return end
 wheelTick()
 if visible(GamepadRadial)then release();return end
 local nextRoot=currentRoot()
 if nextRoot~=root then release();root=nextRoot;if root then collect(root);bind()end
 elseif root then if not active then collect(root);bind()end end
end)
driver:RegisterEvent('PLAYER_REGEN_DISABLED');driver:RegisterEvent('PLAYER_REGEN_ENABLED');driver:SetScript('OnEvent',function()release();root=nil end)
SLASH_NIGHTPROMENU1='/npmenu';SlashCmdList.NIGHTPROMENU=function()if not InCombatLockdown()then panel:SetShown(not panel:IsShown())end end
NightProControllerReady=true
