from pathlib import Path
import runpy

lua=runpy.run_path(str(Path(__file__).with_name('test_workbench.py')))['lua']
lua.execute(r'''
local w=NightProWorkbench
combat=false
NightProGearData.Rank=function()
 local result={}
 for slot=1,17 do result[slot]={};for i=1,14 do result[slot][i]={item={id=100+i,name='Gear '..i,lvl=10,source='Test',st={}}}end end
 return result
end
w:Open('gear');assert(textHas('Page 1 / 3'))
w:Move(1,0);assert(textHas('Page 2 / 3') and textHas('7. Gear 7'))
w:Move(1,0);assert(textHas('Page 3 / 3'));w:Move(1,0);assert(textHas('Page 3 / 3'))
w:Move(-1,0);assert(textHas('Page 2 / 3'))
local instance={id='TEST',name='Test Dungeon',category='DUNGEON',zone='Test Zone',levelRange={12,18},encounters={{id='BOSS',name='Boss One',loot={{itemID=101}}},{id='BOSS2',name='Boss Two',loot={{itemID=102}}}}}
local maps={{'Entrance floor',1000,pins={{'BOSS',.2,.3}}},{'Upper floor','test-map-',pins={{'BOSS2',.7,.6}}},credit='Original map author'}
local q={id=42,name='Dungeon Quest',level=14,minLevel=10,giver='Test Giver',giverNpc=900,objective='Defeat the test boss and return the relic.',choice={114}}
NightProDungeonData={Data={byCategory={DUNGEON={instance},RAID={}},instances={TEST=instance},quests={TEST={q}},Map=function()return maps end,
 Entrance=function()return {map=1454,x=.5,y=.4}end,NpcSpot=function(_,npc,id)assert(npc==900 and id==42);return {map=1454,x=.1,y=.2}end}}
w:Open('dungeons');pressLabel('Test Dungeon');pressLabel('Dungeon map')
assert(textHas('Entrance floor') and textHas('Boss One') and textHas('Original map author'))
w:Move(1,0);assert(textHas('Upper floor') and textHas('Boss Two'))
w:Activate();assert(textHas('Test Dungeon > Boss Two') and textHas('Cached item 102'))
w:Activate();assert(textHas('Dropped by: Boss Two'))
w:Back();assert(textHas('Test Dungeon > Boss Two'))
w:Back();assert(textHas('Upper floor'),'Back from map-selected loot must restore the same floor')
w:Activate('RightButton');assert(textHas('Dungeon Quest'));w:Activate();assert(textHas('WHAT TO DO'))
for i=1,6 do w:Move(1,0)end
assert(textHas('CHOOSE ONE REWARD'))
w:Back();assert(textHas('Dungeon Quest'));w:Back();assert(textHas('Upper floor'))
w:Back();assert(textHas('Bosses & loot'))
w:Open('gear');w:Activate();pressLabel('View loot source');assert(textHas('Test Dungeon > Boss One'))
w:Back();assert(textHas('View loot source') and textHas('1. Gear 1'))
w:Open('gear');w:Move(1,0);w:Move(1,0);w:Move(0,-1);w:Activate();pressLabel('View loot source')
assert(textHas('WHAT TO DO'),'Quest reward gear must lead to its quest guide')
for i=1,10 do w:Move(1,0)end
assert(textHas('Cached item 114'))
w:Back();assert(textHas('View loot source') and textHas('14. Gear 14'))
combat=true;w:Move(1,0);w:Activate();w:Back();assert(textHas('14. Gear 14'));combat=false
assert(q.objective=='Defeat the test boss and return the relic.' and maps[2][1]=='Upper floor','Original data must remain unchanged')
NightProDungeonData.Data.quests={}
C_QuestLog.IsComplete=function()return false end
NightProQuestVisualData.ResolveTrackerTarget=function()return {kind='creature',id=77,name='Test Enemy',refs={{kind='creature'}}}end
QuestieLoader={_modules={QuestieDB={QueryNPCSingle=function(_,field)if field=='spawns'then return {[1]={{50,40},{-1,-1},{60,45}}}end;return 14 end},ZoneDB={GetUiMapIdByAreaId=function(_,area)return area+100 end}}}
C_Map={GetMapArtLayerTextures=function()local t={};for i=1,12 do t[i]=i+1000 end;return t end,GetMapInfo=function()return {name='Quest Zone'}end}
w:Open('quests');w:Activate();pressLabel('Quest locations');assert(textHas('Quest Zone') and textHas('Test Enemy'))
w:Move(0,-1);w:Activate();assert(textHas('Enemies defeated')or textHas('0/4'))
w:Back();assert(textHas('Quest Zone'));w:Back();assert(textHas('Quest locations'))
QuestieLoader=nil;pressLabel('Quest locations');assert(textHas('No supported map locations'))
''')
print('PASS: D-pad pages, page bounds, map floors, boss loot, quest rewards, nested Back history, credits and combat guards')
