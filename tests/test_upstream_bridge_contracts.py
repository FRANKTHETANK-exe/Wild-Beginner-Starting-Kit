"""Original-code data-contract checks. No live game and no upstream distribution.
Reads separately obtained official archives. Gear uses its unmodified data files
and the Core.lua ranking prefix, before window construction. QFG runs its own
preview/tracker fixtures. This is not a native game/security/rendering test.
"""
import argparse, os, re, tempfile, zipfile
from pathlib import Path
import xml.etree.ElementTree as ET
from lupa.lua51 import LuaRuntime
p=argparse.ArgumentParser();p.add_argument('--archives',type=Path,required=True);a=p.parse_args()
for version in ['1.0.1','1.0.2']:
 with zipfile.ZipFile(a.archives/f'GearedForever_{version}.zip') as z:
  lua=LuaRuntime(unpack_returned_tuples=True);lua.execute(r'''
  bit={band=function(a,b)local n,p=0,1;while a>0 and b>0 do if a%2==1 and b%2==1 then n=n+p end;a=math.floor(a/2);b=math.floor(b/2);p=p*2 end;return n end}
  function strsplit(sep,s,max)local out={};local at=1;for i=1,max-1 do local n=s:find(sep,at,true);if not n then break end;out[#out+1]=s:sub(at,n-1);at=n+#sep end;out[#out+1]=s:sub(at);return unpack(out)end
  fixture={}
  ''');ns=lua.globals().fixture
  for name in ['Data.lua','QuestData.lua','SourceData.lua']:lua.execute(z.read('GearedForever/'+name).decode('utf-8-sig'),'GearedForever',ns)
  core=z.read('GearedForever/Core.lua').decode('utf-8-sig');boundary=core.index('-- Window: built from')
  lua.execute(core[:boundary]+'\nns.NightProClasses=CLASSES;NightProGearData=ns','GearedForever',ns)
  lua.execute(r'''
  local g=NightProGearData;assert(g==fixture and #g.NightProClasses==9)
  for _,cls in ipairs(g.NightProClasses)do
   local ranks=g.Rank(cls,cls.specs[1].key,1,11,true,20,{})
   assert(#ranks==17)
   for _,slot in ipairs(ranks)do for _,row in ipairs(slot)do assert(row.item.id and row.item.lvl and row.item.st and row.item.source)end end
  end
  ''');print(f'PASS: real GearedForever {version} data/ranking prefix, 9 classes and all 17 slot contracts')
for version in ['1.4.1','1.6.0']:
 with zipfile.ZipFile(a.archives/f'NeedRoll-v{version}-forever.zip') as z:
  lua=LuaRuntime(unpack_returned_tuples=True);lua.execute("function UnitFactionGroup()return 'Alliance'end;fixture={name='NeedRoll',L=setmetatable({},{__index=function(_,k)return k end}),On=function()end}")
  ns=lua.globals().fixture;lua.execute(z.read('NeedRoll/Data/Data.lua').decode('utf-8-sig'),'NeedRoll',ns)
  for element in ET.fromstring(z.read('NeedRoll/Data/Data.xml')).iter():
   if element.tag.endswith('Script'):
    name='NeedRoll/Data/'+element.attrib['file'].replace('\\','/');lua.execute(z.read(name).decode('utf-8-sig'),'NeedRoll',ns)
  lua.execute(z.read('NeedRoll/Data/Quests.lua').decode('utf-8-sig'),'NeedRoll',ns)
  lua.execute('local _,ns=...;NightProDungeonData=ns','NeedRoll',ns)
  lua.execute(r'''
  local d=NightProDungeonData.Data;assert(#d.byCategory.DUNGEON>0 and #d.byCategory.RAID>0 and next(d.quests) and next(d.instances))
  for _,cat in ipairs({'DUNGEON','RAID'})do for _,inst in ipairs(d.byCategory[cat])do
   assert(inst.id and inst.name and inst.encounters and d.instances[inst.id])
   for _,enc in ipairs(inst.encounters)do assert(enc.name);for _,loot in ipairs(enc.loot or {})do if loot.itemID then assert(type(loot.itemID)=='number')end end end
  end end
  ''');print(f'PASS: real NeedRoll {version} registered dungeon/raid/loot/quest data matches unchanged hub fields')
for version in ['0.2.93','0.3.15']:
 with tempfile.TemporaryDirectory(prefix='nightpro-qfg-contract-') as td:
  with zipfile.ZipFile(a.archives/f'QuestieForeverGamepad-{version}.zip') as z:z.extractall(td)
  old=Path.cwd()
  try:
   os.chdir(Path(td)/'QuestieForeverGamepad')
   for test in ['Tests/quest_preview.lua','Tests/tracker_images.lua','Tests/downstream_preview.lua']:
    lua=LuaRuntime(unpack_returned_tuples=True);lua.execute("assert(loadfile(...))()",test)
   print(f'PASS: original QFG {version} preview/tracker/downstream model test fixtures (not client pixels)')
  finally:os.chdir(old)
