-- SPDX-License-Identifier: GPL-3.0-only
-- Read-only addon status and official installation help. No downloads, enabling,
-- forced addon loads, browser launches or security-setting changes.
local D={errors={}};NightProDependencies=D
local records={
 {name='BagPad',title='BagPad',slug='bagpad-forever',required=true},
 {name='GearedForever',title='GearedForever',slug='gearedforever',required=true,bridge=true},
 {name='NeedRoll',title='NeedRoll',slug='needroll',required=true,bridge=true},
 {name='Questie',title='Questie',slug='questie',required=true},
 {name='QuestieDB',title='QuestieDB',slug='questiedb',required=true},
 {name='QuestieForeverGamepad',title='Questie Forever Gamepad',slug='questie-forever-gamepad',required=true,bridge=true},
 {name='ImprovedForever',title='Improved Forever',slug='improved-forever',required=true},
 {name='ImprovedForever_Auction',title='Improved Forever Auction',slug='improved-forever-auction',required=true},
 {name='Platynator',title='Platynator',slug='platynator',required=false},
}
local byName={};D.names={}
local function key(s)return type(s)=='string' and s:lower():gsub('[^%w]','')or ''end
for _,r in ipairs(records)do
 r.url='https://www.curseforge.com/wow/addons/'..r.slug
 byName[key(r.name)]=r;byName[key(r.title)]=r;byName[key(r.slug)]=r;D.names[#D.names+1]=r.name
end
byName.gear=byName.gearedforever;byName.dungeons=byName.needroll
function D:Resolve(name)return byName[key(name)]end
local function call(fn,...)
 if type(fn)~='function'then return false end
 return pcall(fn,...)
end
local function members(t,names)
 if type(t)~='table'then return false end
 for _,n in ipairs(names)do if type(t[n])~='function'then return false end end
 return true
end
local function connected(name)
 if name=='GearedForever'then return members(NightProGearData,{'Rank'})and type(NightProGearData.NightProClasses)=='table' end
 if name=='NeedRoll'then
  local d=NightProDungeonData and NightProDungeonData.Data
  return type(d)=='table'and type(d.byCategory)=='table'and type(d.instances)=='table'and type(d.quests)=='table'
 end
 if name=='QuestieForeverGamepad'then return members(NightProQuestVisualData,{'ResolveTrackerTarget','EntityModelRequest','ConfigureEntityCamera'})end
 return true
end
local function ready(name)
 if name=='BagPad'then return SlashCmdList and type(SlashCmdList.BAGPAD)=='function'end
 if name=='QuestieForeverGamepad'then return SlashCmdList and type(SlashCmdList.QUESTIEFOREVERGAMEPAD)=='function'end
 if name=='Questie'then return type(QuestieLoader)=='table'end
 if name=='QuestieDB'then return LibQuestieDB and members(LibQuestieDB.Quest,{'Get'})and members(LibQuestieDB.Npc,{'Get'})end
 if name=='ImprovedForever'then return ImprovedForever and members(ImprovedForever.Menu,{'Open'})end
 if name=='ImprovedForever_Auction'then
  return ImprovedForever and members(ImprovedForever.Auction,{'Realm','Stats','Latest','IsOpen','Scan'})and members(ImprovedForever.AuctionBuy,{'Show','OpenFor'})
 end
 if name=='Platynator'then return SlashCmdList and type(SlashCmdList.Platynator)=='function'end
 return true
end
function D:ReportFailure(name,kind)
 local r=self:Resolve(name);if not r then return end
 local errors=self.errors[r.name]or{};errors[kind or 'runtime']=true;self.errors[r.name]=errors
end
function D:ClearFailure(name,kind)
 local r=self:Resolve(name);if not r then return end
 if not kind then self.errors[r.name]=nil;return end
 local errors=self.errors[r.name];if errors then errors[kind]=nil;if not next(errors)then self.errors[r.name]=nil end end
end
function D:State(name)
 local r=self:Resolve(name);if not r then return nil end
 local api=C_AddOns or {};local out={record=r,name=r.name,title=r.title,url=r.url}
 local ok,loading,loaded=call(api.IsAddOnLoaded or IsAddOnLoaded,r.name)
 if ok and(type(loading)=='boolean'or type(loaded)=='boolean')then out.loaded=loaded==nil and loading==true or loaded==true;out.loading=loading==true and loaded==false end
 local existsOK,exists=call(api.DoesAddOnExist,r.name)
 if existsOK then out.installed=exists==true end
 local infoOK,first,_,_,loadable,reason=call(api.GetAddOnInfo or GetAddOnInfo,r.name)
 if infoOK then
  if type(first)=='table'then loadable=first.loadable;reason=first.reason;first=first.name end
  if out.installed==nil then if type(first)=='string'then out.installed=true elseif first==nil then out.installed=false end end
 end
 local enabledOK,enabled
 if api.GetAddOnEnableState then enabledOK,enabled=call(api.GetAddOnEnableState,r.name)
 else
  local _,character=call(UnitName,'player');enabledOK,enabled=call(GetAddOnEnableState,character,r.name)
 end
 local errorOK,hadError=call(api.DoesAddOnHaveLoadError,r.name)
 if out.loaded then
  out.installed=true
  if errorOK and hadError then out.state='load_error';out.label='LOADED - load error reported'
  elseif r.name=='QuestieForeverGamepad'and QuestieForeverGamepadDB and QuestieForeverGamepadDB.lastStatus and (QuestieForeverGamepadDB.lastStatus.state=='blocked'or QuestieForeverGamepadDB.lastStatus.state=='error')then out.state='api_error';out.label='LOADED - addon reports a problem'
  elseif not connected(r.name)then out.state='connection';out.label='LOADED - connection needed'
  elseif self.errors[r.name]then out.state='api_error';out.label='LOADED - integration error'
  elseif not ready(r.name)then out.state='api_error';out.label='LOADED - API not ready'
  else out.state='ready';out.label='READY'end
 elseif out.installed==false then out.state='missing';out.label='NOT LOADED - missing'
 elseif out.loaded==nil then
  if errorOK and hadError then out.state='load_error';out.label='LOAD ERROR REPORTED'
  else out.state='unknown';out.label=out.installed and 'INSTALLED - LOAD STATUS UNAVAILABLE'or 'STATUS UNAVAILABLE'end
 elseif enabledOK and enabled==0 or reason=='DISABLED'then out.state='disabled';out.label='NOT LOADED - disabled'
 elseif errorOK and hadError then out.state='load_error';out.label='NOT LOADED - load error reported'
 elseif out.loading then out.state='loading';out.label='NOT LOADED - still loading'
 elseif out.installed or ok then out.state='not_loaded';out.label='NOT LOADED';out.reason=reason
 else out.state='unknown';out.label='STATUS UNAVAILABLE'end
 return out
end
function D:Help(name)
 local s=self:State(name);if not s then return 'Unknown dependency. Use /npdeps to see the original projects.'end
 local r=s.record;local lines={r.title..'\n'..s.label,'Official project (open in your browser):\n'..r.url}
 if s.state=='missing'then lines[#lines+1]='Close WoW. Install this original addon for Forever in the same CurseForge game instance. For a manual ZIP, put its '..r.name..' folder directly in _forever_/Interface/AddOns. Fully restart WoW after installing a new folder.'
 elseif s.state=='disabled'then lines[#lines+1]='Enable '..r.title..' in the AddOns list for this character, then reload the UI. Do not change security or version checks.'
 elseif s.state=='connection'then lines[#lines+1]='The original addon is loaded, but its shared-data connection is unavailable.'
 elseif s.state=='load_error'or s.state=='api_error'then lines[#lines+1]='Check the game/addon error and its required addons. Install the correct Forever release, enable it, then fully restart WoW. If the error remains, keep the error text for support.'
 elseif s.state=='loading'then lines[#lines+1]='Wait for loading to finish, then hover again. If it stays unavailable, check the AddOns list and restart WoW.'
 elseif s.state=='not_loaded'then lines[#lines+1]='The game has not loaded this addon. Check that it is enabled for this character, its required addons are installed, and its version supports Forever. Restart WoW after installing files.'
 elseif s.state=='unknown'then lines[#lines+1]='The game did not provide a reliable status. Check its AddOns list; missing and disabled cannot be distinguished here.'
 else lines[#lines+1]='This dependency is available. No reinstall is needed.'end
 if s.reason=='INTERFACE_VERSION'or s.reason=='INCOMPATIBLE'then lines[#lines+1]='The game reports an incompatible version. Use the Forever release; do not disable version checks.'end
 if r.bridge and s.state~='ready'then lines[#lines+1]='After installing or updating: close WoW, run NightProController/Install.ps1 with your AddOns path, then reopen WoW. CurseForge does not run this step automatically.'end
 if r.required and s.state~='ready'then lines[#lines+1]='If intentionally leaving any dependency absent, add -AllowMissingDependencies to your usual Install.ps1 -AddonPath command. Only available, verified originals are connected.'end
 if not r.required then lines[#lines+1]='Optional. The rest of the kit can work without this addon.'end
 return table.concat(lines,'\n\n')
end
function D:Summary(names)
 local failed,other={},{}
 for _,name in ipairs(names or {})do
  local s=self:State(name)
  if s and s.state~='ready'and s.record.required then
   if s.loaded==false or s.state=='missing'or s.state=='disabled'then failed[#failed+1]=s.title else other[#other+1]=s.title end
  end
 end
 if #failed>0 then return 'NOT LOADED: '..failed[1]..(#failed>1 and (' + '..(#failed-1))or '')end
 if #other>0 then return 'CHECK: '..other[1]..(#other>1 and (' + '..(#other-1))or '')end
 return 'READY'
end

function D:Pages(value,width,count)
 local lines={};width=width or 64;count=count or 8
 for line in ((value or '')..'\n'):gmatch('(.-)\n')do
  local part=''
  for word in line:gmatch('%S+')do
   if #part>0 and #part+#word+1>width then lines[#lines+1]=part;part=word else part=part==''and word or part..' '..word end
  end
  lines[#lines+1]=part
 end
 local pages={};for i=1,#lines,count do local page={};for j=i,math.min(i+count-1,#lines)do page[#page+1]=lines[j]end;pages[#pages+1]=table.concat(page,'\n')end
 return pages
end
