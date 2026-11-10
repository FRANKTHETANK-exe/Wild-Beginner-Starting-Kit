from pathlib import Path
from lupa.lua51 import LuaRuntime

lua = LuaRuntime(unpack_returned_tuples=True)
lua.execute('''
combat=false;UISpecialFrames={};SlashCmdList={};tinsert=table.insert
local methods={}
for _,name in ipairs({'SetPoint','ClearAllPoints','SetFrameStrata','SetClampedToScreen','SetBackdrop','SetBackdropColor','SetBackdropBorderColor','SetFont','SetWidth','SetHeight','SetJustifyH','SetJustifyV','SetText','SetTextColor','EnableKeyboard','RegisterEvent'})do methods[name]=function()end end
function methods:SetSize(w,h)self.width=w;self.height=h end
function methods:SetScale(s)self.scale=s end
function methods:GetWidth()return self.width end
function methods:GetHeight()return self.height end
function methods:Show()self.shown=true end
function methods:Hide()self.shown=false end
function methods:SetScript(k,v)self.scripts[k]=v end
function methods:SetPropagateKeyboardInput(v)self.propagate=v end
function CreateFrame()return setmetatable({scripts={}}, {__index=methods})end
function methods:CreateFontString()return CreateFrame()end
UIParent=CreateFrame();UIParent:SetSize(2560,1440)
function InCombatLockdown()return combat end
calls={};QuestieForeverGamepadDB={trackerShown=true,navArrow={enabled=true}}
SlashCmdList.QUESTIEFOREVERGAMEPAD=function(cmd)calls[#calls+1]=cmd end
NightProWorkbench={Open=function(_,page)calls.hub=page end}
ImprovedForever={db={padOverrides=true},Binds={FocusChanged=function()calls.focus=true end}}
''')
root = Path(__file__).resolve().parents[1]
lua.execute((root/'AddOns/NightProController/NightProSettings.lua').read_text())
lua.execute('''
local s=NightProSettings;local f=s.frame
for _,size in ipairs({{1920,1080},{2560,1440},{3440,1440},{3840,2160}})do
 UIParent:SetSize(size[1],size[2]);s:Open()
 assert(f.width*f.scale<=size[2]*9/16*.901)
 assert(f.height*f.scale<=size[2]*.761)
end
s:Open();s:Activate()
assert(NightProPreferences.controllerEnabled==false and ImprovedForever.db.padOverrides==false)
assert(calls[#calls]=='gamepad off' and calls.focus)
f.scripts.OnKeyDown(f,'ENTER')
assert(s:ControllerEnabled() and ImprovedForever.db.padOverrides and calls[#calls]=='gamepad on')
f.scripts.OnKeyDown(f,'RIGHT');assert(calls.hub=='tracking' and not f.shown)
s:Open()
f.scripts.OnKeyDown(f,'W');assert(f.propagate,'Movement keys must pass to the game')
f.scripts.OnKeyDown(f,'ESCAPE');assert(not f.shown)
combat=true;local n=#calls
s:Open();s:SetController(false);s:Activate();assert(#calls==n and not f.shown)
combat=false;s:Open();f.scripts.OnEvent(f);assert(not f.shown)
''')
print('PASS: readable portrait settings, keyboard navigation, persisted input choice, quest command routing and combat guards')
