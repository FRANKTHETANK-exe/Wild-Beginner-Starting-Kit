from pathlib import Path
import runpy
root=Path(__file__).resolve().parents[1]
controller=runpy.run_path(str(root/'tests/test_controller.py'))['lua']
controller.execute(r'''
combat=false;statuses={};C_AddOns={
 IsAddOnLoaded=function(name)return (statuses[name]or{}).loaded or false end,
 DoesAddOnExist=function(name)return statuses[name]~=nil end,
 GetAddOnInfo=function(name)if statuses[name]then return name,name,'',true end end,
 GetAddOnEnableState=function(name)return(statuses[name]or{}).enabled or 2 end,
 DoesAddOnHaveLoadError=function(name)return(statuses[name]or{}).error or false end,
}
function hasText(value)
 for _,f in ipairs(frames)do if f.kind=='FontString'and type(f.value)=='string'and f.value:find(value,1,true)then return true end end
 return false
end
local hovered=0;SlashCmdList.BAGPAD=function()hovered=hovered+1 end
SlashCmdList.NIGHTPROMENU()
NightProMenuChoice2.scripts.OnEnter(NightProMenuChoice2)
assert(hasText('NOT LOADED - missing')and hasText('https://www.curseforge.com/wow/addons/bagpad-forever'))
statuses.BagPad={enabled=0};NightProMenuChoice2.scripts.OnEnter(NightProMenuChoice2);assert(hasText('NOT LOADED - disabled'))
statuses.BagPad={error=true};NightProMenuChoice2.scripts.OnEnter(NightProMenuChoice2);assert(hasText('load error reported'))
statuses.BagPad={loaded=true};NightProMenuChoice2.scripts.OnEnter(NightProMenuChoice2);assert(hasText('READY')and hovered==0)
for _,name in ipairs(NightProDependencies.names)do
 SlashCmdList.NIGHTPRODEPENDENCIES(name)
 for _,f in ipairs(frames)do if f.scripts.OnUpdate then f.scripts.OnUpdate(f,.11)end end
 assert(hasText(NightProDependencies:State(name).url),'Each named help request must show its own exact official project')
end
SlashCmdList.NIGHTPRODEPENDENCIES('Questie Forever Gamepad')
local body
for _,f in ipairs(frames)do if f.kind=='FontString'and type(f.value)=='string'and f.value:find('/questie-forever-gamepad',1,true)then body=f end end
assert(body,'Named helper must select the requested dependency, not another addon')
local all=''
for i=1,12 do
 all=all..'\n'..body.value
 local _,lines=body.value:gsub('\n','');assert(lines<=7,'Existing detail area must be paginated to eight lines')
 NightProAddonMenu.scripts.OnMouseWheel(NightProAddonMenu,-1)
end
assert(all:find('Install.ps1',1,true)and all:find('-AllowMissingDependencies',1,true))
NightProWorkbenchFrame=CreateFrame('Frame','NightProWorkbenchFrame',UIParent)
NightProSettingsFrame=CreateFrame('Frame','NightProSettingsFrame',UIParent)
SlashCmdList.NIGHTPRODEPENDENCIES('NeedRoll')
assert(not NightProWorkbenchFrame:IsShown()and not NightProSettingsFrame:IsShown(),'Dependency help must replace other owned windows')
NightProAddonMenu:Hide();NightProWorkbenchFrame:Show();NightProSettingsFrame:Show()
SlashCmdList.NIGHTPROMENU()
assert(NightProAddonMenu:IsShown()and not NightProWorkbenchFrame:IsShown()and not NightProSettingsFrame:IsShown(),'Launcher must replace other owned windows')
NightProAddonMenu:Hide();NightProWorkbenchFrame:Show();NightProSettingsFrame:Show()
local prior=body.value;combat=true;SlashCmdList.NIGHTPRODEPENDENCIES('NeedRoll');SlashCmdList.NIGHTPROMENU()
assert(body.value==prior and not NightProAddonMenu:IsShown()and NightProWorkbenchFrame:IsShown()and NightProSettingsFrame:IsShown(),'Combat must leave existing windows unchanged')
combat=false
local opened=0;NightProWorkbench={Open=function()opened=opened+1 end}
NightProMenuChoice4:Click();assert(opened==1,'Missing optional tool dependencies must not disable the whole hub')
''')
print('PASS: existing hover/details, per-dependency exact links, disabled/error/recovery, bounded pagination, no hover actions and combat guards')
workbench=runpy.run_path(str(root/'tests/test_workbench.py'))['lua']
workbench.execute(r'''
local w=NightProWorkbench;statuses={};C_AddOns={
 IsAddOnLoaded=function(name)return(statuses[name]or{}).loaded or false end,
 DoesAddOnExist=function(name)return statuses[name]~=nil end,
 GetAddOnInfo=function(name)if statuses[name]then return name,name,'',true end end,
 GetAddOnEnableState=function()return 2 end,
 DoesAddOnHaveLoadError=function()return false end,
}
NightProGearData=nil;w:Open('gear');assert(textHas('GearedForever - NOT LOADED - missing'))
w:Activate();assert(textHas('https://www.curseforge.com/wow/addons/gearedforever'))
statuses.GearedForever={loaded=true};w:Open('gear');assert(textHas('LOADED - connection needed'))
local g={NightProClasses={{token='WARLOCK',name='Warlock',specs={{key='demo',label='Demonology'}}}},Rank=function()error('Known provider call failure')end};NightProGearData=g
w:Open('gear');assert(textHas('This page could not load')and NightProDependencies:State('GearedForever').state=='api_error')
local sawLink=textHas('https://www.curseforge.com/wow/addons/gearedforever');for i=1,15 do w:Scroll(-1);sawLink=sawLink or textHas('https://www.curseforge.com/wow/addons/gearedforever')end;assert(sawLink,'Runtime provider errors must retain paged exact-download help')
g.Rank=function()local slots={};for i=1,17 do slots[i]={}end;return slots end
w:Open('gear');assert(NightProDependencies:State('GearedForever').state=='ready','A successful provider call clears its reported integration failure')
NightProQuestVisualData=nil;QuestieLoader=nil;w:Open('quests');assert(textHas('A real quest'),'Native quest journal remains usable without quest dependencies')
w:Activate();assert(textHas('Collect venom: 0/4'),'Remaining features must keep their existing quest text')
SlashCmdList.QUESTIEFOREVERGAMEPAD=nil;w:Open('tracking');assert(textHas('Questie Forever Gamepad - NOT LOADED - missing'))
w:Activate();assert(textHas('https://www.curseforge.com/wow/addons/questie-forever-gamepad'))
''')
print('PASS: hub missing/connection/API-error help, exact links, recovery and usable native journal without third-party dependencies')
