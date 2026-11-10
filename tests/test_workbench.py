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
function methods:GetWidth()return 1920 end
function methods:GetHeight()return 1080 end
function methods:SetText(s)self.value=s end
function methods:Click(which)if self.scripts.OnClick then self.scripts.OnClick(self,which)end end
for _,key in ipairs({'SetSize','SetPoint','SetFrameStrata','SetClampedToScreen','SetBackdrop','SetBackdropColor','SetBackdropBorderColor','SetWidth','SetJustifyH','SetJustifyV','SetTextColor','SetSpacing','SetHeight','RegisterForClicks','ClearAllPoints','SetTexture','SetScale','EnableMouseWheel','RegisterEvent'})do methods[key]=function()end end
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
source = (root / 'AddOns/NightProController/NightProWorkbench.lua').read_text()
lua.execute(source)
lua.execute(r'''
local w=NightProWorkbench
w:Open('gear');assert(textHas('Apprentice Hood'));assert(calls.rank==1)
w:Move(1,0);w:Move(0,-1);assert(calls.rank==1,'Moving focus must not rerank')
pressLabel('Affliction');assert(calls.spec=='demonology')
pressLabel('Usable now');assert(calls.range[1]==12 and calls.range[2]==21)
pressLabel('View loot source');assert(textHas('Test Dungeon / Test Boss'),'source navigation');assert(textHas('Cached item 123'),'item label')
w:Back();assert(textHas('Dungeon Quest'));w:Back();assert(textHas('Test Dungeon'));w:Back();w:Back();assert(not w.frame:IsShown())
w:Open('quests');assert(textHas('A real quest'));assert(textHas('Enemies defeated: 2/5'))
assert(textHas('Complete - ready to turn in'))
pressLabel('Open quest map');assert(calls.quest==42 and not w.frame:IsShown())
w:Open('auctions');assert(textHas('Saved low: 1g 0s 0c'))
pressLabel('Live listings');assert(calls.buy==0 and textHas('Visit an auctioneer'))
pressLabel('Scan at auctioneer');assert(calls.scan==0 and textHas('Visit an auctioneer before scanning'))
calls.atAuctioneer=true;pressLabel('Live listings');assert(calls.buy==1)
w:Open('gear');combat=true;w:Activate();w:Scroll(-1);w:Back();assert(calls.rank==4)
combat=false
NightProGearData.Rank=function()error('Bad upstream data')end
w:Open('gear');assert(textHas('This page could not load'));assert(#NightProKitDiagnostics==1)
w:Back();assert(not w.frame:IsShown(),'Error must not trap the controller')
NightProDungeonData=nil;w:Open('dungeons');assert(textHas('data bridge is missing'))
''')
print('PASS: Lua 5.1; gear filters, no focus reranking/tooltips, dungeon drilldown, quest map, auction guards, combat and recoverable errors')
