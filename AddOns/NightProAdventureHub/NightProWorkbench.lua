-- SPDX-License-Identifier: GPL-3.0-only
-- Upstream addons own the data. This hub provides the controller presentation.
local W={};NightProWorkbench=W
local modules={
 {key='gear',name='Find Gear',sub='Choose a slot. See gear for your class and level.'},
 {key='quests',name='My Quests',sub='Read your objectives, then open the quest map.'},
 {key='dungeons',name='Dungeons & Loot',sub='Choose a dungeon, then its bosses or quests.'},
 {key='auctions',name='Auction Prices',sub='Check saved prices. Trade at an auctioneer.'},
}
local slots={'Head','Neck','Shoulder','Back','Chest','Wrist','Hands','Waist','Legs','Feet','Ring','Trinket','Two-Hand','Main Hand','Off Hand','Shield','Ranged'}
local state={module='home',view='home',page=1,slot=5,spec=1,range=1,category=1,zone='home',index=1,detailPage=1}
local list,rows,filters,actions,cards={},{},{},{},{}
local path,entries={},{}
local refresh,paint,focus,describe,chooseModule
local frame=CreateFrame('Frame','NightProWorkbenchFrame',UIParent,'BackdropTemplate');W.frame=frame
frame:SetSize(620,860);frame:SetPoint('CENTER',UIParent,'CENTER',0,0);frame:SetFrameStrata('DIALOG');frame:SetClampedToScreen(true);frame:Hide()
tinsert(UISpecialFrames,'NightProWorkbenchFrame')
local function panel(f,inset)
 if BagPad and BagPad.Style then
  if inset then BagPad.Style:SchemePane(f)else BagPad.Style:Panel(f);BagPad.Style:SchemeWindow(f)end
 else
  f:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8x8',edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',edgeSize=12,insets={left=3,right=3,top=3,bottom=3}})
  f:SetBackdropColor(.025,.035,.055,.98);f:SetBackdropBorderColor(.65,.55,.30,.9)
 end
end
panel(frame)
local function text(parent,size,x,y,width,value,gold)
 local t=parent:CreateFontString(nil,'OVERLAY','GameFontHighlight')
 if t.SetFont then t:SetFont(STANDARD_TEXT_FONT or 'Fonts\\FRIZQT__.TTF',size,'')end
 t:SetPoint('TOPLEFT',x,y);t:SetWidth(width);t:SetJustifyH('LEFT');t:SetJustifyV('TOP');t:SetText(value or '')
 if gold then t:SetTextColor(1,.82,0)else t:SetTextColor(.88,.89,.92)end
 return t
end
text(frame,24,22,-22,530,'NIGHTPRO ADVENTURE HUB',true)
local subtitle=text(frame,17,22,-57,566,'Gear, quests, dungeons and prices. All in one place.')
local breadcrumb=text(frame,16,22,-99,566,'Choose what you want to do',true)
local body=CreateFrame('Frame',nil,frame,'BackdropTemplate');body:SetPoint('TOPLEFT',14,-129);body:SetSize(592,660);panel(body,true)
local heading=text(body,23,16,-17,560,'',true)
local info=text(body,17,16,-54,560,'');info:SetHeight(62)
local detail=CreateFrame('Frame',nil,body,'BackdropTemplate');detail:SetPoint('TOPLEFT',10,-112);detail:SetSize(572,467);panel(detail,true)
local detailTitle=text(detail,23,18,-18,536,'',true);detailTitle:SetHeight(72)
local detailText=text(detail,19,18,-103,536,'');detailText:SetSpacing(5);detailText:SetHeight(346)
local picture=CreateFrame('Frame',nil,detail,'BackdropTemplate');picture:SetPoint('TOPLEFT',18,-79);picture:SetSize(536,250);panel(picture,true);picture:Hide()
local pictureIcon=picture:CreateTexture(nil,'ARTWORK');pictureIcon:SetSize(136,136);pictureIcon:SetPoint('TOP',0,-8)
local pictureName=text(picture,18,12,-151,512,'');pictureName:SetHeight(42)
local pictureGuide=text(picture,18,12,-197,512,'');pictureGuide:SetHeight(49)
local pictureModel,pictureKey,pictureSlot
local function clearPicture()
 picture:Hide();pictureIcon:Hide();pictureKey=nil
 if pictureModel then pictureModel:Hide();if pictureModel.ClearModel then pictureModel:ClearModel()end end
end
local function showPicture(entry)
 if not entry then clearPicture();return end
 picture:Show();pictureName:SetText((entry.role and (entry.role..': ')or '')..(entry.name or 'Quest target')..(entry.levelText and ('\n'..entry.levelText)or ''));pictureGuide:SetText(entry.guide or '')
 local key=tostring(entry.kind)..':'..tostring(entry.id)
 if pictureKey==key then return end
 pictureKey=key;pictureIcon:Hide();if pictureModel then pictureModel:Hide()end
 if entry.kind=='item' then
  local fn=C_Item and C_Item.GetItemIconByID or GetItemIcon
  local icon=fn and fn(entry.id)
  if icon then pictureIcon:SetTexture(icon);pictureIcon:Show()
  else pictureKey=nil;pictureName:SetText((entry.name or 'Quest item')..' - picture loading')end
  return
 end
 local visual=NightProQuestVisualData
 if not visual then return end
 if not pictureModel then
  pictureModel=CreateFrame('PlayerModel',nil,picture);pictureModel:SetSize(512,145);pictureModel:SetPoint('TOP',0,-5)
  pictureModel:SetScript('OnModelLoaded',function()
   if pictureSlot and pictureModel:IsShown()then pcall(visual.ConfigureEntityCamera,visual,pictureSlot)end
  end)
 end
 local method,value=visual:EntityModelRequest(entry,pictureModel)
 if not method then pictureName:SetText((entry.name or 'Quest target')..' - picture unavailable');return end
 pictureModel:SetSize(entry.animation=='giver' and 145 or 512,145)
 if pictureModel.ClearModel then pictureModel:ClearModel()end
 pictureSlot={model=pictureModel,entry=entry,objectiveStyle=true,rotation=.35,lockCreatureCamera=true,cameraAPI=pictureModel.SetCamDistanceScale}
 pictureModel:Show()
 local ok=pcall(pictureModel[method],pictureModel,value)
 if ok then pcall(visual.ConfigureEntityCamera,visual,pictureSlot)
 else pictureModel:Hide();pictureName:SetText((entry.name or 'Quest target')..' - picture unavailable')end
end
local footer=text(frame,16,22,-812,576,'D-pad: choose   A: open   B: back   LB / RB: page')
local pageText=text(body,16,16,-621,390,'')
local help={SetText=function()end}
local function button(parent,x,y,width,height,label,fn)
 local b=CreateFrame('Button',nil,parent,'BackdropTemplate');b:SetPoint('TOPLEFT',x,y);b:SetSize(width,height)
 b:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8x8',edgeFile='Interface\\Buttons\\WHITE8x8',edgeSize=1})
 b:SetBackdropColor(.055,.075,.11,1);b:SetBackdropBorderColor(.29,.32,.39,1)
 b.label=text(b,18,12,-13,width-24,label);b.label:SetHeight(height-16)
 b:RegisterForClicks('LeftButtonUp','RightButtonUp')
 b:SetScript('OnClick',function(_,which)if not InCombatLockdown()then fn(which=='RightButton' and -1 or 1)end end)
 return b
end
local backButton=button(frame,478,-91,120,30,'Back',function()W:Back()end);backButton.label:ClearAllPoints();backButton.label:SetPoint('TOPLEFT',12,-6)
local function diagnostic(err)
 NightProKitDiagnostics=NightProKitDiagnostics or {};local d=NightProKitDiagnostics
 d[#d+1]={at=date('%Y-%m-%d %H:%M:%S'),page=state.module,message=tostring(err):sub(1,1800)};while #d>12 do table.remove(d,1)end
 state.view='error';for _,b in ipairs(rows)do b:Hide()end;for _,v in ipairs(filters)do v.button:Hide()end
 for _,v in ipairs(actions)do v.button:Hide()end;detail:Show()
 detailTitle:SetText('This page could not load');detailText:SetText('Press B to return to the hub.\n\n'..tostring(err):sub(1,240))
end
local function guarded(fn,...)local ok,r=pcall(fn,...);if not ok then diagnostic(r)end;return ok,r end
for i,m in ipairs(modules)do
 local b=button(body,16,-121-(i-1)*112,560,96,m.name,function()chooseModule(m.key)end)
 b.label:SetHeight(27);text(b,17,12,-49,532,m.sub)
 b:SetScript('OnEnter',function()state.zone='home';state.index=i;focus()end);cards[i]=b
end
for i=1,4 do
 local b=button(body,16+((i-1)%2)*286,-117-math.floor((i-1)/2)*49,274,43,'',function(dir)
  if filters[i].change then local rebuild=filters[i].change(dir);if rebuild~=false then state.page=1;refresh()end end
 end)
 b:SetScript('OnEnter',function()state.zone='filters';state.index=i;focus()end);filters[i]={button=b}
end
for i=1,6 do
 local b=button(body,16,-225-(i-1)*61,560,56,'',function()
  local e=list[(state.page-1)*6+i];if not e then return end
  state.index=i;state.selected=i;state.zone='list'
  if e.open then e.open()else state.view='detail';state.detailPage=1;state.index=1;describe(e);paint()end
 end)
 b.label:SetHeight(23);b.sub=text(b,16,12,-35,536,'');b.sub:SetHeight(18);b.sub:SetTextColor(.70,.74,.80)
 b:SetScript('OnEnter',function()state.zone='list';state.index=i;focus()end);rows[i]=b
end
for i=1,2 do
 local b=button(body,16+(i-1)*286,-581,274,36,'',function()local a=actions[i];if a and a.run then guarded(a.run)end end)
 b:SetScript('OnEnter',function()state.zone='actions';state.index=i;focus()end);actions[i]={button=b}
end
local prev=button(body,420,-619,68,30,'<',function()W:Scroll(1)end)
local nextPage=button(body,496,-619,80,30,'>',function()W:Scroll(-1)end)
local function setFilter(i,label,fn)filters[i].button.label:SetText(label or '');filters[i].change=fn;filters[i].button:SetShown(label~=nil)end
local function setAction(i,label,fn)actions[i].button.label:SetText(label or '');actions[i].run=fn;actions[i].button:SetShown(label~=nil)end
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
 heading:SetText('Find gear for your character');subtitle:SetText('Gear, quests, dungeons and prices. All in one place.')
 help:SetText('GEAR\n\nChange a filter with A. X cycles it backward.\n\nRankings come from GearedForever. They are recommendations, not a simulation.\n\nNo automatic item tooltips or model previews.')
 if not g or not g.NightProClasses then error('Gear data bridge is missing. Run Install.ps1 again, then reload.') end
 local _,token=UnitClass('player');local cls=g.NightProClasses[1]
 for _,c in ipairs(g.NightProClasses)do if c.token==token then cls=c end end
 state.spec=math.min(state.spec,#cls.specs);local spec=cls.specs[state.spec]
 local level=math.min(60,math.max(1,UnitLevel('player')))
 state.range=math.min(state.range,1+math.ceil((60-level)/10));local hi=math.min(60,level+(state.range-1)*10);local lo=state.range==1 and 1 or math.max(1,hi-9)
 setFilter(1,'Role: '..spec.label,function(d)state.spec=cycle(state.spec,d,#cls.specs)end)
 setFilter(2,'Slot: '..slots[state.slot],function(d)state.slot=cycle(state.slot,d,#slots)end)
 setFilter(3,state.range==1 and 'Usable now' or ('Levels '..lo..'-'..hi),function(d)state.range=cycle(state.range,d,1+math.ceil((60-level)/10))end)
 setFilter(4,'Reset choices',function()state.range=1;state.spec=1;state.slot=5 end)
 info:SetText(cls.name..' / '..spec.label..'  |  '..slots[state.slot]..'  |  Suggestions, not equipped-item comparisons')
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

local function targetGuide(target,complete,objective)
 local ref=target.refs and target.refs[1]
 local name=target.name or 'the marked target'
 local task
 if complete then task='Return to '..name..' and turn in your quest.'
 elseif target.kind=='creature' and ref and ref.kind=='item' then task='Defeat '..name..' and loot '..(ref.name or 'the quest item')..'.'
 elseif target.kind=='creature' and ref and (ref.kind=='creature' or ref.kind=='killcredit' or ref.kind=='monster') then task='Defeat '..name..'.'
 elseif target.kind=='object' then task='Find '..name..' and interact with it.'
 elseif target.kind=='item' then task='Collect '..name..'.'
 else task=objective and (objective.raw_text or objective.text) or 'Open the quest map for the marked objective.' end
 target.guide=task
 local fighting=not complete and target.kind=='creature' and ref and (ref.kind=='item' or ref.kind=='creature' or ref.kind=='killcredit' or ref.kind=='monster')
 if fighting then
  local db=QuestieLoader and QuestieLoader._modules and QuestieLoader._modules.QuestieDB
  local function number(field)
   if not(db and db.QueryNPCSingle)then return end
   local ok,value=pcall(db.QueryNPCSingle,target.id,field)
   value=ok and tonumber(value);return value and value>0 and value or nil
  end
  local lo,hi=number('minLevel'),number('maxLevel')
  if lo or hi then lo=lo or hi;hi=hi or lo;target.levelText='Enemy level '..lo..(hi~=lo and ('-'..hi)or '')
  else target.levelText='Enemy level not listed' end
 end
end

local function questPage()
 heading:SetText('Quest journal');subtitle:SetText('Your current quests, with room to read the objectives.')
 help:SetText('QUESTS\n\nChoose a quest to read its objectives.\n\nOpen its map from the action button. Your existing Questie map and tracker stay available.\n\nThis page never abandons or completes quests for you.')
 setFilter(1,'Refresh journal',function()end)
 setFilter(2,'Quest map',function()frame:Hide();if ToggleQuestLog then ToggleQuestLog()end;return false end)
 setFilter(3,'Tracking & arrow',function()chooseModule('tracking');return false end)
 local api=C_QuestLog or {};local countFn=api.GetNumQuestLogEntries or GetNumQuestLogEntries
 for i=1,math.min(500,countFn and countFn() or 0)do
  local q
  if api.GetInfo then q=api.GetInfo(i)
  elseif GetQuestLogTitle then
   local title,level,_,header,_,complete,_,id=GetQuestLogTitle(i);q={title=title,level=level,isHeader=header,questID=id,isComplete=complete}
  end
  if q and q.title and not(q.isHeader==true or q.isHeader==1)then
   local id=q.questID;local objective={}
   local cache=QuestieLoader and QuestieLoader._modules and QuestieLoader._modules.QuestLogCache
   local saved=id and cache and cache.TryGetQuest and cache.TryGetQuest(id)
   local objectives=saved and saved.objectives or (id and api.GetQuestObjectives and api.GetQuestObjectives(id)) or {}
   local order={};for index in pairs(objectives)do if type(index)=='number'then order[#order+1]=index end end;table.sort(order)
   for _,index in ipairs(order)do
    local o=objectives[index];local wording=o.raw_text or o.text or ''
    objective[#objective+1]=wording:match('^%s*%d+/%d+%s*$') and ('Objective '..index..': '..wording..'\nOpen the quest map for the target name.') or wording
   end
   local complete=q.isComplete==true or q.isComplete==1 or (id and api.IsComplete and api.IsComplete(id))
   local bodyText=(complete and 'Ready to turn in.\n\n' or '')..(#objective>0 and table.concat(objective,'\n\n') or 'Open the quest map for the full description.')
   local entry=detailEntry(q.title,complete and 'Complete - ready to turn in' or ('Level '..tostring(q.level or '?')),bodyText,
    {label='Open quest map',run=function()
     if id and QuestMapFrame_OpenToQuestDetails then frame:Hide();QuestMapFrame_OpenToQuestDetails(id)
     elseif ToggleQuestLog then frame:Hide();ToggleQuestLog()end
    end})
   entry.pictures={}
   local visual=NightProQuestVisualData
   if visual and visual.ResolveTrackerTarget then
    local native={id=id,complete=complete,ready=true,objectivesLoaded=true,objectives={}}
    for _,index in ipairs(order)do
     local o=objectives[index];native.objectives[#native.objectives+1]={NativeIndex=index,finished=o.finished,text=o.text}
    end
    local seen={}
    for _,index in ipairs(complete and {0}or order)do
     local ok,target=pcall(visual.ResolveTrackerTarget,visual,native,index>0 and {ObjectiveIndex=index}or nil)
     if ok and target then
      local copy={};for k,v in pairs(target)do copy[k]=v end;target=copy
      targetGuide(target,complete,objectives[index])
      local key=tostring(target.kind)..':'..tostring(target.id)
      if not seen[key]then entry.pictures[#entry.pictures+1]=target;seen[key]=true end
     end
    end
   end
   list[#list+1]=entry
  end
 end
 info:SetText(#list..' quests in your journal  |  Select a quest for your next step')
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
 heading:SetText('Dungeons & loot');subtitle:SetText('Choose a location, then bosses or dungeon quests.')
 if not(n and n.Data)then error('Dungeon data bridge is missing. Run Install.ps1 again, then reload.')end
 local d=n.Data;local cats={'DUNGEON','RAID'}
 setFilter(1,state.category==1 and 'Dungeons' or 'Raids',function(dir)state.category=cycle(state.category,dir,2);path={}end)
 local instance,section,encounter=path[1],path[2],path[3]
 local function branch(title,sub,open)
  local e=detailEntry(title,sub,'');e.open=function()open();state.page=1;state.index=1;state.zone='list';refresh()end;list[#list+1]=e
 end
 if not instance then
  local sorted={};for _,v in ipairs(d.byCategory[cats[state.category]]or{})do sorted[#sorted+1]=v end
  table.sort(sorted,function(a,b)local al=a.levelRange and a.levelRange[1]or 99;local bl=b.levelRange and b.levelRange[1]or 99;if al==bl then return(a.name or a.id)<(b.name or b.id)end;return al<bl end)
  for _,v in ipairs(sorted)do
   branch(v.name or v.id,(v.levelRange and ('Levels '..table.concat(v.levelRange,'-')..'  /  ')or '')..(v.zone or ''),function()path={v}end)
  end
  info:SetText('Start here: choose a location. Sorted by suggested level.')
 elseif not section then
  branch('Bosses & loot','See the enemies and what they can drop',function()path[2]='bosses'end)
  branch('Dungeon quests',#(d.quests[instance.id]or{})..' quests: requirements, quest givers and rewards',function()path[2]='quests'end)
  info:SetText(instance.name..(instance.levelRange and ('  /  Levels '..table.concat(instance.levelRange,'-'))or '')..'\nChoose what you want to see.')
 elseif section=='quests' then
  for _,q in ipairs(d.quests[instance.id]or{})do list[#list+1]=dungeonQuest(q)end
  info:SetText(instance.name..' > Dungeon quests')
 elseif not encounter then
  for _,v in ipairs(instance.encounters or{})do if not v.overview then
   branch(v.name or v.id,#(v.loot or{})..' possible drops  /  A: show loot',function()path[3]=v end)
  end end
  info:SetText(instance.name..' > Bosses & loot')
 else
  for _,v in ipairs(encounter.loot or{})do if v.itemID then
   local e=detailEntry(itemName(v.itemID),'A: where this drops',instance.name..'\n\nDropped by: '..(encounter.name or '')..'\n\n'..(v.note or '')..'\n\nNeedRoll lists this drop. A drop chance is not available.');e.itemID=v.itemID;list[#list+1]=e
  end end
  info:SetText(instance.name..' > '..(encounter.name or '')..'\nSelect an item for its source.')
 end
end
function W:FindItem(id)
 local n=NightProDungeonData;if not(n and n.Data)then return end
 for _,instance in pairs(n.Data.instances)do
  if instance.category=='DUNGEON' or instance.category=='RAID' then
   for _,encounter in ipairs(instance.encounters or {})do for _,loot in ipairs(encounter.loot or {})do if loot.itemID==id then
    path={instance,'bosses',encounter};state.module='dungeons';state.page=1;state.zone='list';state.index=1;refresh();return true
   end end end
  end
 end
 list={detailEntry(itemName(id),'No dungeon drop listed','This item is not listed as a dungeon or raid drop. It may be a quest reward, vendor item or world drop. Check its Gear description for the source.')};state.selected=1;state.index=1;state.detailPage=1;state.view='detail';paint()
 return false
end
local function auctionPage()
 heading:SetText('Check saved auction prices');subtitle:SetText('Gear, quests, dungeons and prices. All in one place.')
 help:SetText('AUCTIONS\n\nThese are saved observations, not guaranteed live listings.\n\nThe live auction button opens Improved Forever\'s controller trading window at an auctioneer.\n\nBuying and selling keep its confirmation controls.')
 local a=ImprovedForever and ImprovedForever.Auction
 if not(a and a.Realm)then error('Improved Forever Auction is not loaded.')end
 setFilter(1,'Refresh prices',function()end)
 setFilter(2,'Scan at auctioneer',function()
  if a.IsOpen() then a.Scan(false) else info:SetText('Visit an auctioneer before scanning. Your saved prices remain available.')end
  return false
 end)
 setFilter(3,'Live auction house',function()
  if a.IsOpen() and ImprovedForever.AuctionBuy then frame:Hide();ImprovedForever.AuctionBuy.Show()
  else info:SetText('Visit an auctioneer to browse current listings, buy or sell.')end
  return false
 end)
 local ids={};for id in pairs(a.Realm().items or {})do ids[#ids+1]=id end;table.sort(ids,function(a,b)local an,bn=itemName(a),itemName(b);if an==bn then return a<b end;return an<bn end)
 local _,scanned=a.Stats();info:SetText(#ids..' saved items  |  Last scan: '..(scanned and date('%b %d, %H:%M',scanned) or 'Not scanned yet'))
 for _,id in ipairs(ids)do
  local day,low,market,qty=a.Latest(id)
  list[#list+1]=detailEntry(itemName(id),low and ('Saved low: '..money(low)) or 'No price',
   ('Last seen: %s\n\nLowest recorded: %s\n\nMarket estimate: %s\n\nObserved quantity: %s\n\nSaved data can be out of date. Open live listings to check the current price.'):format(day and date('%b %d',day*86400) or '?',low and money(low)or 'Not recorded',market and money(market)or 'Not recorded',qty or '?'),
   {label='Live listings',run=function()
    if a.IsOpen() and ImprovedForever.AuctionBuy then frame:Hide();ImprovedForever.AuctionBuy.OpenFor(id)
    else detailText:SetText('Visit an auctioneer to view live listings for this item. No purchase has been made.')end
   end})
  list[#list].itemID=id
 end
end

local detailPages={}
local function paginate(s,pageSize)
 pageSize=pageSize or 12
 local lines={};s=(s or ''):gsub('|c%x%x%x%x%x%x%x%x',''):gsub('|r','')
 for line in (s..'\n'):gmatch('(.-)\n')do
  local current=''
  for word in line:gmatch('%S+')do
   if #current+#word+1>46 then lines[#lines+1]=current;current=word else current=current=='' and word or current..' '..word end
  end
  lines[#lines+1]=current
 end
 local pages={};for i=1,#lines,pageSize do local part={};for j=i,math.min(i+pageSize-1,#lines)do part[#part+1]=lines[j]end;pages[#pages+1]=table.concat(part,'\n')end
 return #pages>0 and pages or {''}
end
describe=function(e)
 detailTitle:SetText(e and e.title or 'Nothing here yet')
 local pictures=e and e.pictures or {};local illustrated=#pictures>0
 detailPages=paginate(e and e.body or 'Try another filter or refresh this page.',illustrated and 3 or 12)
 local count=#detailPages;for i=count+1,#pictures do detailPages[i]=detailPages[count]end
 state.detailPage=math.min(state.detailPage,#detailPages);detailText:SetText(detailPages[state.detailPage])
 detailText:ClearAllPoints();detailText:SetPoint('TOPLEFT',18,illustrated and -344 or -103);detailText:SetHeight(illustrated and 109 or 346)
 showPicture(pictures[math.min(state.detailPage,#pictures)])
 for i=1,2 do local a=e and(i==1 and e.first or e.second);setAction(i,a and a.label,a and a.run)end
end
local function visibleIndices(group)
 local out={};for i,v in ipairs(group)do if(v.button or v):IsShown()then out[#out+1]=i end end;return out
end
focus=function()
 local group=state.view=='home' and cards or state.view=='detail' and actions or state.zone=='filters' and filters or rows
 for _,g in ipairs({cards,filters,actions,rows})do for _,v in ipairs(g)do local b=v.button or v;b:SetBackdropColor(.055,.075,.11,1);b:SetBackdropBorderColor(.29,.32,.39,1)end end
 local v=group[state.index];local b=v and(v.button or v)
 if b and b:IsShown()then b:SetBackdropColor(.16,.20,.29,1);b:SetBackdropBorderColor(1,.82,0,1)end
end
paint=function()
 local isHome=state.view=='home';local isDetail=state.view=='detail'
 detail:SetShown(isDetail or state.view=='error')
 if not isDetail then clearPicture()end
 for _,b in ipairs(cards)do b:SetShown(isHome)end
 for _,v in ipairs(filters)do v.button:SetShown(not isHome and not isDetail and state.view~='error' and v.change~=nil)end
 for _,v in ipairs(actions)do v.button:Hide()end
 local pages=math.max(1,math.ceil(#list/6));state.page=math.min(math.max(1,state.page),pages)
 for i,b in ipairs(rows)do
  local e=list[(state.page-1)*6+i];b:SetShown(state.view=='list' and e~=nil)
  if e then if e.itemID then e.title=itemName(e.itemID)end;b.label:SetText(e.title);b.sub:SetText(e.sub)end
 end
 if isHome then
  subtitle:SetText('Gear, quests, dungeons and prices. All in one place.');heading:SetText('What would you like to do?');info:SetText('Four tools, one hub. Choose a section below.');breadcrumb:SetText('Adventure Hub');pageText:SetText('B: close Adventure Hub')
 elseif isDetail then
  describe(list[(state.page-1)*6+state.selected]);pageText:SetText(('Details %d / %d'):format(state.detailPage,#detailPages))
 else pageText:SetText(('Page %d / %d   -   %d results'):format(state.page,pages,#list))end
 if state.view=='list' and #list==0 then detail:Show();describe(nil);detailText:SetText(state.module=='auctions' and 'No saved prices yet. Visit an auctioneer and choose Scan at auctioneer. Come back here afterward to check those prices anywhere.' or state.module=='quests' and 'Your quest journal is empty. Pick up a quest in the world, then return here.' or 'No results with these choices. Try a different slot, level range or category.')end
 prev:SetShown(not isHome);nextPage:SetShown(not isHome)
 footer:SetText(isHome and 'D-pad: choose   A: open   B: close' or isDetail and 'A: selected action   B: list   LB / RB: read more' or 'D-pad: choose   A: open   X: filter back   B: hub')
 focus()
end
local function trackingPage()
 heading:SetText('Your journey');subtitle:SetText('Quest tracking and navigation inside Adventure Hub.')
 breadcrumb:SetText('Adventure Hub > My Quests > Your journey')
 info:SetText('Tracking and arrow: Questie Forever Gamepad.\nQuest information: Questie and QuestieDB.')
 local command=SlashCmdList.QUESTIEFOREVERGAMEPAD
 if not command then info:SetText('Install Questie Forever Gamepad to use tracking and the navigation arrow.');return end
 local db=QuestieForeverGamepadDB or {};local arrow=db.navArrow or {}
 setFilter(1,'My quest journal',function()chooseModule('quests');return false end)
 local function control(title,sub,cmd)
  list[#list+1]={title=title,sub=sub,open=function()command(cmd);refresh()end}
 end
 control('Side quest tracker: '..(db.trackerShown~=false and 'ON' or 'OFF'),'Select to show or hide your objectives.',db.trackerShown~=false and 'tracker hide' or 'tracker show')
 control('Navigation arrow: '..(arrow.enabled~=false and 'ON' or 'OFF'),'Select to show or hide the route arrow.',arrow.enabled~=false and 'arrow off' or 'arrow on')
 local scale=tonumber(arrow.scale)or 1
 control(('Arrow size: %.0f%%'):format(scale*100),'Select to cycle through 75%, 100%, 125% and 150%.','arrow scale '..tostring(scale<.99 and 1 or scale<1.24 and 1.25 or scale<1.49 and 1.5 or .75))
 control('Arrow position: '..(arrow.locked~=false and 'LOCKED' or 'MOVABLE'),'Unlock, move it with the mouse, then lock it again.',arrow.locked~=false and 'arrow unlock' or 'arrow lock')
 list[#list+1]=detailEntry('About the quest tools','Original projects and settings',
  'This page brings the controls together. NightPro did not make Questie or Questie Forever Gamepad.\n\nQuestie and QuestieDB contributors provide quest information and map markers. Tombons97 and the Questie Forever Gamepad contributors provide controller support, the side tracker, arrow navigation and quest-picture helpers.\n\nTheir original settings editor is still available under its own name.',
  {label='Original settings',run=function()frame:Hide();command('settings')end},
  {label='Back to journey',run=function()chooseModule('tracking')end})
end
local builders={gear=gearPage,quests=questPage,dungeons=dungeonPage,auctions=auctionPage,tracking=trackingPage}
refresh=function()
 if InCombatLockdown()then return end
 list={};for i=1,4 do setFilter(i)end
 if state.module=='home' then state.view='home';paint();return end
 state.view='list';for _,m in ipairs(modules)do if m.key==state.module then breadcrumb:SetText('Adventure Hub > '..m.name)end end
 local ok=guarded(builders[state.module]);if ok then paint()end
end
chooseModule=function(key)
 state.module=key or 'home';state.view=state.module=='home' and 'home' or 'list';state.page=1;state.zone=state.view=='home' and 'home' or 'list';state.index=1;state.detailPage=1;path={};entries={};refresh()
end
function W:Open(key)
 if InCombatLockdown()then return end
 if GearedForeverFrame then GearedForeverFrame:Hide()end
 if NightProSettingsFrame then NightProSettingsFrame:Hide()end
 frame:SetScale(math.min(1,UIParent:GetWidth()*.29/620,UIParent:GetHeight()*.60/860))
 frame:ClearAllPoints();frame:SetPoint('CENTER',UIParent,'CENTER',0,0);frame:Show();chooseModule(key or 'home')
end
function W:Move(dx,dy)
 if InCombatLockdown()then return end
 if state.view=='home' then state.index=math.max(1,math.min(4,state.index-dy))
 elseif state.view=='detail' then local ids=visibleIndices(actions);state.index=ids[math.max(1,math.min(#ids,state.index+dx-dy))]or 1
 elseif state.zone=='filters' then
  local ids=visibleIndices(filters);local pos=1;for i,v in ipairs(ids)do if v==state.index then pos=i end end
  if dy<0 and pos+2>#ids then state.zone='list';state.index=1
  elseif dy>0 and pos<=2 then state.zone='list';state.index=1
  else state.index=ids[math.max(1,math.min(#ids,pos+dx-dy*2))]or 1 end
 else
  if dy>0 and state.index==1 and #visibleIndices(filters)>0 then state.zone='filters';state.index=visibleIndices(filters)[1]
  elseif dy~=0 then state.index=math.max(1,math.min(math.max(1,math.min(6,#list-(state.page-1)*6)),state.index-dy))end
 end
 focus()
end
function W:Activate(which)
 if InCombatLockdown()then return end
 local group=state.view=='home' and cards or state.view=='detail' and actions or state.zone=='filters' and filters or rows
 local v=group[state.index];local b=v and(v.button or v)
 if b and b:IsShown()then if state.view=='list' and state.zone=='list' then state.selected=state.index end;guarded(b.Click,b,which or 'LeftButton')end
end
function W:Scroll(delta)
 if InCombatLockdown()then return end
 if state.view=='detail' then state.detailPage=math.max(1,math.min(#detailPages,state.detailPage+(delta>0 and -1 or 1)));paint()
 elseif state.view=='list' then state.page=math.max(1,math.min(math.max(1,math.ceil(#list/6)),state.page+(delta>0 and -1 or 1)));state.zone='list';state.index=1;paint()end
end
function W:Back()
 if InCombatLockdown()then return end
 if state.view=='home' then frame:Hide()
 elseif state.view=='error' then chooseModule('home')
 elseif state.view=='detail' then state.view='list';state.zone='list';state.index=state.selected or 1;paint()
 elseif state.module=='dungeons' and #path>0 then path[#path]=nil;state.page=1;state.zone='list';state.index=1;refresh()
 elseif state.module=='tracking' then chooseModule('quests')
 else chooseModule('home')end
end
frame.NightProMove=function(_,dx,dy)W:Move(dx,dy)end
frame.NightProActivate=function(_,which)W:Activate(which)end
frame.NightProBack=function()W:Back()end
frame.NightProScroll=function(_,delta)W:Scroll(delta)end
frame:EnableMouseWheel(true);frame:SetScript('OnMouseWheel',function(_,delta)W:Scroll(delta)end)
local events=CreateFrame('Frame');events:RegisterEvent('PLAYER_REGEN_DISABLED');events:RegisterEvent('GET_ITEM_INFO_RECEIVED')
local queued=false
events:SetScript('OnEvent',function(_,event)
 if event=='PLAYER_REGEN_DISABLED' then frame:Hide();return end
 if frame:IsShown()and not InCombatLockdown()and not queued then queued=true;C_Timer.After(.2,function()queued=false;if frame:IsShown()and not InCombatLockdown()then paint()end end)end
end)

SLASH_NIGHTPROHUB1='/adventurehub';SLASH_NIGHTPROHUB2='/nphub'
SlashCmdList.NIGHTPROHUB=function()W:Open()end
if Minimap then
 local launcher=CreateFrame('Button','NightProAdventureHubButton',Minimap,'BackdropTemplate')
 launcher:SetSize(36,36);launcher:SetPoint('TOPLEFT',Minimap,'TOPLEFT',-2,0);launcher:SetFrameStrata('MEDIUM')
 NightProCreateEmblem(launcher,34)
 launcher:SetScript('OnClick',function()if not InCombatLockdown()then if frame:IsShown()then frame:Hide()else W:Open()end end end)
 launcher:SetScript('OnEnter',function(self)GameTooltip:SetOwner(self,'ANCHOR_LEFT');GameTooltip:AddLine('NightPro Adventure Hub');GameTooltip:AddLine('Gear, quests, dungeons and auction prices',1,1,1);GameTooltip:Show()end)
 launcher:SetScript('OnLeave',function()GameTooltip:Hide()end)
end
