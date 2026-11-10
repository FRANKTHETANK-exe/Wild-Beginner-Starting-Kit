-- SPDX-License-Identifier: GPL-3.0-only
-- Keep the complete window inside a centered 9:16 crop, including attached panels.
local P={};NightProPortrait=P
local originals=setmetatable({},{__mode='k'})
local function visible(f)return f and f.IsShown and f:IsShown()end
local function safe(f)return f and not(f.IsForbidden and f:IsForbidden())and not(f.IsProtected and f:IsProtected())end
function P.Scale(width,height,base,screenWidth,screenHeight)
 return math.min(base,math.min(screenWidth,screenHeight*9/16)*.90/width,screenHeight*.60/height)
end
function P.FitWindow(f,extraWidth)
 if not(safe(f)and visible(f))then return end
 local base=originals[f]or f:GetScale();originals[f]=base
 local scale=P.Scale(f:GetWidth()+(extraWidth or 0),f:GetHeight(),base,UIParent:GetWidth(),UIParent:GetHeight())
 if math.abs(f:GetScale()-scale)>.001 then f:SetScale(scale)end
 f:ClearAllPoints();f:SetPoint('CENTER',UIParent,'CENTER',-(extraWidth or 0)*scale/2,0)
end
function P.FitBags()
 if InCombatLockdown()then return end
 local b=BagPad;local f=b and b.Native and b.Native.frame
 if not(visible(f)and b.profile and b.Position and b.Layout)or(f.IsForbidden and f:IsForbidden())then return end
 local d=b.Detail and b.Detail.frame;local head=b.Header and b.Header.frame
 local dw=visible(d)and d:GetWidth()or 0
 local hh=visible(head)and head:GetHeight()or 0
 local width=f:GetWidth()+dw
 local height=math.max(f:GetHeight(),visible(d)and d:GetHeight()or 0)+hh
 local base=originals[f]or f:GetScale();originals[f]=base
 local scale=P.Scale(width+24,height+24,base,UIParent:GetWidth(),UIParent:GetHeight())
 if math.abs(f:GetScale()-scale)>.001 then
  -- The native bag owns protected item controls. Use BagPad's existing layout API
  -- outside combat rather than editing those frames or their input scripts here.
  b.profile.scale=scale/(b.Layout.baseScale or 1)
  b.Layout:Refresh()
 end
 local factor=f:GetEffectiveScale()/UIParent:GetEffectiveScale()
 local left=(UIParent:GetWidth()-width*factor)/2
 if visible(d)and b.Detail.side=='left'then left=left+dw*factor end
 local top=(UIParent:GetHeight()-height*factor)/2+hh*factor
 local old=b.profile.position
 if b.profile.positionAnchor~='topleft'or not old or not old.x or math.abs(old.x-left)>.5 or not old.y or math.abs(old.y-top)>.5 then
  b.profile.positionAnchor='topleft';b.Position:Set(left,top)
 end
end
local elapsed=0
local driver=CreateFrame('Frame')
driver:SetScript('OnUpdate',function(_,dt)
 elapsed=elapsed+dt;if elapsed<.25 then return end;elapsed=0
 if InCombatLockdown()then return end
 P.FitBags()
 local names={'BagPadOptionsWindow','ImprovedForeverConfigFrame','QuestieForeverGamepadSettings'}
 for _,name in ipairs(UISpecialFrames or {})do if name:match('^PlatynatorCustomiseDialog')then names[#names+1]=name end end
 for _,name in ipairs(names)do
  local f=_G[name]
  P.FitWindow(f,name=='ImprovedForeverConfigFrame'and 68 or 0)
 end
 -- Template, import and confirmation panels are children of the bag options window.
 -- They inherit its scale; only top-level panels need their own portrait fit.
 local b=BagPad
 if b and b.OptionsWindow then
  local w=b.OptionsWindow
  if w.OpenPanel then local f=w:OpenPanel();f=f and(f.frame or f)
   if safe(f)and f.GetParent and f:GetParent()==UIParent then P.FitWindow(f)end
  end
 end
end)
