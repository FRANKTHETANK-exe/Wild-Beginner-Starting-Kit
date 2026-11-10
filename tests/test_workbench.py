from pathlib import Path
from lupa.lua51 import LuaRuntime

lua = LuaRuntime(unpack_returned_tuples=True)
lua.execute(r'''
frames={};combat=false;UISpecialFrames={};tinsert=table.insert;SlashCmdList={};calls={rank=0,buy=0,scan=0}
local methods={}
function methods:SetScript(k,v)self.scripts[k]=v end
function methods:GetScript(k)return self.scripts[k]end
function methods:Show()self.shown=true end
function methods:Hide()self.shown=false end
function methods:SetShown(v)self.shown=v end
function methods:IsShown()return self.shown end
function methods:IsVisible()return self.shown and(not self.parent or self.parent:IsVisible())end
function methods:GetWidth()return self.width or 1920 end
function methods:GetHeight()return self.height or 1080 end
function methods:SetText(s)self.value=s end
function methods:Click(which)if self.scripts.OnClick then self.scripts.OnClick(self,which)end end
for _,key in ipairs({'SetSize','SetPoint','SetFrameStrata','SetClampedToScreen','SetBackdrop','SetBackdropColor','SetBackdropBorderColor','SetWidth','SetJustifyH','SetJustifyV','SetTextColor','SetSpacing','SetHeight','RegisterForClicks','ClearAllPoints','SetTexture','SetScale','EnableMouseWheel','RegisterEvent'})do methods[key]=function()end end
function methods:SetSize(w,h)self.width=w;self.height=h end
function methods:SetScale(s)self.scale=s end
function methods:SetPoint(...)self.point={...}end
function CreateFrame(kind,name,parent)
 local f=setmetatable({kind=kind,name=name,parent=parent,shown=true,scripts={}}, {__index=methods})
 if name then _G[name]=f end;frames[#frames+1]=f;return f
end
function methods:CreateTexture()return CreateFrame('Texture',nil,self)end
function methods:CreateFontString()return CreateFrame('FontString',nil,self)end
UIParent=CreateFrame('Frame','UIParent')
function InCombatLockdown()return combat end
function UnitClass()return 'Warlock','WARLOCK'end
function UnitLevel()return 11 end
function date(_,v)return v and tostring(v)or 'today'end
function GetItemInfo(id)return 'Cached item '..id end
GameTooltip=setmetatable({}, {__index=function()error('Workbench must not call native tooltips')end})
NightProGearData={NightProClasses={{token='WARLOCK',name='Warlock',specs={{key='affliction',label='Affliction'},{key='demonology',label='Demonology'}}}},
 Rank=function(cls,spec,lo,hi,quest,count,show)
  calls.rank=calls.rank+1;calls.range={lo,hi};calls.spec=spec
  local ranks={};for i=1,17 do ranks[i]={{item={id=123,name='Apprentice Hood',lvl=8,source='Dungeon reward',st={}}}}end;return ranks
 end}
NightProDungeonData={Data={byCategory={DUNGEON={{id='TEST',category='DUNGEON',name='Test Dungeon',encounters={{id='BOSS',name='Test Boss',loot={{itemID=123}}}}}},RAID={}},quests={TEST={{id=42,name='Dungeon Quest',minLevel=8,level=10,giver='Quest Giver'}}},instances={}}}
NightProDungeonData.Data.instances.TEST=NightProDungeonData.Data.byCategory.DUNGEON[1]
C_QuestLog={GetNumQuestLogEntries=function()return 2 end,GetInfo=function(i)return i==1 and {title='Zone',isHeader=true}or{title='A real quest',questID=42,level=10}end,
 GetQuestObjectives=function()return {{text='Enemies defeated: 2/5'}}end,IsComplete=function()return true end}
function QuestMapFrame_OpenToQuestDetails(id)calls.quest=id end
ImprovedForever={Auction={Realm=function()return {items={[123]={}}}end,Stats=function()return 1,100 end,
 Latest=function()return 100,10000,15000,3 end,IsOpen=function()return calls.atAuctioneer end,
 Scan=function()calls.scan=calls.scan+1 end},AuctionBuy={OpenFor=function(id)calls.buy=calls.buy+1 end,Show=function()calls.trade=true end}}
function textHas(value)
 for _,f in ipairs(frames)do if f.kind=='FontString' and f:IsVisible()and tostring(f.value):find(value,1,true)then return true end end
 return false
end
function pressLabel(label)
 for _,f in ipairs(frames)do if f.kind=='Button' and f:IsVisible()and f.label and f.label.value==label then f:Click('LeftButton');return end end
 error('No visible button: '..label)
end
''')
root = Path(__file__).resolve().parents[1]
source = (root / 'AddOns/NightProAdventureHub/NightProWorkbench.lua').read_text()
lua.execute(source)
lua.execute(r'''
local w=NightProWorkbench
for _,size in ipairs({{1920,1080},{2560,1440},{3840,2160},{3440,1440}})do
 for _,uiScale in ipairs({.64,.85,1})do
  UIParent.width=size[1]/uiScale;UIParent.height=size[2]/uiScale
  w:Open()
  local fw=w.frame.width*w.frame.scale*uiScale
  local fh=w.frame.height*w.frame.scale*uiScale
  local cropWidth=size[2]*9/16
  assert(fw<=cropWidth*.95,'Hub must fit inside the portrait crop with a margin')
  assert(fh<=size[2]*.601,'Hub must fit between the social strip and avatar')
  assert(w.frame.point[1]=='CENTER' and w.frame.point[3]=='CENTER','Hub must remain centered')
 end
end
UIParent.width=1920;UIParent.height=1080
w:Open();assert(textHas('NIGHTPRO ADVENTURE HUB'));assert(textHas('Four tools, one hub.'))
assert(textHas('Find Gear') and textHas('My Quests'))
w:Activate();assert(textHas('Apprentice Hood'));assert(calls.rank==1)
w:Move(0,-1);w:Move(0,1);assert(calls.rank==1,'Moving focus must not rerank')
pressLabel('Role: Affliction');assert(calls.spec=='demonology')
pressLabel('Usable now');assert(calls.range[1]==12 and calls.range[2]==21)
pressLabel('1. Apprentice Hood');assert(textHas('View loot source'))
pressLabel('View loot source');assert(textHas('Test Dungeon > Test Boss'));assert(textHas('Cached item 123'))
w:Back();assert(textHas('Test Boss'));w:Back();assert(textHas('Bosses & loot') and textHas('Dungeon quests'))
pressLabel('Dungeon quests');assert(textHas('Dungeon Quest'));w:Back();w:Back();w:Back();assert(textHas('Four tools, one hub.'))
w:Open('quests');assert(textHas('A real quest'));assert(not textHas('Enemies defeated: 2/5'),'Details must not crowd the list')
assert(textHas('Complete - ready to turn in'));pressLabel('A real quest');assert(textHas('Enemies defeated: 2/5'))
pressLabel('Open quest map');assert(calls.quest==42 and not w.frame:IsShown())
w:Open('auctions');assert(textHas('Saved low: 1g 0s 0c'))
pressLabel('Cached item 123');pressLabel('Live listings');assert(calls.buy==0 and textHas('Visit an auctioneer'))
w:Back();pressLabel('Scan at auctioneer');assert(calls.scan==0 and textHas('Visit an auctioneer before scanning'))
calls.atAuctioneer=true;pressLabel('Cached item 123');pressLabel('Live listings');assert(calls.buy==1)
w:Open('gear');local ranks=calls.rank;combat=true;w:Activate();w:Scroll(-1);w:Back();assert(calls.rank==ranks)
combat=false
NightProGearData.Rank=function()error('Bad upstream data')end
w:Open('gear');assert(textHas('This page could not load'));assert(#NightProKitDiagnostics==1)
w:Back();assert(textHas('Four tools, one hub.'));w:Back();assert(not w.frame:IsShown())
NightProDungeonData=nil;w:Open('dungeons');assert(textHas('data bridge is missing'))
-- Short filter rows must never strand focus on an invisible control.
w:Open('quests');w:Move(0,1);w:Move(1,0);w:Move(0,-1);w:Activate();assert(textHas('Enemies defeated: 2/5'))
-- Long descriptions are paged instead of clipped.
w:Back();C_QuestLog.GetQuestObjectives=function()local t={};for i=1,35 do t[i]={text='Objective '..i..': collect the requested supplies'}end;return t end
w:Open('quests');w:Activate();assert(textHas('Objective 1:'));assert(not textHas('Objective 35:'))
for i=1,10 do w:Scroll(-1)end;assert(textHas('Objective 35:'))
w:Back();assert(textHas('A real quest'));w:Back();assert(textHas('Four tools, one hub.'))
local savedObjectives={[2]={text='Vicious Night Web Spider Venom: 0/4',finished=false}}
QuestieLoader={_modules={QuestLogCache={TryGetQuest=function()return {objectives=savedObjectives}end}}}
C_QuestLog.GetQuestObjectives=function()return {{text='0/4'}}end
w:Open('quests');w:Activate();assert(textHas('Vicious Night Web Spider Venom: 0/4'))
assert(savedObjectives[2].text=='Vicious Night Web Spider Venom: 0/4','Do not mutate Questie snapshots')
QuestieLoader=nil;w:Open('quests');w:Activate();assert(textHas('Open the quest map for the target name.'))
-- Pictures use the selected objective identity, and completed quests use the turn-in target.
local resolved={}
C_QuestLog.IsComplete=function()return false end
C_QuestLog.GetQuestObjectives=function()return {{text='Collect venom: 0/4'},{text='Speak to the apothecary'}}end
GetItemIcon=function(id)assert(id==55);return 'venom-icon'end
NightProQuestVisualData={ResolveTrackerTarget=function(_,native,context)
 resolved[#resolved+1]={complete=native.complete,index=context and context.ObjectiveIndex}
 if native.complete then return {kind='creature',id=99,name='Apothecary',role='Quest turn-in'}end
 return context.ObjectiveIndex==1 and {kind='item',id=55,name='Venom'}or {kind='creature',id=99,name='Apothecary'}
end,EntityModelRequest=function(_,entry,model)
 model.SetCreature=function(_,id)calls.model=id end;return 'SetCreature',entry.id
end,ConfigureEntityCamera=function()calls.camera=(calls.camera or 0)+1 end}
w:Open('quests');w:Activate();assert(textHas('Venom'));assert(resolved[1].index==1 and resolved[2].index==2)
w:Scroll(-1);assert(calls.model==99 and textHas('Apothecary'))
local cameraCalls=calls.camera;w:Scroll(-1);assert(calls.camera==cameraCalls,'Stable picture must not reload its model')
C_QuestLog.IsComplete=function()return true end
w:Open('quests');w:Activate();assert(textHas('Quest turn-in: Apothecary'));assert(resolved[#resolved].complete)
w:Back();assert(not textHas('Quest turn-in: Apothecary'),'Pictures must hide when leaving details')
NightProQuestVisualData.ResolveTrackerTarget=function()error('Missing target data')end
w:Open('quests');w:Activate();assert(textHas('Collect venom: 0/4'),'Missing pictures must preserve the quest text')
local original={kind='creature',id=123,name='Night Web Spider',refs={{kind='item',name='Spider Venom'}}}
NightProQuestVisualData.ResolveTrackerTarget=function()return original end
C_QuestLog.IsComplete=function()return false end
QuestieLoader={_modules={QuestieDB={QueryNPCSingle=function(id,key)assert(id==123);return key=='minLevel'and 3 or 5 end}}}
w:Open('quests');w:Activate()
assert(textHas('Enemy level 3-5') and textHas('Defeat Night Web Spider and loot Spider Venom.'))
assert(original.guide==nil and original.levelText==nil,'Never modify upstream quest targets')
QuestieLoader=nil;w:Open('quests');w:Activate();assert(textHas('Enemy level not listed'))
C_QuestLog.IsComplete=function()return true end
w:Open('quests');w:Activate();assert(textHas('Return to Night Web Spider and turn in your quest.'))
assert(not textHas('Enemy level not listed'),'Turn-in NPCs are not enemies')

QuestieForeverGamepadDB={trackerShown=true,navArrow={enabled=false,scale=1,locked=true}}
SlashCmdList.QUESTIEFOREVERGAMEPAD=function(cmd)
 calls.tracking=cmd
 if cmd=='tracker hide' then QuestieForeverGamepadDB.trackerShown=false end
 if cmd=='arrow on' then QuestieForeverGamepadDB.navArrow.enabled=true end
end
w:Open('quests');pressLabel('Tracking & arrow');assert(textHas('Your journey'))
assert(textHas('Tracking and arrow: Questie Forever Gamepad.'))
pressLabel('Side quest tracker: ON');assert(calls.tracking=='tracker hide' and textHas('Side quest tracker: OFF'))
pressLabel('Navigation arrow: OFF');assert(calls.tracking=='arrow on')
pressLabel('Arrow size: 100%');assert(calls.tracking=='arrow scale 1.25')
pressLabel('Arrow position: LOCKED');assert(calls.tracking=='arrow unlock')
pressLabel('About the quest tools');assert(textHas('NightPro did not make Questie'))
pressLabel('Original settings');assert(calls.tracking=='settings' and not w.frame:IsShown())
w:Open('tracking');w:Back();assert(textHas('A real quest'))
''')
print('PASS: one hub, list/detail flow, gear filters, source navigation, separate dungeon sections, quest map, auction guards, safe B navigation, long-text pagination and combat guards')
