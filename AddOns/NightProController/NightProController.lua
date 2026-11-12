-- NightPro accessibility adapter. No writes or hooks to native gamepad frames.
-- The read-only wheel overlay follows the design of QuestieForeverGamepad RadialMenu.lua
-- (QuestieForeverGamepad contributors, GPL-3.0-only). This file is GPL-3.0-only.
local root,selected,buttons,active
local audit=CreateFrame('Frame')
audit:RegisterEvent('ADDON_ACTION_BLOCKED');audit:RegisterEvent('ADDON_ACTION_FORBIDDEN')
audit:SetScript('OnEvent',function(_,event,addon,action)
 if addon~='NightProController' then return end
 NightProKitDiagnostics=NightProKitDiagnostics or {}
 local d=NightProKitDiagnostics
 d[#d+1]={at=date('%Y-%m-%d %H:%M:%S'),page='controller',message=event..': '..tostring(action)}
 while #d>12 do table.remove(d,1)end
 print('|cffffd100NightPro|r: '..event..' - '..tostring(action))
end)
local own=CreateFrame('Frame','NightProControllerBindings',UIParent,'SecureHandlerStateTemplate')
own:SetAttribute('_onstate-combat', 'if newstate == "combat" then self:ClearBindings() end')
RegisterStateDriver(own,'combat','[combat] combat; peace')
local mark=CreateFrame('Frame',nil,UIParent,'BackdropTemplate')
mark:SetBackdrop({edgeFile='Interface\\Buttons\\WHITE8x8',edgeSize=3});mark:SetBackdropBorderColor(1,.82,0);mark:SetFrameStrata('TOOLTIP');mark:Hide()
local legend=mark:CreateFontString(nil,'OVERLAY','GameFontNormal');legend:SetPoint('BOTTOM',UIParent,'BOTTOM',0,38);legend:SetText('D-pad: move   A: select   X: alternate   B: back   LB/RB: scroll')

local panel=CreateFrame('Frame','NightProAddonMenu',UIParent,'BackdropTemplate')
panel:SetSize(620,900);panel:SetPoint('CENTER');panel:SetFrameStrata('DIALOG')
panel:SetClampedToScreen(true)
panel:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8x8',edgeFile='Interface\\Buttons\\WHITE8x8',edgeSize=2})
panel:SetBackdropColor(.035,.035,.045,.98);panel:SetBackdropBorderColor(.65,.55,.30,.9)
panel:Hide();tinsert(UISpecialFrames,'NightProAddonMenu')
local function showMenu()
 if InCombatLockdown()then return end
 if NightProWorkbenchFrame then NightProWorkbenchFrame:Hide()end
 if NightProSettingsFrame then NightProSettingsFrame:Hide()end
 panel:Show()
end
local function text(parent,font,x,y,width,value)
 local f=parent:CreateFontString(nil,'OVERLAY',font)
 f:SetPoint('TOPLEFT',x,y);f:SetWidth(width);f:SetJustifyH('LEFT');f:SetText(value)
 return f
end
local heading=text(panel,'GameFontNormalLarge',24,-22,550,'NIGHTPRO  |  BEGINNER KIT')
heading:SetTextColor(1,.82,0)
text(panel,'GameFontHighlight',24,-53,550,'Bags, bank and your Adventure Hub')
local detail=CreateFrame('Frame',nil,panel,'BackdropTemplate')
detail:SetPoint('TOPLEFT',24,-505);detail:SetSize(572,330)
detail:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8x8',edgeFile='Interface\\Buttons\\WHITE8x8',edgeSize=1})
detail:SetBackdropColor(.06,.06,.075,1);detail:SetBackdropBorderColor(.40,.35,.22,.8)
local detailTitle=text(detail,'GameFontNormalLarge',18,-18,536,'Welcome')
detailTitle:SetTextColor(1,.82,0)
local detailBody=text(detail,'GameFontHighlight',18,-57,536,'Choose a tool above.')
detailBody:SetSpacing(4);detailBody:SetHeight(215)
local status=text(detail,'GameFontNormal',18,-293,536,'')
local footer=text(panel,'GameFontHighlight',24,-860,572,'D-pad: choose   A: open   B: close   LB / RB: read more')
footer:SetTextColor(.85,.80,.68)
local function loaded(name)
 local fn=C_AddOns and C_AddOns.IsAddOnLoaded or IsAddOnLoaded
 if not fn then return false end
 local ok,loading,ready=pcall(fn,name);return ok and (ready==nil and loading==true or ready==true)
end
local function slash(key,arg)
 if SlashCmdList[key] then SlashCmdList[key](arg or '');return true end
 print('|cffffd100NightPro|r: This tool is not ready. Check the AddOns list at character selection.')
end
local function controls()
 if NightProSettings then NightProSettings:Open() end
end
local firstSteps='1. Open Adventure Hub from wheel page 3 or the blue/red minimap emblem. /adventurehub opens it too. This kit menu is /npmenu.\n\n2. Bags still opens the native controller bag. Use its own button prompts to equip, move or destroy items.\n\n3. Visit your bank once to save its contents. Snapshots show the last visit; they cannot move remote items.\n\n4. Open Adventure Hub. Find Gear, My Quests, Dungeons & Loot and Auction Prices are sections inside it.\n\n5. Auction buying and selling still needs an auctioneer.\n\nB backs out of this menu and supported tool windows. Combat keeps control of your game buttons.'
local credits='BagPad: Chris / TheFerdinandGamer (MIT).\n\nImproved Forever and Auction: markg / markgravity (MIT). Includes work from moust4ki\'s Easy Controller (MIT).\n\nGearedForever: Nathan / fistedwaffles05 (GPLv3).\n\nNeedRoll: mikebvs / flowmotion_x (GPLv3).\n\nQuestie Forever Gamepad: Tombons97 and contributors (GPLv3). Questie and QuestieDB: their contributors. Questie provides quest data, map pins and tracking; Questie Forever Gamepad provides objective pictures and model framing.\n\nBagPad\'s style cites xeR\'s Forever Quality of Life Settings.\n\nNightPro: this shared menu, branding and navigation adapter. Original addon code and authorship stay with their creators.'
local choices={
 {'Start Here',nil,firstSteps},
 {'Bag Settings - BagPad','BagPad','BagPad by Chris / TheFerdinandGamer provides the inventory and its item controls.\n\nTo open your inventory, choose Bags on the native controller wheel. Use its item prompts to equip, move or destroy items.',function()slash('BAGPAD')end},
 {'Bank - BagPad','BagPad','BagPad provides bank contents saved on your last visit.\n\nVisit a banker to deposit or withdraw items. This does not provide remote bank access.',function()slash('BAGPAD','bank')end},
 {'Adventure Hub',nil,'Gear, quests, dungeons and auction prices are now four sections of ONE hub.\n\nOpen it, choose what you want to do, then select an entry to read its details. B takes you back one step.',function()if NightProWorkbench then NightProWorkbench:Open()end end},
 {'Inventory - BagPad','BagPad','BagPad provides inventory snapshots and saved characters.\n\nSnapshots only know what the addon has seen. Visit a character or bank to update them.',function()slash('BAGPAD','characters')end},
 {'NightPro Controls',nil,'Choose controller or keyboard-and-mouse navigation.\n\nJourney opens the tracking controls inside Adventure Hub. Controller bindings open the original Improved Forever editor.',controls},
 {'Nameplates - Platynator','Platynator','Optional nameplate settings.\n\nPlatynator is a separate addon by plusmouse. Its original editor stays intact; some editing controls still need a pointer.',function()slash('Platynator')end},
 {'Credits',nil,credits},
 {'Close',nil,'Back to the game.',function()end},
}
local dependency=NightProDependencies
if dependency then
 choices[1].dependencies=dependency.names
 choices[4].dependencies={'GearedForever','NeedRoll','Questie','QuestieDB','QuestieForeverGamepad','ImprovedForever','ImprovedForever_Auction'}
 choices[6].dependencies={'ImprovedForever','QuestieForeverGamepad'}
end
local detailPages,detailPage={},1
local function addPages(value)
 if not value or value==''then return end
 local lines={}
 for line in (value..'\n'):gmatch('(.-)\n')do
  local part=''
  for word in line:gmatch('%S+')do
   if #part>0 and #part+#word+1>64 then lines[#lines+1]=part;part=word else part=part==''and word or part..' '..word end
  end
  lines[#lines+1]=part
 end
 for i=1,#lines,8 do local page={};for j=i,math.min(i+7,#lines)do page[#page+1]=lines[j]end;detailPages[#detailPages+1]=table.concat(page,'\n')end
end
local function describe(choice)
 detailTitle:SetText(choice[1]);detailPages={};detailPage=1
 local names=choice.dependencies or (choice[2]and{choice[2]})or {}
 local issues,ready={},{ }
 if dependency then
  for _,name in ipairs(names)do local v=dependency:State(name);if v then
   if v.state~='ready'then issues[#issues+1]=name else ready[#ready+1]=name end
  end end
  if choice.allHelp then for _,name in ipairs(names)do addPages(dependency:Help(name))end
  else
   for _,name in ipairs(issues)do addPages(dependency:Help(name))end
   addPages(choice[3]);for _,name in ipairs(ready)do addPages(dependency:Help(name))end
  end
 else addPages(choice[3])end
 detailBody:SetText(detailPages[1]or '')
 if choice[2]then
  local v=dependency and dependency:State(choice[2]);local isReady=v and v.state=='ready';if not v then isReady=loaded(choice[2])end
  status:SetText(v and v.label or (isReady and 'READY'or 'NOT LOADED - see the install guide'))
  status:SetTextColor(isReady and .55 or 1,isReady and .85 or .65,.35)
 elseif dependency and #names>0 then
  local summary=dependency:Summary(names);status:SetText(summary..'  |  LB / RB: dependency help')
  status:SetTextColor(summary=='READY'and .55 or 1,summary=='READY'and .85 or .65,.35)
 else status:SetText('')end
end
if dependency then
 function dependency:Open(name)
  if InCombatLockdown()then return end
  local item=self:Resolve(name);showMenu()
  describe({item and item.title..' dependency'or 'Dependency status',nil,'',dependencies=item and{item.name}or self.names,allHelp=true})
 end
 SLASH_NIGHTPRODEPENDENCIES1='/npdeps'
 SlashCmdList.NIGHTPRODEPENDENCIES=function(name)dependency:Open(name)end
end
for i,choice in ipairs(choices) do
 local b=CreateFrame('Button','NightProMenuChoice'..i,panel,'BackdropTemplate')
 b:SetSize(572,39);b:SetPoint('TOPLEFT',24,-93-(i-1)*44)
 b:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8x8',edgeFile='Interface\\Buttons\\WHITE8x8',edgeSize=1})
 b:SetBackdropColor(.08,.08,.10,1);b:SetBackdropBorderColor(.40,.35,.22,.8)
 local label=text(b,'GameFontHighlight',14,-10,540,choice[1])
 b:SetScript('OnEnter',function(self) self:SetBackdropColor(.20,.17,.08,1);describe(choice) end)
 b:SetScript('OnLeave',function(self) self:SetBackdropColor(.08,.08,.10,1) end)
 b:SetScript('OnClick',function()
  if InCombatLockdown() then return end
  describe(choice)
  if choice[2] then
   local value=dependency and dependency:State(choice[2])
   if not loaded(choice[2])or(value and value.state~='ready')then return end
  end
  if choice[4] then panel:Hide();C_Timer.After(0,choice[4]) end
 end)
end
panel:SetScript('OnShow',function()
 local width,height=UIParent:GetWidth(),UIParent:GetHeight()
 panel:SetScale(math.min(1,width*.29/620,height*.60/900));panel:ClearAllPoints();panel:SetPoint('CENTER',UIParent,'CENTER',0,0)
 describe(choices[1])
end)
panel:EnableMouseWheel(true)
panel:SetScript('OnMouseWheel',function(_,delta)
 detailPage=math.max(1,math.min(#detailPages,detailPage+(delta>0 and -1 or 1)))
 detailBody:SetText(detailPages[detailPage]or '')
end)
local function visible(f) return f and f.IsVisible and f:IsVisible() end
local function allowed(f) return f and not (f.IsForbidden and f:IsForbidden()) and not (f.IsProtected and f:IsProtected()) end
local function release()
 if active and not InCombatLockdown() then own:Execute('self:ClearBindings()');active=false end
 mark:Hide();selected=nil
end
local function focus(f,keepDescription)
 if selected==f then return end
 if selected and selected~=f then local cb=selected:GetScript('OnLeave');if cb then cb(selected)end end
 selected=f;if not f then mark:Hide();return end
 mark:ClearAllPoints();mark:SetPoint('TOPLEFT',f,'TOPLEFT',-3,3);mark:SetPoint('BOTTOMRIGHT',f,'BOTTOMRIGHT',3,-3);mark:Show()
 local cb=f:GetScript('OnEnter');if cb and root==panel and not keepDescription then cb(f)end
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
 if not kept then focus(buttons[1] and buttons[1].f,true)end
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
local rootNames={'NightProSettingsFrame','NightProWorkbenchFrame','NightProAddonMenu','GearedForeverFrame','NeedRollFrame','NeedRollNativeFrame','NeedRollDarkFrame','NeedRollElvUIFrame'}
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
local icon=overlay:CreateTexture(nil,'ARTWORK');icon:SetAllPoints();icon:Hide();NightProCreateEmblem(overlay,60)
local label=overlay:CreateFontString(nil,'OVERLAY','GameFontNormal');label:SetPoint('TOP',overlay,'BOTTOM',0,-3);label:SetText('Adventure Hub')
local lastIndex,slot,armed,waitOpen,closeOwner,closeTarget
local function wheelTick()
 local w=GamepadRadial
 if not visible(w)then
  overlay:Hide()
  if armed and w and not w.isCancelled then if waitOpen then armed=nil;waitOpen=nil;if NightProWorkbench then NightProWorkbench:Open()else showMenu()end else waitOpen=true end else armed=nil end
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
   local ok=pcall(closeOwner.Execute,closeOwner,'local wheel=self:GetFrameRef("wheel"); if wheel then wheel:Hide(true) end');if not ok then label:SetText('Adventure Hub - press B')end
  end
 end
 lastIndex=index
end
local timer=0;local driver=CreateFrame('Frame')
driver:SetScript('OnUpdate',function(_,dt)
 timer=timer+dt;if timer<.10 then return end;timer=0
 if InCombatLockdown()or (NightProPreferences and NightProPreferences.controllerEnabled==false)or not(InputUtil and InputUtil.IsGamepadUIEnabled())then release();overlay:Hide();armed=nil;waitOpen=nil;lastIndex=nil;return end
 wheelTick()
 if visible(GamepadRadial)then release();return end
 local nextRoot=currentRoot()
 if nextRoot~=root then release();root=nextRoot;if root then collect(root);bind()end
 elseif root then if not active then collect(root);bind()end end
end)
driver:RegisterEvent('PLAYER_REGEN_DISABLED');driver:RegisterEvent('PLAYER_REGEN_ENABLED');driver:SetScript('OnEvent',function()release();root=nil end)
SLASH_NIGHTPROMENU1='/npmenu';SlashCmdList.NIGHTPROMENU=function()if not InCombatLockdown()then if panel:IsShown()then panel:Hide()else showMenu()end end end
NightProControllerReady=true
