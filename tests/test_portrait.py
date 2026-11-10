from pathlib import Path
from lupa.lua51 import LuaRuntime

r=Path(__file__).resolve().parents[1]
lua=LuaRuntime(unpack_returned_tuples=True)
lua.execute('''
combat=false;UIParent={};function UIParent:GetWidth()return 2560 end;function UIParent:GetHeight()return 1440 end
function CreateFrame()return {SetScript=function(self,_,fn)driver=fn end}end
function InCombatLockdown()return combat end
''')
lua.execute((r/'AddOns/NightProController/NightProPortrait.lua').read_text())
lua.execute('''
for _,screen in ipairs({{1920,1080},{2560,1440},{3440,1440},{3840,2160}})do
 for _,window in ipairs({{940,850},{1010+68,620},{900,450},{620,900}})do
  local scale=NightProPortrait.Scale(window[1],window[2],1,screen[1],screen[2])
  assert(window[1]*scale<=screen[2]*9/16*.901)
  assert(window[2]*scale<=screen[2]*.601)
 end
end
BagPad=setmetatable({},{__index=function()error('Combat must not touch bag frames')end})
combat=true;driver(nil,.3)
combat=false;BagPad=nil;driver(nil,.3)
local touched=false
local f={IsShown=function()return true end,IsProtected=function()return true end,GetScale=function()touched=true end}
NightProPortrait.FitWindow(f);assert(not touched,'Protected windows must not be edited')
''')
print('PASS: settings and bag geometry fit portrait at 1080p, 1440p, ultrawide and 4K; combat and protected-frame guards')
