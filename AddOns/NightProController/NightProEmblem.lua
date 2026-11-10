-- SPDX-License-Identifier: GPL-3.0-only
function NightProCreateEmblem(parent,size)
 local badge=CreateFrame('Frame',nil,parent,'BackdropTemplate')
 badge:SetSize(size,size);badge:SetPoint('CENTER');badge:EnableMouse(false)
 badge:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8x8',edgeFile='Interface\\Buttons\\WHITE8x8',edgeSize=1})
 badge:SetBackdropColor(.025,.035,.055,1);badge:SetBackdropBorderColor(.8,.65,.3,1)
 for i,path in ipairs({'Alliance','Horde'})do
  local bg=badge:CreateTexture(nil,'BACKGROUND');bg:SetSize(size/2-2,size-4)
  bg:SetPoint(i==1 and 'LEFT' or 'RIGHT',i==1 and 2 or -2,0)
  bg:SetColorTexture(i==1 and .04 or .35,.05,i==1 and .35 or .04,.95)
  local logo=badge:CreateTexture(nil,'ARTWORK');logo:SetSize((size-6)/2,size-6)
  logo:SetPoint(i==1 and 'LEFT' or 'RIGHT',i==1 and 3 or -3,0)
  logo:SetTexture('Interface\\Timer\\'..path..'-Logo')
  logo:SetTexCoord(i==1 and 0 or .5,i==1 and .5 or 1,0,1)
 end
 return badge
end
