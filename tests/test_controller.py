import sys
from pathlib import Path
from lupa import LuaRuntime
lua=LuaRuntime(unpack_returned_tuples=True)
lua.execute(r'''
frames={}; bindings={}; combat=false; clicks=0; tinsert=table.insert; UISpecialFrames={}; SlashCmdList={}
local methods={}
function methods:SetScript(k,v) self.scripts[k]=v end
function methods:GetScript(k) return self.scripts[k] end
function methods:IsShown() return self.shown end
function methods:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
function methods:Show() self.shown=true end
function methods:Hide() self.shown=false end
function methods:SetShown(v) self.shown=v end
function methods:GetChildren() return table.unpack(self.children) end
function methods:GetParent() return self.parent end
function methods:GetName() return self.name end
function methods:IsProtected() return false end
function methods:IsForbidden() return false end
function methods:IsObjectType(t) return t==self.kind end
function methods:IsEnabled() return true end
function methods:GetWidth()return 1920 end
function methods:GetHeight()return 1080 end
function methods:GetRegions()return end
function methods:GetCenter() return self.x or 100,self.y or 100 end
function methods:GetFrameLevel() return 1 end
function methods:GetEffectiveScale() return 1 end
function methods:SetAttribute(k,v)self[k]=v end
function methods:ClearBindings()bindings={}end
function methods:SetBindingClick(_,key,name)bindings[key]=name end
function methods:Execute(code)assert(load(code,'snippet','t',{self=self}))()end
function RegisterStateDriver()end
C_AddOns={IsAddOnLoaded=function(name)return name=='GearedForever' end}
function methods:Click(btn) if self.scripts.OnClick then self.scripts.OnClick(self,btn)end end
for _,n in ipairs({'SetBackdrop','SetBackdropBorderColor','SetBackdropColor','SetFrameStrata','SetSize','SetPoint','SetText','SetTextColor','SetAllPoints','SetTexture','RegisterForClicks','RegisterEvent','ClearAllPoints','EnableMouse','SetClampedToScreen','SetWidth','SetJustifyH','SetSpacing','SetScale','SetFrameLevel','SetHeight','EnableMouseWheel'})do methods[n]=function()end end
function methods:SetText(value)self.value=value end
function CreateFrame(kind,name,parent,template)
 local f=setmetatable({kind=kind,name=name,parent=parent,children={},scripts={},shown=true}, {__index=methods})
 if parent then table.insert(parent.children,f)end
 if name then _G[name]=f end
 table.insert(frames,f);return f
end
function methods:CreateTexture()return CreateFrame('Texture',nil,nil)end
function methods:CreateFontString()return CreateFrame('FontString',nil,nil)end
UIParent=CreateFrame('Frame','UIParent')
InputUtil={IsGamepadUIEnabled=function()return true end}
function InCombatLockdown()return combat end
function SetOverrideBindingClick(_,_,key,name)assert(not combat);bindings[key]=name end
function ClearOverrideBindings()assert(not combat);bindings={}end
C_Timer={After=function(_,fn)fn()end}
GamepadRadial=setmetatable({}, {__index={IsVisible=function()return false end},__newindex=function()error('Native wheel mutation')end})
''')
source=(Path(__file__).resolve().parents[1] / 'AddOns/NightProController/NightProController.lua').read_text(encoding='utf-8-sig')
lua.execute('function NightProCreateEmblem()end')
lua.execute((Path(__file__).resolve().parents[1]/'AddOns/NightProController/NightProDependencies.lua').read_text())
lua.execute(source)
lua.execute(r'''
local driver=frames[#frames]
local function tick()driver.scripts.OnUpdate(driver,.11)end
SlashCmdList.NIGHTPROMENU();tick()
assert(NightProAddonMenu:IsVisible())
NightProMenuChoice2:Click();assert(NightProAddonMenu:IsVisible(),'Missing dependency must leave menu open')
NightProMenuChoice1:Click();assert(NightProAddonMenu:IsVisible(),'Start Here must stay open')
NightProMenuChoice8:Click();assert(NightProAddonMenu:IsVisible(),'Credits must stay open')
local opened=0;NightProWorkbench={Open=function(_,key)assert(key==nil);opened=opened+1 end}
NightProMenuChoice4:Click();assert(opened==1 and not NightProAddonMenu:IsVisible(),'Gear launch')
local oldLoaded=C_AddOns.IsAddOnLoaded
C_AddOns.IsAddOnLoaded=function()return true end
local bagCommand;SlashCmdList.BAGPAD=function(arg)bagCommand=arg end
SlashCmdList.NIGHTPROMENU();NightProMenuChoice5:Click()
assert(bagCommand=='characters','Inventory must open the visual snapshot browser')
C_AddOns.IsAddOnLoaded=oldLoaded
SlashCmdList.NIGHTPROMENU();tick()
assert(bindings.PAD2=='NightProNav_PAD2')
NightProNav_PAD2:Click();assert(not NightProAddonMenu:IsVisible());assert(next(bindings)==nil)
local gear=CreateFrame('Frame','GearedForeverFrame',UIParent)
local a=CreateFrame('Button',nil,gear);a.x=100;a.y=200;a:SetScript('OnClick',function()clicks=clicks+1 end)
local b=CreateFrame('Button',nil,gear);b.x=100;b.y=100;b:SetScript('OnClick',function()clicks=clicks+10 end)
tick();NightProNav_PADDDOWN:Click();NightProNav_PAD1:Click();assert(clicks==10,'D-pad must reach real controls')
NightProNav_PAD2:Click();assert(not gear:IsVisible());assert(next(bindings)==nil)
combat=true;NightProControllerBindings:Execute(NightProControllerBindings['_onstate-combat']:gsub('newstate','"combat"'));assert(next(bindings)==nil);SlashCmdList.NIGHTPROMENU();tick();assert(not NightProAddonMenu:IsVisible())
''')
print('PASS: private menu, real button navigation, B closes/releases, combat guard, no native wheel writes')


theme=(Path(__file__).resolve().parents[1] / 'AddOns/NightProController/NightProTheme.lua').read_text()
before = lua.eval('#frames')
lua.execute(theme)
assert lua.eval('#frames') == before, 'Original addon windows must not receive replacement branding'
print('PASS: upstream windows keep their own identity')
