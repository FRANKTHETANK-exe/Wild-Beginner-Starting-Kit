-- SPDX-License-Identifier: GPL-3.0-only
-- Data stays with its original addons. This window owns only its presentation.
local W = {}; NightProWorkbench = W
local unpack = unpack or table.unpack
local modules = {
 {key='gear',name='Gear',sub='Upgrades for your level',icon=135041},
 {key='quests',name='Quests',sub='Your journal and objectives',icon=134269},
 {key='dungeons',name='Dungeons & Loot',sub='Bosses, rewards and quests',icon=133076},
 {key='auctions',name='Auctions',sub='Saved prices and trading',icon=133784},
}
local slots={'Head','Neck','Shoulder','Back','Chest','Wrist','Hands','Waist','Legs','Feet','Ring','Trinket','Two-Hand','Main Hand','Off Hand','Shield','Ranged'}
local state={module='gear',page=1,slot=5,spec=1,range=1,category=1,zone='sidebar',index=1,query=''}
local list,rows,filters,actions,side={}, {}, {}, {}, {}
local path,entries={},{}
local refresh,paint,focus,describe
local frame=CreateFrame('Frame','NightProWorkbenchFrame',UIParent,'BackdropTemplate')
W.frame=frame
frame:SetSize(1060,680);frame:SetPoint('CENTER');frame:SetFrameStrata('DIALOG');frame:SetClampedToScreen(true);frame:Hide()
tinsert(UISpecialFrames,'NightProWorkbenchFrame')
local function panel(f,inset)
 if BagPad and BagPad.Style then
  if inset then BagPad.Style:SchemePane(f) else BagPad.Style:Panel(f);BagPad.Style:SchemeWindow(f) end
 else
  f:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8x8',edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',edgeSize=12,insets={left=3,right=3,top=3,bottom=3}})
  f:SetBackdropColor(.025,.035,.055,.98);f:SetBackdropBorderColor(.65,.55,.30,.9)
 end
end
panel(frame)
local function text(parent,size,x,y,width,value,gold)
 local t=parent:CreateFontString(nil,'OVERLAY',size)
 t:SetPoint('TOPLEFT',x,y);t:SetWidth(width);t:SetJustifyH('LEFT');t:SetJustifyV('TOP');t:SetText(value or '')
 if gold then t:SetTextColor(1,.82,0) else t:SetTextColor(.88,.89,.92) end
 return t
end
text(frame,'GameFontNormalLarge',24,-21,920,'NIGHTPRO  |  ADVENTURER\'S KIT',true)
local subtitle=text(frame,'GameFontHighlight',24,-48,950,'')
local sidebar=CreateFrame('Frame',nil,frame,'BackdropTemplate');sidebar:SetPoint('TOPLEFT',14,-82);sidebar:SetSize(210,538);panel(sidebar,true)
local body=CreateFrame('Frame',nil,frame,'BackdropTemplate');body:SetPoint('TOPLEFT',234,-82);body:SetSize(812,538);panel(body,true)
local heading=text(body,'GameFontNormalLarge',16,-15,770,'',true)
local info=text(body,'GameFontHighlightSmall',16,-43,770,'')
local detail=CreateFrame('Frame',nil,body,'BackdropTemplate');detail:SetPoint('TOPLEFT',435,-109);detail:SetSize(360,373);panel(detail,true)
local detailTitle=text(detail,'GameFontNormalLarge',16,-17,326,'',true)
local detailText=text(detail,'GameFontHighlight',16,-62,326,'');detailText:SetSpacing(3);detailText:SetHeight(292)
local footer=text(frame,'GameFontHighlightSmall',24,-643,1005,'D-pad: choose   A: open / change   X: change back   B: back   LB / RB: page',false)
local pageText=text(body,'GameFontHighlightSmall',16,-506,396,'')
local function button(parent,x,y,width,height,label,fn)
 local b=CreateFrame('Button',nil,parent,'BackdropTemplate');b:SetPoint('TOPLEFT',x,y);b:SetSize(width,height)
 b:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8x8',edgeFile='Interface\\Buttons\\WHITE8x8',edgeSize=1})
 b:SetBackdropColor(.055,.075,.11,1);b:SetBackdropBorderColor(.29,.32,.39,1)
 b.label=text(b,'GameFontHighlight',12,-11,width-24,label)
 b:RegisterForClicks('LeftButtonUp','RightButtonUp')
 b:SetScript('OnClick',function(_,which) if not InCombatLockdown() then fn(which=='RightButton' and -1 or 1) end end)
 return b
end
local close=button(frame,1006,-17,35,32,'X',function() frame:Hide() end)
local function diagnostic(err)
 NightProKitDiagnostics=NightProKitDiagnostics or {}
 local d=NightProKitDiagnostics;d[#d+1]={at=date('%Y-%m-%d %H:%M:%S'),page=state.module,message=tostring(err):sub(1,1800)}
 while #d>12 do table.remove(d,1) end
 detailTitle:SetText('This page could not load');detailText:SetText('Your game controls are still available. Close this window with B.\n\n'..tostring(err):sub(1,400))
end
local function guarded(fn,...)
 local ok,result=pcall(fn,...);if not ok then diagnostic(result) end;return ok,result
end
local function chooseModule(key)
 state.module=key;state.page=1;state.query='';path={};entries={};state.zone='sidebar'
 for i,m in ipairs(modules) do if m.key==key then state.index=i end end
 refresh()
end
for i,m in ipairs(modules) do
 local b=button(sidebar,10,-12-(i-1)*72,190,64,'',function()chooseModule(m.key);state.zone='list';state.index=1;focus()end)
 local icon=b:CreateTexture(nil,'ARTWORK');icon:SetSize(30,30);icon:SetPoint('TOPLEFT',10,-12);icon:SetTexture(m.icon)
 b.label:ClearAllPoints();b.label:SetPoint('TOPLEFT',48,-12);b.label:SetWidth(132);b.label:SetText(m.name)
 text(b,'GameFontHighlightSmall',48,-33,132,m.sub)
 b:SetScript('OnEnter',function()state.zone='sidebar';state.index=i;focus()end);side[i]=b
end
local help=text(sidebar,'GameFontHighlightSmall',14,-323,182,'',false);help:SetSpacing(4)
local home=button(sidebar,10,-490,190,34,'Back to all tools',function()frame:Hide();if NightProAddonMenu then NightProAddonMenu:Show()end end)
for i=1,4 do
 local b=button(body,16+(i-1)*195,-66,187,32,'',function(dir)
  if filters[i].change then local rebuild=filters[i].change(dir);if rebuild~=false then state.page=1;refresh()end end
 end)
 b:SetScript('OnEnter',function()state.zone='filters';state.index=i;focus()end);filters[i]={button=b}
end
for i=1,8 do
 local b=button(body,16,-109-(i-1)*47,403,43,'',function()
  local e=list[(state.page-1)*8+i];if not e then return end
  state.zone='list';state.index=i;describe(e)
  if e.open then e.open() else state.zone='actions';state.index=1;focus()end
 end)
 b.label:SetWidth(373);b.label:SetHeight(18)
 b.sub=text(b,'GameFontHighlightSmall',12,-27,373,'');b.sub:SetTextColor(.63,.68,.75)
 b:SetScript('OnEnter',function()state.zone='list';state.index=i;focus()end);rows[i]=b
end
for i=1,2 do
 local b=button(body,435+(i-1)*184,-493,176,32,'',function()
  local a=actions[i];if a and a.run then guarded(a.run) end
 end)
 b:SetScript('OnEnter',function()state.zone='actions';state.index=i;focus()end);actions[i]={button=b}
end
local prev=button(body,268,-493,70,32,'<',function()W:Scroll(1)end)
local nextPage=button(body,345,-493,74,32,'>',function()W:Scroll(-1)end)
local function setFilter(i,label,fn)
 filters[i].button.label:SetText(label or '');filters[i].change=fn;filters[i].button:SetShown(label~=nil)
end
local function setAction(i,label,fn)
 actions[i].button.label:SetText(label or '');actions[i].run=fn;actions[i].button:SetShown(label~=nil)
end
local function itemName(id)
 local gear=NightProGearData
 if gear and gear.byId and gear.byId[id] then return gear.byId[id].name or ('Item '..id) end
 local fn=(C_Item and C_Item.GetItemInfo) or GetItemInfo
 local name=fn and fn(id)
 return name or ('Item '..tostring(id)..' (not cached)')
end
local function money(n)
 n=math.floor(tonumber(n) or 0);return ('%dg %ds %dc'):format(math.floor(n/10000),math.floor(n/100)%100,n%100)
end
local function cycle(value,delta,count)return (value-1+delta)%math.max(1,count)+1 end
local function detailEntry(title,sub,bodyText,first,second)
 return {title=title,sub=sub or '',body=bodyText or '',first=first,second=second}
end
local function gearPage()
 local g=NightProGearData
 heading:SetText('Gear upgrades');subtitle:SetText('Your class, your level, your next upgrade.')
 help:SetText('GEAR\n\nChange a filter with A. X cycles it backward.\n\nRankings come from GearedForever. They are recommendations, not a simulation.\n\nNo automatic item tooltips or model previews.')
 if not g or not g.NightProClasses then error('Gear data bridge is missing. Run Install.ps1 again, then reload.') end
 local _,token=UnitClass('player');local cls=g.NightProClasses[1]
 for _,c in ipairs(g.NightProClasses)do if c.token==token then cls=c end end
 state.spec=math.min(state.spec,#cls.specs);local spec=cls.specs[state.spec]
 local level=math.min(60,math.max(1,UnitLevel('player')))
 local hi=math.min(60,level+(state.range-1)*10);local lo=state.range==1 and 1 or math.max(1,hi-9)
 setFilter(1,spec.label,function(d)state.spec=cycle(state.spec,d,#cls.specs)end)
 setFilter(2,slots[state.slot],function(d)state.slot=cycle(state.slot,d,#slots)end)
 setFilter(3,state.range==1 and 'Usable now' or ('Levels '..lo..'-'..hi),function(d)state.range=cycle(state.range,d,6)end)
 setFilter(4,'My level: '..level,function()state.range=1;state.spec=1 end)
 info:SetText(cls.name..' / '..spec.label..'  |  '..slots[state.slot]..'  |  Top 20 recommendations')
 local show={};for k,v in pairs(GearedForeverDB and GearedForeverDB.show or {})do show[k]=v end
 local rank=g.Rank(cls,spec.key,lo,hi,true,20,show)[state.slot] or {}
 for i,v in ipairs(rank)do
  local item=v.item
  local bodyText=('Level %d%s\n\n%s\n\nSource: %s\n\nRank %d for %s / %s.\nRanking data: GearedForever.'):format(item.lvl,item.est and ' (estimated)' or '',item.noreq and 'Quest reward; check the quest requirements.' or 'Check required level and your trained equipment skills.',g.SourceLabel and g.SourceLabel(item) or item.source or 'Not listed',i,cls.name,spec.label)
  if item.st then
   local stats={};for _,p in ipairs({{2,'Strength'},{3,'Agility'},{4,'Stamina'},{15,'Intellect'},{16,'Spirit'},{17,'Spell power'},{18,'Healing'}})do
    if (item.st[p[1]] or 0)~=0 then stats[#stats+1]=p[2]..': '..item.st[p[1]] end
   end
   if #stats>0 then bodyText=bodyText..'\n\n'..table.concat(stats,'  /  ')end
  end
  list[#list+1]=detailEntry(i..'. '..(item.name or ('Item '..item.id)),'Level '..item.lvl..'  /  '..(item.source or ''),bodyText,
   {label='View loot source',run=function()chooseModule('dungeons');W:FindItem(item.id)end})
 end
end
local function questPage()
 heading:SetText('Quest journal');subtitle:SetText('Your current quests, with room to read the objectives.')
 help:SetText('QUESTS\n\nChoose a quest to read its objectives.\n\nOpen its map from the action button. Your existing Questie map and tracker stay available.\n\nThis page never abandons or completes quests for you.')
 setFilter(1,'Refresh journal',function()end)
 setFilter(2,'Tracker settings',function()frame:Hide();SlashCmdList.QUESTIEFOREVERGAMEPAD('settings')end)
 local api=C_QuestLog or {};local countFn=api.GetNumQuestLogEntries or GetNumQuestLogEntries
 for i=1,math.min(500,countFn and countFn() or 0)do
  local q
  if api.GetInfo then q=api.GetInfo(i)
  elseif GetQuestLogTitle then
   local title,level,_,header,_,complete,_,id=GetQuestLogTitle(i);q={title=title,level=level,isHeader=header,questID=id,isComplete=complete}
  end
  if q and q.title and not(q.isHeader==true or q.isHeader==1)then
   local id=q.questID;local objective={}
   if id and api.GetQuestObjectives then
    for _,o in ipairs(api.GetQuestObjectives(id) or {})do objective[#objective+1]=(o.finished and '|cff77cc88' or '')..(o.text or '')..'|r' end
   end
   local complete=q.isComplete==true or q.isComplete==1 or (id and api.IsComplete and api.IsComplete(id))
   local bodyText=(complete and 'Ready to turn in.\n\n' or '')..(#objective>0 and table.concat(objective,'\n\n') or 'Open the quest map for the full description.')
   list[#list+1]=detailEntry(q.title,complete and 'Complete - ready to turn in' or ('Level '..tostring(q.level or '?')),bodyText,
    {label='Open quest map',run=function()
     if id and QuestMapFrame_OpenToQuestDetails then frame:Hide();QuestMapFrame_OpenToQuestDetails(id)
     elseif ToggleQuestLog then frame:Hide();ToggleQuestLog()end
    end})
  end
 end
 info:SetText(#list..' quests in your journal  |  Questie handles map pins and tracking')
end
local function dungeonQuest(q)
 local rewards={};for _,reward in ipairs(q.rewards or {})do
  local id=type(reward)=='table' and (reward.itemID or reward.id) or reward
  if type(id)=='number' then rewards[#rewards+1]=itemName(id)end
 end
 return detailEntry(q.name or ('Quest '..q.id),'Quest / Level '..tostring(q.level or '?'),
  ('Minimum level: %s\n\nQuest giver: %s\n\nFaction: %s\n\n%s%s'):format(q.minLevel or '?',q.giver or 'See quest map',q.side or 'Both factions',q.chainStartName and ('Chain begins: '..q.chainStartName..'\n\n') or '',#rewards>0 and ('Rewards:\n'..table.concat(rewards,'\n')) or ''),
  {label='Full quest page',run=function()if NeedRoll_ShowQuest and NeedRoll_ShowQuest(q.id)then frame:Hide()end end})
end
local function dungeonPage()
 local n=NightProDungeonData
 heading:SetText('Dungeons & loot');subtitle:SetText('Find a dungeon, choose a boss, check the rewards.')
 help:SetText('DUNGEONS & LOOT\n\nA opens the selected dungeon or boss. B returns one level.\n\nLB / RB changes pages.\n\nDungeon, boss and quest data comes from NeedRoll.')
 if not(n and n.Data)then error('Dungeon data bridge is missing. Run Install.ps1 again, then reload.')end
 local d=n.Data;local cats={'DUNGEON','RAID'}
 setFilter(1,state.category==1 and 'Dungeons' or 'Raids',function(dir)state.category=cycle(state.category,dir,2);path={}end)
 setFilter(2,'Back one level',function()W:Back()end)
 local instance=path[1];local encounter=path[2]
 if not instance then
  local sorted={};for _,v in ipairs(d.byCategory[cats[state.category]] or {})do sorted[#sorted+1]=v end
  table.sort(sorted,function(a,b)return (a.name or a.id)<(b.name or b.id)end)
  for _,v in ipairs(sorted)do
   local e=detailEntry(v.name or v.id,v.zone or '',(v.name or v.id)..'\n\n'..(v.levelRange and ('Suggested levels: '..table.concat(v.levelRange,'-')..'\n\n') or '')..#(v.encounters or {})..' encounter and loot sections.\n\n'..#(d.quests[v.id] or {})..' associated quests.\n\nPress A to browse.')
   e.open=function()path={v};state.page=1;state.zone='list';state.index=1;refresh()end;list[#list+1]=e
  end
  info:SetText('Choose a location  |  '..#list..' entries')
 elseif not encounter then
  for _,v in ipairs(instance.encounters or {})do if not v.overview then
   local e=detailEntry(v.name or v.id,#(v.loot or {})..' loot entries','Press A to see the loot list.')
   e.open=function()path[2]=v;state.page=1;state.index=1;refresh()end;list[#list+1]=e
  end end
  for _,q in ipairs(d.quests[instance.id] or {})do list[#list+1]=dungeonQuest(q)end
  info:SetText(instance.name..'  |  Bosses, shared loot and quests')
 else
  for _,v in ipairs(encounter.loot or {})do if v.itemID then
   local entry=detailEntry(itemName(v.itemID),'Item '..v.itemID,instance.name..'\n\n'..(encounter.name or '')..'\n\n'..(v.note or '')..'\n\nSource: NeedRoll. Drop chances are not shown because its Forever drop data is still being collected.');entry.itemID=v.itemID;list[#list+1]=entry
  end end
  info:SetText(instance.name..' / '..(encounter.name or '')..'  |  '..#list..' items')
 end
end
function W:FindItem(id)
 local n=NightProDungeonData;if not(n and n.Data)then return end
 for _,instance in pairs(n.Data.instances)do
  if instance.category=='DUNGEON' or instance.category=='RAID' then
   for _,encounter in ipairs(instance.encounters or {})do for _,loot in ipairs(encounter.loot or {})do if loot.itemID==id then
    path={instance,encounter};state.module='dungeons';state.page=1;state.zone='list';state.index=1;refresh();return true
   end end end
  end
 end
 detailTitle:SetText(itemName(id));detailText:SetText('No dungeon or raid drop is listed for this item. It may come from a quest, vendor, profession or world drop. The Gear description lists its known source.')
 return false
end
local function auctionPage()
 heading:SetText('Auction prices');subtitle:SetText('Saved market prices anywhere. Live trading at an auctioneer.')
 help:SetText('AUCTIONS\n\nThese are saved observations, not guaranteed live listings.\n\nThe live auction button opens Improved Forever\'s controller trading window at an auctioneer.\n\nBuying and selling keep its confirmation controls.')
 local a=ImprovedForever and ImprovedForever.Auction
 if not(a and a.Realm)then error('Improved Forever Auction is not loaded.')end
 setFilter(1,'Saved prices',function()end)
 setFilter(2,'Scan at auctioneer',function()
  if a.IsOpen() then a.Scan(false) else info:SetText('Visit an auctioneer before scanning. Your saved prices remain available.')end
  return false
 end)
 setFilter(3,'Live auction house',function()
  if a.IsOpen() and ImprovedForever.AuctionBuy then frame:Hide();ImprovedForever.AuctionBuy.Show()
  else info:SetText('Visit an auctioneer to browse current listings, buy or sell.')end
  return false
 end)
 local ids={};for id in pairs(a.Realm().items or {})do ids[#ids+1]=id end;table.sort(ids)
 local _,scanned=a.Stats();info:SetText(#ids..' saved items  |  Last scan: '..(scanned and date('%b %d, %H:%M',scanned) or 'Not scanned yet'))
 for _,id in ipairs(ids)do
  local day,low,market,qty=a.Latest(id)
  list[#list+1]=detailEntry('Item '..id,low and ('Saved low: '..money(low)) or 'No price',
   ('Last seen: %s\n\nLowest recorded: %s\n\nMarket estimate: %s\n\nObserved quantity: %s\n\nSaved data can be out of date. Open live listings to check the current price.'):format(day and date('%b %d',day*86400) or '?',money(low),money(market),qty or '?'),
   {label='Live listings',run=function()
    if a.IsOpen() and ImprovedForever.AuctionBuy then frame:Hide();ImprovedForever.AuctionBuy.OpenFor(id)
    else detailText:SetText('Visit an auctioneer to view live listings for this item. No purchase has been made.')end
   end})
  list[#list].itemID=id
 end
end
describe=function(e)
 detailTitle:SetText(e and e.title or 'Nothing to show yet')
 detailText:SetText(e and e.body or (state.module=='auctions' and 'Visit an auctioneer and let the auction addon save a scan. Prices will appear here afterward.' or 'Try another filter or refresh the page.'))
 for i=1,2 do local a=e and (i==1 and e.first or e.second);setAction(i,a and a.label,a and a.run)end
end
paint=function()
 local pages=math.max(1,math.ceil(#list/8));state.page=math.min(math.max(1,state.page),pages)
 for i,b in ipairs(rows)do
  local e=list[(state.page-1)*8+i];b:SetShown(e~=nil)
  if e then
   if e.itemID then e.title=itemName(e.itemID)end
   b.label:SetText(e.title);b.sub:SetText(e.sub)
  end
 end
 pageText:SetText(('Page %d / %d  -  %d results'):format(state.page,pages,#list))
 describe(list[(state.page-1)*8+math.min(8,state.zone=='list' and state.index or 1)])
 focus()
end
focus=function()
 local group=state.zone=='sidebar' and side or state.zone=='filters' and filters or state.zone=='actions' and actions or rows
 for _,g in ipairs({side,filters,actions,rows})do for _,v in ipairs(g)do local b=v.button or v
  b:SetBackdropColor(.055,.075,.11,1);b:SetBackdropBorderColor(.29,.32,.39,1)
 end end
 local v=group[state.index];local b=v and (v.button or v)
 if b and b:IsShown()then b:SetBackdropColor(.16,.20,.29,1);b:SetBackdropBorderColor(1,.82,0,1)end
 if state.zone=='list' then describe(list[(state.page-1)*8+state.index])end
end
local builders={gear=gearPage,quests=questPage,dungeons=dungeonPage,auctions=auctionPage}
refresh=function()
 if InCombatLockdown()then return end
 list={};for i=1,4 do setFilter(i)end
 local ok=guarded(builders[state.module]);if ok then paint()else for _,b in ipairs(rows)do b:Hide()end;for i=1,2 do setAction(i)end end
end
function W:Open(key)
 if InCombatLockdown()then return end
 if GearedForeverFrame then GearedForeverFrame:Hide()end
 frame:SetScale(math.min(1,(UIParent:GetWidth()-40)/1060,(UIParent:GetHeight()-40)/680))
 frame:Show();chooseModule(key or state.module)
end
function W:Move(dx,dy)
 if InCombatLockdown()then return end
 if state.zone=='sidebar'then
  if dx>0 then state.zone='list';state.index=1 elseif dy~=0 then state.index=math.max(1,math.min(#side,state.index-dy))end
 elseif state.zone=='filters'then
  if dy<0 then state.zone='list';state.index=1 else state.index=math.max(1,math.min(4,state.index+dx))end
 elseif state.zone=='actions'then
  if dx<0 or dy>0 then state.zone='list';state.index=1 elseif dx>0 then state.index=2 end
 else
  if dx<0 then state.zone='sidebar';state.index=1
  elseif dx>0 then state.zone='actions';state.index=1
  elseif dy>0 and state.index==1 then state.zone='filters';state.index=1
  elseif dy~=0 then
   local count=math.min(8,#list-(state.page-1)*8);state.index=math.max(1,math.min(math.max(1,count),state.index-dy))
  end
 end
 focus()
end
function W:Activate(which)
 if InCombatLockdown()then return end
 local group=state.zone=='sidebar' and side or state.zone=='filters' and filters or state.zone=='actions' and actions or rows
 local v=group[state.index];local b=v and(v.button or v)
 if b and b:IsShown()then guarded(b.Click,b,which or 'LeftButton')end
end
function W:Scroll(delta)
 if InCombatLockdown()then return end
 state.page=math.max(1,math.min(math.max(1,math.ceil(#list/8)),state.page+(delta>0 and -1 or 1)))
 state.zone='list';state.index=1;paint()
end
function W:Back()
 if InCombatLockdown()then return end
 if state.module=='dungeons' and #path>0 then path[#path]=nil;state.page=1;state.zone='list';state.index=1;refresh()
 elseif state.zone=='actions' or state.zone=='filters' then state.zone='list';state.index=1;focus()
 elseif state.zone=='list'then state.zone='sidebar';state.index=1;focus()
 else frame:Hide()end
end
frame.NightProMove=function(_,dx,dy)W:Move(dx,dy)end
frame.NightProActivate=function(_,which)W:Activate(which)end
frame.NightProBack=function()W:Back()end
frame.NightProScroll=function(_,delta)W:Scroll(delta)end
frame:EnableMouseWheel(true);frame:SetScript('OnMouseWheel',function(_,delta)W:Scroll(delta)end)
local events=CreateFrame('Frame');events:RegisterEvent('PLAYER_REGEN_DISABLED');events:RegisterEvent('GET_ITEM_INFO_RECEIVED')
local itemRefreshQueued=false
events:SetScript('OnEvent',function(_,event)
 if event=='PLAYER_REGEN_DISABLED' then frame:Hide();return end
 if frame:IsShown() and not InCombatLockdown() and not itemRefreshQueued then
  itemRefreshQueued=true;C_Timer.After(.2,function()itemRefreshQueued=false;if frame:IsShown() and not InCombatLockdown() then paint()end end)
 end
end)
