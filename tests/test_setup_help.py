from pathlib import Path
import runpy, zipfile

root=Path(__file__).resolve().parents[1]
lua=runpy.run_path(str(root/'tests/test_controller.py'))['lua']
lua.execute('''
local m=getmetatable(UIParent).__index
for _,n in ipairs({'SetMultiLine','SetAutoFocus','SetFontObject','SetCursorPosition','ClearFocus','HighlightText','SetScrollChild'})do m[n]=function()end end
combat=false
''')
lua.execute((root/'AddOns/NightProController/NightProSetup.lua').read_text())
assert lua.eval('NightProSetup.prompt')==(root/'AI-SETUP.txt').read_text().rstrip('\n')
lua.execute('''
SlashCmdList.NIGHTPROMENU()
NightProAddonMenu.scripts.OnShow()
local welcome=false
for _,f in ipairs(frames)do if f.kind=='FontString'and type(f.value)=='string'and f.value:find('START PLAYING',1,true)then welcome=true end end
assert(welcome,'Start Here must not open on a dependency error page')
NightProAIHelp:Click()
assert(NightProSetupPromptFrame:IsVisible()and not NightProAddonMenu:IsVisible())
local driver
for _,f in ipairs(frames)do if f.scripts.OnUpdate then driver=f end end
driver.scripts.OnUpdate(driver,.11)
assert(bindings.PAD2=='NightProNav_PAD2')
NightProNav_PAD2:Click()
assert(not NightProSetupPromptFrame:IsVisible()and NightProAddonMenu:IsVisible(),'Controller B returns to the kit menu')
combat=true;SlashCmdList.NIGHTPROSETUPAI();assert(not NightProSetupPromptFrame:IsVisible(),'No prompt during combat')
combat=false;SlashCmdList.NIGHTPROSETUPAI();assert(NightProSetupPromptFrame:IsVisible())
NightProSetupPromptText.scripts.OnEscapePressed(NightProSetupPromptText)
assert(not NightProSetupPromptFrame:IsVisible()and NightProAddonMenu:IsVisible(),'Escape returns to the kit menu')
''')
prompt=(root/'AI-SETUP.txt').read_text()
for token in ['-Preview','WTF','official CurseForge','Do not bypass','computer','Battle.net']:
    assert token in prompt,token
for file in ['INSTALL.md','README.md','CURSEFORGE.md']:
    s=(root/file).read_text();assert 'AI-SETUP.txt' in s and 'CurseForge' in s
print('PASS: short welcome, same copyable AI prompt, controller B and Escape return, combat guard and setup documentation')
