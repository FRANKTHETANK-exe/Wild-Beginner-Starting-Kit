from pathlib import Path
import json
from lupa.lua51 import LuaRuntime
root=Path(__file__).resolve().parents[1]
lua=LuaRuntime(unpack_returned_tuples=True)
lua.execute(r'''
addon={};function UnitName()return 'Test character'end
C_AddOns={
 IsAddOnLoaded=function(name)local a=addon[name]or{};if a.queryError then error('Status unavailable')end;return a.loading or a.loaded or false,a.loaded or false end,
 DoesAddOnExist=function(name)return addon[name]~=nil end,
 GetAddOnInfo=function(name)local a=addon[name];if not a then return end;return name,name,'',a.loadable~=false,a.reason end,
 GetAddOnEnableState=function(name)return (addon[name]or{}).enabled or 2 end,
 DoesAddOnHaveLoadError=function(name)return (addon[name]or{}).loadError or false end,
 EnableAddOn=function()error('Status must not enable addons')end,
 LoadAddOn=function()error('Status must not force load addons')end,
 SetAddonVersionCheck=function()error('Status must not change security/version checks')end,
}
SlashCmdList={BAGPAD=function()error('Status must not execute addon commands')end,QUESTIEFOREVERGAMEPAD=function()end,Platynator=function()end}
NightProGearData={Rank=function()end,NightProClasses={}}
NightProDungeonData={Data={byCategory={},instances={},quests={}}}
NightProQuestVisualData={ResolveTrackerTarget=function()end,EntityModelRequest=function()end,ConfigureEntityCamera=function()end}
QuestieLoader={};LibQuestieDB={Quest={Get=function()end},Npc={Get=function()end}}
ImprovedForever={Menu={Open=function()end},Auction={Realm=function()end,Stats=function()end,Latest=function()end,IsOpen=function()end,Scan=function()end},AuctionBuy={Show=function()end,OpenFor=function()end}}
''')
lua.execute((root/'AddOns/NightProController/NightProDependencies.lua').read_text())
manifest=json.loads((root/'curseforge-dependencies.json').read_text())
for dep in manifest['addons']:
 name=dep['folders'][0]
 state=lua.eval('function(n)return NightProDependencies:State(n)end')(name)
 assert state['state']=='missing' and state['url']==dep['projectUrl'],name
 helptext=lua.eval('function(n)return NightProDependencies:Help(n)end')(name)
 assert dep['projectUrl'] in helptext and 'Fully restart WoW' in helptext,name
 lua.execute("local n=...;addon[n]={loaded=false,enabled=0}",name)
 assert lua.eval('function(n)return NightProDependencies:State(n).state end')(name)=='disabled'
 lua.execute("local n=...;addon[n]={loaded=false,loadError=true}",name)
 assert lua.eval('function(n)return NightProDependencies:State(n).state end')(name)=='load_error'
 lua.execute("local n=...;addon[n]={loaded=true}",name)
 assert lua.eval('function(n)return NightProDependencies:State(n).state end')(name)=='ready',name
print('PASS: all nine dependencies resolve exact official URLs and missing/disabled/load-error/ready states')
lua.execute(r'''
local d=NightProDependencies
NightProGearData=nil;assert(d:State('GearedForever').state=='connection')
assert(d:Help('GearedForever'):find('Install.ps1',1,true))
NightProGearData={Rank=function()end,NightProClasses={}};assert(d:State('GearedForever').state=='ready')
local old=ImprovedForever.Auction.Latest;ImprovedForever.Auction.Latest=nil
assert(d:State('ImprovedForever_Auction').state=='api_error');ImprovedForever.Auction.Latest=old
addon.NeedRoll.queryError=true;assert(d:State('NeedRoll').state=='unknown')
assert(d:State('NeedRoll').label=='INSTALLED - LOAD STATUS UNAVAILABLE')
addon.NeedRoll.queryError=nil;assert(d:State('NeedRoll').state=='ready')
addon.NeedRoll.loaded=false;addon.NeedRoll.loading=true;assert(d:State('NeedRoll').state=='loading')
addon.NeedRoll.loading=nil;addon.NeedRoll.reason='INTERFACE_VERSION'
assert(d:Help('NeedRoll'):find('do not disable version checks',1,true))
addon.NeedRoll.loaded=true;addon.NeedRoll.reason=nil
QuestieForeverGamepadDB={lastStatus={state='blocked'}};assert(d:State('QuestieForeverGamepad').state=='api_error')
QuestieForeverGamepadDB.lastStatus.state='active';assert(d:State('QuestieForeverGamepad').state=='ready')
d:ReportFailure('gear');assert(d:State('GearedForever').state=='api_error');d:ClearFailure('gear');assert(d:State('GearedForever').state=='ready')
assert(d:Resolve('questie-forever-gamepad').name=='QuestieForeverGamepad')
assert(d:Resolve('Improved Forever Auction').name=='ImprovedForever_Auction')
assert(d:Resolve('unrecognized')==nil)
-- Legacy API argument order differs from the C_AddOns API.
C_AddOns=nil
function IsAddOnLoaded()return false end
function GetAddOnInfo(name)return name,name,'',false,'DISABLED'end
function GetAddOnEnableState(character,name)assert(character=='Test character'and name=='NeedRoll');return 0 end
assert(d:State('NeedRoll').state=='disabled')
IsAddOnLoaded=function()error('Failed read')end;GetAddOnInfo=function()error('Failed read')end;GetAddOnEnableState=nil
assert(d:State('NeedRoll').state=='unknown')
''')
print('PASS: connection/API/query failures, later resolution, loading, incompatible versions, aliases and legacy API order without state changes')
