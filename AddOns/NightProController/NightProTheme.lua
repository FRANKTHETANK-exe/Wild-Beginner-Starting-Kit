-- SPDX-License-Identifier: GPL-3.0-only
local names={
 BagPadOptionsWindow='NightPro Bags', BagPadBankView='NightPro Bank',
 QuestieForeverGamepadSettings='NightPro Quests',
 ImprovedForeverConfigFrame='NightPro Controls',
 ImprovedForeverAuctionBuy='NightPro Auctions',
 NeedRollFrame='NightPro Dungeons & Loot', NeedRollNativeFrame='NightPro Dungeons & Loot',
 NeedRollDarkFrame='NightPro Dungeons & Loot', NeedRollElvUIFrame='NightPro Dungeons & Loot',
 GearedForeverFrame='NightPro Gear',
}
local titles={
 ['BagPad']='NightPro Bags', ['Questie Forever Gamepad']='NightPro Quests',
 ['NeedRoll']='NightPro Loot', ['GearedForever']='NightPro Gear',
 ['Improved Forever']='NightPro Controls',
}
local borders=setmetatable({},{__mode='k'})
local function safe(frame)
 return frame and not (frame.IsForbidden and frame:IsForbidden())
  and not (frame.IsProtected and frame:IsProtected())
end
local function replaceTitles(frame,depth)
 if depth>5 or not safe(frame) then return end
 if frame.GetRegions then
  for _,region in ipairs({frame:GetRegions()}) do
   if region.IsObjectType and region:IsObjectType('FontString') then
    local value=region:GetText()
    if type(value)=='string' then
     local plain=value:gsub('|c%x%x%x%x%x%x%x%x',''):gsub('|r','')
     local replacement=titles[plain]
     local module=plain:match('^Improved Forever: (.+)$')
     if module then replacement='NightPro Controls: '..module end
     if replacement then region:SetText(replacement);region:SetTextColor(1,.82,0) end
    end
   end
  end
 end
 for _,child in ipairs({frame:GetChildren()}) do replaceTitles(child,depth+1) end
end
local function skin(frame,title)
 if not safe(frame) or not frame:IsShown() then return end
 replaceTitles(frame,0)
 if borders[frame] then return end
 local border=CreateFrame('Frame',nil,frame,'BackdropTemplate')
 border:SetPoint('TOPLEFT',-2,2);border:SetPoint('BOTTOMRIGHT',2,-2)
 border:SetFrameLevel(frame:GetFrameLevel()+10);border:EnableMouse(false)
 border:SetBackdrop({edgeFile='Interface\\Buttons\\WHITE8x8',edgeSize=2})
 border:SetBackdropBorderColor(.65,.55,.30,.9)
 if frame==GearedForeverFrame then
  local plaque=CreateFrame('Frame',nil,border,'BackdropTemplate')
  plaque:SetSize(frame:GetWidth()*.70,frame:GetHeight()*.035)
  plaque:SetPoint('TOP',0,-frame:GetHeight()*.021)
  plaque:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8x8'})
  plaque:SetBackdropColor(.035,.035,.045,1)
  local label=plaque:CreateFontString(nil,'OVERLAY','GameFontNormalLarge')
  label:SetPoint('CENTER');label:SetText(title);label:SetTextColor(1,.82,0)
 end
 borders[frame]=border
end
local function bagTitles()
 if not BagPad then return end
 if BagPad.Header and safe(BagPad.Header.frame) and BagPad.Header.title then
  local alt=BagPad.AltView and BagPad.AltView.Character and BagPad.AltView:Character()
  BagPad.Header.title:SetText(alt and ('NightPro Bags - '..(alt.name or alt.key)) or 'NightPro Bags')
 end
 if BagPad.BankView and safe(BagPad.BankView.frame) and BagPad.BankView.title then
  BagPad.BankView.title:SetText('NightPro Bank')
 end
end
local elapsed=0
local driver=CreateFrame('Frame')
driver:SetScript('OnUpdate',function(_,dt)
 elapsed=elapsed+dt;if elapsed<.5 then return end;elapsed=0
 if InCombatLockdown() then return end
 bagTitles()
 for name,title in pairs(names) do skin(_G[name],title) end
end)
